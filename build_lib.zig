//! Reusable vendor-library helper.
//!
//! `addVendorLib` is the single entry point. Each lib under `lib/` is built
//! by passing a declarative `VendorLib` spec at the call site in `build.zig`
//! — no per-library wrapper functions, no duplication.
//!
//! If a lib needs anything that doesn't fit `VendorLib` (e.g. a generated
//! header), do that one bespoke piece inline in `build.zig` and pass the
//! resulting `LazyPath` in via `generated_include_paths`.

const std = @import("std");

/// C++ flags used for every vendored C++ source file.
/// Matches CMake's `set(CMAKE_CXX_STANDARD 17)`. A bump to C++23 was
/// attempted earlier in the fork but the engine sources rely on
/// pre-C++20 behavior (implicit <iterator>, ostream<<wchar_t, ...) so
/// the bump has been parked until after the build-system migration.
pub const cxx_flags = [_][]const u8{ "-std=c++17", "-fno-strict-aliasing" };

/// C flags used for every vendored C source file. Empty — the toolchain
/// picks a recent default and CMake doesn't set anything special either.
pub const c_flags = [_][]const u8{};

/// Install one header file to `zig-out/include/<dest>`.
pub const HeaderFile = struct {
    src: []const u8,
    dest: []const u8,
};

/// Install a directory of headers (`installHeadersDirectory`).
pub const HeaderDir = struct {
    src: []const u8,
    dest: []const u8,
    extensions: []const []const u8 = &.{".h"},
};

/// Declarative description of a vendored static library. Everything except
/// `name` and `sources` has a sensible default.
pub const VendorLib = struct {
    /// Output library name (becomes `lib<name>.a`).
    name: []const u8,

    /// Source files, relative to the build root.
    sources: []const []const u8,

    /// Per-source compile flags. Default is C++23; pass `&c_flags`
    /// for C-only libs.
    flags: []const []const u8 = &cxx_flags,

    /// Override the language Zig would otherwise infer from each source's
    /// file extension. Used when, e.g., a Lua-style library ships `.c`
    /// files that must be compiled as C++ (upstream does the same with
    /// `set_source_files_properties(... LANGUAGE CXX)`).
    language: ?std.Build.Module.CSourceLanguage = null,

    /// Include directories given as paths relative to the build root.
    include_paths: []const []const u8 = &.{},

    /// Include directories given as already-resolved `LazyPath`s — use this
    /// for outputs of WriteFile / generated config headers.
    generated_include_paths: []const std.Build.LazyPath = &.{},

    /// Individual headers to expose in `zig-out/include/`.
    install_headers: []const HeaderFile = &.{},

    /// Optional directory of headers to expose.
    install_headers_dir: ?HeaderDir = null,

    /// `.cpp` links libc++, `.c` links libc. Default: `.cpp`.
    link: enum { c, cpp } = .cpp,
};

/// Build a vendored static library from a spec. Returns the Compile step.
pub fn addVendorLib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    spec: VendorLib,
) *std.Build.Step.Compile {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = spec.link == .c,
        .link_libcpp = spec.link == .cpp,
    });

    for (spec.sources) |src| {
        mod.addCSourceFile(.{
            .file = b.path(src),
            .flags = spec.flags,
            .language = spec.language,
        });
    }
    for (spec.include_paths) |p| mod.addIncludePath(b.path(p));
    for (spec.generated_include_paths) |lp| mod.addIncludePath(lp);

    const lib = b.addLibrary(.{
        .name = spec.name,
        .linkage = .static,
        .root_module = mod,
    });

    for (spec.install_headers) |h| lib.installHeader(b.path(h.src), h.dest);
    if (spec.install_headers_dir) |d| {
        lib.installHeadersDirectory(
            b.path(d.src),
            d.dest,
            .{ .include_extensions = d.extensions },
        );
    }

    return lib;
}
