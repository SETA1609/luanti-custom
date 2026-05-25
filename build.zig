//! zig-luanti build system.
//!
//! This file is intentionally thin: it just wires together pieces from
//! sibling modules. Look there for the actual logic:
//!
//!   - `build_options.zig` — every `b.option(...)` lives behind
//!     `Options.parse(b, ...)`.
//!   - `build_config.zig`  — version constants, install-dir layout,
//!     feature probes, and the generators for cmake_config.h and
//!     cmake_config_githash.h.
//!   - `build_engine.zig`  — engine source lists and shared compile config.
//!   - `build_lib.zig`     — reusable `addVendorLib` helper.
//!
//! CMakeLists.txt remains the canonical build until Phase 14; this is the
//! parallel migration described in FORK.md.

const std = @import("std");

const vlib = @import("build_lib.zig");
const cfg = @import("build_config.zig");
const opts_mod = @import("build_options.zig");
const engine = @import("build_engine.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const os_tag = target.result.os.tag;

    const opts = opts_mod.Options.parse(b, os_tag, optimize);
    const probes = cfg.ConfigProbes.detect(os_tag);

    const version_string = cfg.computeVersionString(b, opts.version_extra, optimize);
    const install_dirs = cfg.computeInstallDirs(b, os_tag, opts);
    const git_version = cfg.computeGitVersion(b, version_string);

    // -------------------------------------------------------------------------
    // Generated headers — drop-in replacements for cmake_config.h.in and
    // cmake_config_githash.h.in. Consumed by every engine .cpp via the
    // -DUSE_CMAKE_CONFIG_H define in `engine.cxx_flags`.
    // -------------------------------------------------------------------------
    const generated = b.addWriteFiles();
    const cmake_config_h_lp = generated.add(
        "cmake_config.h",
        cfg.renderCmakeConfigH(b, version_string, install_dirs, optimize, opts, probes),
    );
    const cmake_config_githash_h_lp = generated.add(
        "cmake_config_githash.h",
        cfg.renderGitHashH(b, git_version),
    );
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(cmake_config_h_lp, .header, "cmake_config.h").step);
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(cmake_config_githash_h_lp, .header, "cmake_config_githash.h").step);

    // -------------------------------------------------------------------------
    // Phase 2 & 3: vendored libraries from lib/
    // -------------------------------------------------------------------------
    const jsoncpp = vlib.addVendorLib(b, target, optimize, .{
        .name = "jsoncpp",
        .sources = &.{"lib/jsoncpp/jsoncpp.cpp"},
        .include_paths = &.{"lib/jsoncpp"},
        .install_headers_dir = .{ .src = "lib/jsoncpp/json", .dest = "json" },
    });

    const gmp = vlib.addVendorLib(b, target, optimize, .{
        .name = "gmp",
        .sources = &.{"lib/gmp/mini-gmp.c"},
        .flags = &vlib.c_flags,
        .include_paths = &.{"lib/gmp"},
        .install_headers = &.{.{ .src = "lib/gmp/mini-gmp.h", .dest = "mini-gmp.h" }},
        .link = .c,
    });

    // sha256 needs a per-library cmake_config.h declaring whether <endian.h>
    // exists on the target. Synthesize and feed via generated_include_paths.
    const sha256_config_dir = blk: {
        const wf = b.addWriteFiles();
        _ = wf.add("cmake_config.h", if (probes.have_endian_h)
            "// Filled in by the build system\n\n#pragma once\n\n#define HAVE_ENDIAN_H\n"
        else
            "// Filled in by the build system\n\n#pragma once\n\n/* #undef HAVE_ENDIAN_H */\n");
        break :blk wf.getDirectory();
    };

    const sha256 = vlib.addVendorLib(b, target, optimize, .{
        .name = "sha256",
        .sources = &.{"lib/sha256/sha256.c"},
        .flags = &vlib.c_flags,
        .include_paths = &.{"lib/sha256"},
        .generated_include_paths = &.{sha256_config_dir},
        .install_headers = &.{.{ .src = "lib/sha256/my_sha256.h", .dest = "my_sha256.h" }},
        .link = .c,
    });

    const bitop = vlib.addVendorLib(b, target, optimize, .{
        .name = "bitop",
        .sources = &.{"lib/bitop/bit.cpp"},
        .include_paths = &.{ "lib/bitop", "lib/lua/src" },
        .install_headers = &.{.{ .src = "lib/bitop/bit.h", .dest = "bit.h" }},
    });

    // lib/lstrpack — single-file C library that backports Lua 5.3's
    // string.pack/unpack to the engine's Lua 5.1 runtime. Needs Lua headers
    // privately and exposes its own header publicly.
    // Mirrors lib/lstrpack/CMakeLists.txt:1-7.
    const lstrpack = vlib.addVendorLib(b, target, optimize, .{
        .name = "lstrpack",
        .sources = &.{"lib/lstrpack/lstrpack.c"},
        .flags = &vlib.c_flags,
        .include_paths = &.{ "lib/lstrpack", "lib/lua/src" },
        .install_headers = &.{.{ .src = "lib/lstrpack/lstrpack.h", .dest = "lstrpack.h" }},
        .link = .c,
    });

    // tiniergltf is header-only — exposed as a Module rather than a static
    // lib so downstream targets can pull in its include paths via addImport.
    const tiniergltf = b.addModule("tiniergltf", .{ .target = target, .optimize = optimize });
    tiniergltf.addIncludePath(b.path("lib/tiniergltf"));
    tiniergltf.addIncludePath(b.path("lib/jsoncpp"));
    tiniergltf.addIncludePath(b.path("src"));

    // Lua 5.1.4. .c sources compiled as C++ to match upstream's
    // set_source_files_properties(LANGUAGE CXX). LUA_USE_POSIX / DLOPEN /
    // MACOSX / BUILD_AS_DLL gated on os_tag.
    const lua_flags: []const []const u8 = switch (os_tag) {
        .macos, .ios, .driverkit, .tvos, .visionos, .watchos => &.{
            "-std=c++17", "-DLUA_USE_POSIX", "-DLUA_USE_MACOSX", "-DLUA_USE_DLOPEN",
        },
        .linux => &.{ "-std=c++17", "-DLUA_USE_POSIX", "-DLUA_USE_DLOPEN" },
        .freebsd, .openbsd, .netbsd, .dragonfly => &.{ "-std=c++17", "-DLUA_USE_POSIX" },
        .windows => &.{ "-std=c++17", "-DLUA_BUILD_AS_DLL" },
        else => &.{ "-std=c++17", "-DLUA_ANSI" },
    };

    const lua = vlib.addVendorLib(b, target, optimize, .{
        .name = "lua",
        .sources = &lua_sources,
        .flags = lua_flags,
        .language = .cpp,
        .include_paths = &.{"lib/lua/src"},
        .install_headers = &.{
            .{ .src = "lib/lua/src/lua.h", .dest = "lua.h" },
            .{ .src = "lib/lua/src/lauxlib.h", .dest = "lauxlib.h" },
            .{ .src = "lib/lua/src/lualib.h", .dest = "lualib.h" },
            .{ .src = "lib/lua/src/luaconf.h", .dest = "luaconf.h" },
        },
    });

    // -------------------------------------------------------------------------
    // Phase 4: foundation deps via Zig's package manager.
    // Hashes are pinned in build.zig.zon.
    // -------------------------------------------------------------------------
    const zlib = b.dependency("zlib", .{ .target = target, .optimize = optimize }).artifact("z");
    const zstd = b.dependency("zstd", .{ .target = target, .optimize = optimize }).artifact("zstd");
    const sqlite3 = b.dependency("sqlite3", .{ .target = target, .optimize = optimize }).artifact("sqlite3");

    // -------------------------------------------------------------------------
    // Phase 5: EngineCommon static library.
    //
    // C++ engine code shared between client and server. mapgen, scripting,
    // server-net, gui, client-net, and irrlicht_changes live with their
    // respective executables (Phases 6, 9).
    // -------------------------------------------------------------------------
    const engine_common = vlib.addVendorLib(b, target, optimize, .{
        .name = "EngineCommon",
        .sources = &engine.common_sources,
        .flags = &engine.cxx_flags,
        .include_paths = &engine.include_paths,
        .generated_include_paths = &.{generated.getDirectory()},
    });
    engine_common.root_module.linkLibrary(zlib);
    engine_common.root_module.linkLibrary(zstd);
    engine_common.root_module.linkLibrary(sqlite3);
    engine_common.root_module.linkLibrary(sha256);
    engine_common.root_module.linkLibrary(jsoncpp);
    engine_common.root_module.linkLibrary(gmp);
    if (!opts.use_luajit) engine_common.root_module.linkLibrary(lua);

    // -------------------------------------------------------------------------
    // Phase 6: luantiserver executable.
    //
    // Adds `engine.server_sources` (108 .cpp files: common_SRCS direct +
    // mapgen + script + common_server + server_network) on top of
    // EngineCommon. MT_BUILDTARGET=2 tells src/config.h that this is a
    // server build, which gates the client-only branches in main.cpp.
    // Catch2 / unittest sources are NOT wired in yet — Phase 10 does that.
    // -------------------------------------------------------------------------
    const luantiserver = if (opts.build_server) blk: {
        const exe_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        });
        const server_flags = [_][]const u8{
            "-std=c++17",
            "-fno-strict-aliasing",
            "-DUSE_CMAKE_CONFIG_H",
            "-DMT_BUILDTARGET=2",
        };
        for (engine.server_sources) |src| {
            exe_mod.addCSourceFile(.{ .file = b.path(src), .flags = &server_flags });
        }
        for (engine.include_paths) |p| exe_mod.addIncludePath(b.path(p));
        exe_mod.addIncludePath(generated.getDirectory());

        exe_mod.linkLibrary(engine_common);
        exe_mod.linkLibrary(zlib);
        exe_mod.linkLibrary(zstd);
        exe_mod.linkLibrary(sqlite3);
        exe_mod.linkLibrary(sha256);
        exe_mod.linkLibrary(jsoncpp);
        exe_mod.linkLibrary(gmp);
        exe_mod.linkLibrary(lstrpack);
        if (!opts.use_luajit) {
            exe_mod.linkLibrary(lua);
            exe_mod.linkLibrary(bitop);
        }

        const exe = b.addExecutable(.{
            .name = "luantiserver",
            .root_module = exe_mod,
        });

        // PLATFORM_LIBS — src/CMakeLists.txt:285-366. Threads come in via
        // libc, but dl/rt have to be explicit on Linux.
        switch (os_tag) {
            .linux => {
                exe.root_module.linkSystemLibrary("dl", .{});
                exe.root_module.linkSystemLibrary("rt", .{});
            },
            .freebsd, .openbsd, .netbsd, .dragonfly => {
                exe.root_module.linkSystemLibrary("pthread", .{});
            },
            .windows => {
                exe.root_module.linkSystemLibrary("ws2_32", .{});
                exe.root_module.linkSystemLibrary("shlwapi", .{});
                exe.root_module.linkSystemLibrary("winmm", .{});
                exe.root_module.linkSystemLibrary("version", .{});
            },
            else => {},
        }

        break :blk exe;
    } else null;

    // -------------------------------------------------------------------------
    // Installs & per-library convenience steps.
    // -------------------------------------------------------------------------
    b.installArtifact(jsoncpp);
    b.installArtifact(gmp);
    b.installArtifact(sha256);
    if (!opts.use_luajit) {
        b.installArtifact(bitop);
        b.installArtifact(lua);
    }
    b.installArtifact(lstrpack);
    b.installArtifact(zlib);
    b.installArtifact(zstd);
    b.installArtifact(sqlite3);
    b.installArtifact(engine_common);
    if (luantiserver) |exe| b.installArtifact(exe);

    for ([_]struct { name: []const u8, lib: *std.Build.Step.Compile }{
        .{ .name = "jsoncpp", .lib = jsoncpp },
        .{ .name = "gmp", .lib = gmp },
        .{ .name = "sha256", .lib = sha256 },
        .{ .name = "bitop", .lib = bitop },
        .{ .name = "lua", .lib = lua },
        .{ .name = "lstrpack", .lib = lstrpack },
        .{ .name = "zlib", .lib = zlib },
        .{ .name = "zstd", .lib = zstd },
        .{ .name = "sqlite3", .lib = sqlite3 },
        .{ .name = "EngineCommon", .lib = engine_common },
    }) |e| {
        const step = b.step(e.name, b.fmt("Build {s} static lib", .{e.name}));
        step.dependOn(&e.lib.step);
    }
    if (luantiserver) |exe| {
        const step = b.step("luantiserver", "Build the Luanti dedicated server executable");
        step.dependOn(&exe.step);
    }
}

// lib/lua/src/CMakeLists.txt:5-34. Kept here rather than in
// build_engine.zig because it's about a vendored library, not the engine
// proper.
const lua_sources = [_][]const u8{
    "lib/lua/src/lapi.c",
    "lib/lua/src/lauxlib.c",
    "lib/lua/src/lbaselib.c",
    "lib/lua/src/lcode.c",
    "lib/lua/src/ldblib.c",
    "lib/lua/src/ldebug.c",
    "lib/lua/src/ldo.c",
    "lib/lua/src/ldump.c",
    "lib/lua/src/lfunc.c",
    "lib/lua/src/lgc.c",
    "lib/lua/src/linit.c",
    "lib/lua/src/liolib.c",
    "lib/lua/src/llex.c",
    "lib/lua/src/lmathlib.c",
    "lib/lua/src/lmem.c",
    "lib/lua/src/loadlib.c",
    "lib/lua/src/lobject.c",
    "lib/lua/src/lopcodes.c",
    "lib/lua/src/loslib.c",
    "lib/lua/src/lparser.c",
    "lib/lua/src/lstate.c",
    "lib/lua/src/lstring.c",
    "lib/lua/src/lstrlib.c",
    "lib/lua/src/ltable.c",
    "lib/lua/src/ltablib.c",
    "lib/lua/src/ltm.c",
    "lib/lua/src/lundump.c",
    "lib/lua/src/lvm.c",
    "lib/lua/src/lzio.c",
};
