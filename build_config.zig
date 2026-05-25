//! Configuration & generated-header helpers.
//!
//! Contains:
//!   - Project metadata constants (VERSION_*, PROJECT_NAME, DEVELOPMENT_BUILD)
//!   - `InstallDirs`: platform-dependent install layout
//!   - `ConfigProbes`: static OS-based feature probes (HAVE_ENDIAN_H, ...)
//!   - `renderCmakeConfigH`: produces the byte-compatible `cmake_config.h`
//!   - Small helpers: LTO default, version-string composition, git lookups
//!
//! The build_options.zig file imports VERSION_* and DEVELOPMENT_BUILD; the
//! main build.zig wires everything together. None of this knows about
//! vendor libs or the engine.

const std = @import("std");
const opts_mod = @import("build_options.zig");
const Options = opts_mod.Options;

// Project metadata — keep in sync with CMakeLists.txt:7-22.
pub const PROJECT_NAME = "luanti";
pub const PROJECT_NAME_CAPITALIZED = "Luanti";
pub const VERSION_MAJOR = 5;
pub const VERSION_MINOR = 17;
pub const VERSION_PATCH = 0;
pub const DEVELOPMENT_BUILD = true;

// Compile-time feature probes — the boolean answers CMake's
// `check_include_files` calls would give. Static OS-based detection is
// good enough for the platforms Luanti supports.
pub const ConfigProbes = struct {
    have_endian_h: bool,
    have_strlcpy: bool,
    have_malloc_trim: bool,

    pub fn detect(os_tag: std.Target.Os.Tag) ConfigProbes {
        return switch (os_tag) {
            .linux => .{
                .have_endian_h = true,
                .have_strlcpy = false, // glibc historically lacks it; musl >= 1.2.2 has it
                .have_malloc_trim = true,
            },
            .freebsd, .openbsd, .netbsd, .dragonfly => .{
                .have_endian_h = true,
                .have_strlcpy = true,
                .have_malloc_trim = false,
            },
            .haiku => .{
                .have_endian_h = true,
                .have_strlcpy = true,
                .have_malloc_trim = false,
            },
            .macos, .ios, .driverkit, .tvos, .visionos, .watchos => .{
                .have_endian_h = false, // Darwin uses <libkern/OSByteOrder.h>
                .have_strlcpy = true,
                .have_malloc_trim = false,
            },
            else => .{
                .have_endian_h = false,
                .have_strlcpy = false,
                .have_malloc_trim = false,
            },
        };
    }
};

pub const InstallDirs = struct {
    sharedir: []const u8,
    bindir: []const u8,
    docdir: []const u8,
    example_conf_dir: []const u8,
    mandir: []const u8,
    xdg_apps_dir: []const u8,
    metainfodir: []const u8,
    icondir: []const u8,
    localedir: []const u8,
};

// Mirrors CMakeLists.txt:43-59. Disable LTO on Apple targets and on
// Windows+GCC; disable on Debug builds.
pub fn defaultLto(os_tag: std.Target.Os.Tag, optimize: std.builtin.OptimizeMode) bool {
    if (optimize == .Debug) return false;
    if (os_tag.isDarwin()) return false;
    // GCC on Windows can't link with LTO; we can't tell GCC vs Clang at this
    // point so conservatively disable on all Windows targets. Users can
    // override with -Denable-lto=true.
    if (os_tag == .windows) return false;
    return true;
}

// Mirrors CMakeLists.txt:24-34.
pub fn computeVersionString(b: *std.Build, version_extra: []const u8, optimize: std.builtin.OptimizeMode) []const u8 {
    var s = b.fmt("{d}.{d}.{d}", .{ VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH });
    if (version_extra.len > 0) {
        s = b.fmt("{s}-{s}", .{ s, version_extra });
    } else if (DEVELOPMENT_BUILD) {
        s = b.fmt("{s}-dev", .{s});
    }
    if (optimize == .Debug) {
        s = b.fmt("{s}-debug", .{s});
    }
    return s;
}

// Mirrors GenerateVersion.cmake. Runs git at build-script time and returns
// "<VERSION_STRING>-<hash>[-dirty]" in development builds, else VERSION_STRING.
pub fn computeGitVersion(b: *std.Build, version_string: []const u8) []const u8 {
    if (!DEVELOPMENT_BUILD) return version_string;

    const hash = runGit(b, &.{ "rev-parse", "--short", "HEAD" }) orelse return version_string;
    const dirty = (runGitExitCode(b, &.{ "diff-index", "--quiet", "HEAD" }) orelse 0) != 0;

    return if (dirty)
        b.fmt("{s}-{s}-dirty", .{ version_string, hash })
    else
        b.fmt("{s}-{s}", .{ version_string, hash });
}

fn buildGitArgv(b: *std.Build, args: []const []const u8) ?[][]const u8 {
    const argv = b.allocator.alloc([]const u8, args.len + 1) catch return null;
    argv[0] = "git";
    for (args, 0..) |a, i| argv[i + 1] = a;
    return argv;
}

// Returns trimmed stdout on success, null on any failure (missing git,
// not a repo, non-zero exit, etc.). Matches GenerateVersion.cmake which
// silently tolerates a missing repo.
fn runGit(b: *std.Build, args: []const []const u8) ?[]const u8 {
    const argv = buildGitArgv(b, args) orelse return null;
    defer b.allocator.free(argv);

    var code: u8 = undefined;
    const stdout = b.runAllowFail(argv, &code, .ignore) catch return null;
    return std.mem.trim(u8, stdout, " \t\r\n");
}

// Returns the exit code on a clean process termination. Used for
// `git diff-index --quiet HEAD` which encodes the answer in its exit
// status rather than its stdout.
fn runGitExitCode(b: *std.Build, args: []const []const u8) ?u8 {
    const argv = buildGitArgv(b, args) orelse return null;
    defer b.allocator.free(argv);

    var code: u8 = undefined;
    _ = b.runAllowFail(argv, &code, .ignore) catch |err| switch (err) {
        error.ExitCodeFailure => return code,
        else => return null,
    };
    return 0;
}

// Mirrors CMakeLists.txt:145-233.
pub fn computeInstallDirs(b: *std.Build, os_tag: std.Target.Os.Tag, opts: Options) InstallDirs {
    var d: InstallDirs = if (os_tag == .windows) .{
        .sharedir = ".",
        .bindir = "bin",
        .docdir = "doc",
        .example_conf_dir = ".",
        .mandir = "",
        .xdg_apps_dir = "",
        .metainfodir = "",
        .icondir = "",
        .localedir = "locale",
    } else if (os_tag.isDarwin()) blk: {
        const bundle = b.fmt("{s}.app", .{PROJECT_NAME});
        const bindir = b.fmt("{s}/Contents/MacOS", .{bundle});
        const sharedir = b.fmt("{s}/Contents/Resources", .{bundle});
        const docdir = b.fmt("{s}/{s}", .{ sharedir, PROJECT_NAME });
        break :blk .{
            .sharedir = sharedir,
            .bindir = bindir,
            .docdir = docdir,
            .example_conf_dir = docdir,
            .mandir = "",
            .xdg_apps_dir = "",
            .metainfodir = "",
            .icondir = "",
            .localedir = b.fmt("{s}/locale", .{sharedir}),
        };
    } else if (opts.run_in_place) .{
        .sharedir = ".",
        .bindir = "bin",
        .docdir = "doc",
        .example_conf_dir = ".",
        .mandir = "unix/man",
        .xdg_apps_dir = "unix/applications",
        .metainfodir = "unix/metainfo",
        .icondir = "unix/icons",
        .localedir = "locale",
    } else .{
        // Defaults match GNUInstallDirs with prefix /usr/local. Users
        // override with --prefix at install time or -Dcustom-*=... here.
        .sharedir = "/usr/local/share/" ++ PROJECT_NAME,
        .bindir = "/usr/local/bin",
        .docdir = "/usr/local/share/doc/" ++ PROJECT_NAME,
        .example_conf_dir = "/usr/local/share/doc/" ++ PROJECT_NAME,
        .mandir = "/usr/local/share/man",
        .xdg_apps_dir = "/usr/local/share/applications",
        .metainfodir = "/usr/local/share/metainfo",
        .icondir = "/usr/local/share/icons",
        .localedir = "/usr/local/share/locale",
    };

    if (opts.custom_sharedir.len > 0) d.sharedir = opts.custom_sharedir;
    if (opts.custom_bindir.len > 0) d.bindir = opts.custom_bindir;
    if (opts.custom_docdir.len > 0) d.docdir = opts.custom_docdir;
    if (opts.custom_mandir.len > 0) d.mandir = opts.custom_mandir;
    if (opts.custom_example_conf_dir.len > 0) d.example_conf_dir = opts.custom_example_conf_dir;
    if (opts.custom_xdg_apps_dir.len > 0) d.xdg_apps_dir = opts.custom_xdg_apps_dir;
    if (opts.custom_icondir.len > 0) d.icondir = opts.custom_icondir;
    if (opts.custom_localedir.len > 0) d.localedir = opts.custom_localedir;

    return d;
}

// CMAKE_BUILD_TYPE values: Debug, Release, RelWithDebInfo, MinSizeRel,
// SemiDebug (custom). Mapping from Zig's OptimizeMode to CMake's strings keeps
// log output and `cmake_config.h`'s BUILD_TYPE define identical to the CMake
// build for the same optimization level.
pub fn buildTypeName(optimize: std.builtin.OptimizeMode) []const u8 {
    return switch (optimize) {
        .Debug => "Debug",
        .ReleaseSafe => "RelWithDebInfo",
        .ReleaseFast => "Release",
        .ReleaseSmall => "MinSizeRel",
    };
}

// Mirrors src/cmake_config.h.in line-for-line. Split across two b.fmt
// calls because std.fmt enforces a 32-argument-per-call limit.
pub fn renderCmakeConfigH(
    b: *std.Build,
    version_string: []const u8,
    d: InstallDirs,
    optimize: std.builtin.OptimizeMode,
    opts: Options,
    probes: ConfigProbes,
) []const u8 {
    const head = b.fmt(
        \\// Filled in by the build system
        \\
        \\#pragma once
        \\
        \\#define PROJECT_NAME "{s}"
        \\#define PROJECT_NAME_C "{s}"
        \\#define VERSION_MAJOR {d}
        \\#define VERSION_MINOR {d}
        \\#define VERSION_PATCH {d}
        \\#define VERSION_EXTRA "{s}"
        \\#define VERSION_STRING "{s}"
        \\#define PRODUCT_VERSION_STRING "{d}.{d}"
        \\#define STATIC_SHAREDIR "{s}"
        \\#define STATIC_LOCALEDIR "{s}"
        \\#define BUILD_TYPE "{s}"
        \\#define ICON_DIR "{s}"
        \\
    , .{
        PROJECT_NAME,
        PROJECT_NAME_CAPITALIZED,
        VERSION_MAJOR,
        VERSION_MINOR,
        VERSION_PATCH,
        opts.version_extra,
        version_string,
        VERSION_MAJOR,
        VERSION_MINOR,
        d.sharedir,
        d.localedir,
        buildTypeName(optimize),
        d.icondir,
    });

    const flags = b.fmt(
        \\#define RUN_IN_PLACE {d}
        \\#define DEVELOPMENT_BUILD {d}
        \\#define ENABLE_UPDATE_CHECKER {d}
        \\#define USE_GETTEXT {d}
        \\#define USE_CURL {d}
        \\#define USE_SOUND {d}
        \\#define USE_CURSES {d}
        \\#define USE_LEVELDB {d}
        \\#define USE_LUAJIT {d}
        \\#define USE_POSTGRESQL {d}
        \\#define USE_PROMETHEUS {d}
        \\#define USE_SPATIAL {d}
        \\#define USE_SYSTEM_GMP {d}
        \\#define USE_SYSTEM_JSONCPP {d}
        \\#define USE_REDIS {d}
        \\#define USE_OPENSSL {d}
        \\#define HAVE_ENDIAN_H {d}
        \\#define HAVE_STRLCPY {d}
        \\#define HAVE_MALLOC_TRIM {d}
        \\#define CURSES_HAVE_CURSES_H 0
        \\#define CURSES_HAVE_NCURSES_H 0
        \\#define CURSES_HAVE_NCURSES_NCURSES_H 0
        \\#define CURSES_HAVE_NCURSES_CURSES_H 0
        \\#define CURSES_HAVE_NCURSESW_NCURSES_H 0
        \\#define CURSES_HAVE_NCURSESW_CURSES_H 0
        \\#define BUILD_UNITTESTS {d}
        \\#define BUILD_BENCHMARKS {d}
        \\#define USE_SDL2 {d}
        \\#define BUILD_WITH_TRACY {d}
        \\
    , .{
        @intFromBool(opts.run_in_place),
        @intFromBool(DEVELOPMENT_BUILD),
        @intFromBool(opts.enable_update_checker),
        @intFromBool(opts.enable_gettext),
        @intFromBool(opts.enable_curl),
        @intFromBool(opts.enable_sound),
        @intFromBool(opts.enable_curses),
        @intFromBool(opts.enable_leveldb),
        @intFromBool(opts.use_luajit),
        @intFromBool(opts.enable_postgresql),
        @intFromBool(opts.enable_prometheus),
        @intFromBool(opts.enable_spatial),
        @intFromBool(opts.use_system_gmp),
        @intFromBool(opts.use_system_jsoncpp),
        @intFromBool(opts.enable_redis),
        @intFromBool(opts.enable_openssl),
        @intFromBool(probes.have_endian_h),
        @intFromBool(probes.have_strlcpy),
        @intFromBool(probes.have_malloc_trim),
        @intFromBool(opts.build_unittests),
        @intFromBool(opts.build_benchmarks),
        @intFromBool(opts.use_sdl2),
        @intFromBool(opts.build_with_tracy),
    });

    return b.fmt("{s}{s}", .{ head, flags });
}

pub fn renderGitHashH(b: *std.Build, git_version: []const u8) []const u8 {
    return b.fmt(
        \\// Filled in by the build system
        \\// Separated from cmake_config.h to avoid excessive rebuilds on every commit
        \\
        \\#pragma once
        \\
        \\#define VERSION_GITHASH "{s}"
        \\
    , .{git_version});
}
