const std = @import("std");
const vlib = @import("build_lib.zig");

// =============================================================================
// zig-luanti build system — Phase 1
//
// This file is being grown incrementally to replace the CMake build (see
// branch zig-build-system). For the migration plan and current phase, refer
// to the project memory.
//
// Phase 1 status:
//   - All CMake options() are mirrored as b.option().
//   - cmake_config.h and cmake_config_githash.h are generated to
//     zig-out/include/ with byte-compatible content.
//   - No C/C++ compilation yet — that begins in Phase 2.
//
// CMakeLists.txt is the source of truth; cross-reference the option/default
// comments below if you change anything here.
// =============================================================================

// Project metadata — keep in sync with CMakeLists.txt:7-22.
const PROJECT_NAME = "luanti";
const PROJECT_NAME_CAPITALIZED = "Luanti";
const VERSION_MAJOR = 5;
const VERSION_MINOR = 17;
const VERSION_PATCH = 0;
const DEVELOPMENT_BUILD = true;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const os_tag = target.result.os.tag;

    // -------------------------------------------------------------------------
    // Build flags (CMakeLists.txt:37-90, src/CMakeLists.txt:51-271)
    // -------------------------------------------------------------------------
    const opts = Options{
        // Top-level build switches
        .build_client = b.option(bool, "build-client", "Build client") orelse true,
        .build_server = b.option(bool, "build-server", "Build server") orelse false,
        .build_unittests = b.option(bool, "build-unittests", "Build unittests") orelse true,
        .build_benchmarks = b.option(bool, "build-benchmarks", "Build benchmarks") orelse false,
        .build_documentation = b.option(bool, "build-documentation", "Build Doxygen docs") orelse true,

        // Misc top-level
        .run_in_place = b.option(bool, "run-in-place", "Run directly in source directory structure") orelse (os_tag == .windows),
        .warn_all = b.option(bool, "warn-all", "Enable -Wall for Release build") orelse true,
        .enable_update_checker = b.option(bool, "enable-update-checker", "Enable update checks by default") orelse !DEVELOPMENT_BUILD,
        .enable_lto = b.option(bool, "enable-lto", "Use Link Time Optimization") orelse defaultLto(os_tag, optimize),
        .build_with_tracy = b.option(bool, "build-with-tracy", "Build with the Tracy profiler client") orelse false,
        .version_extra = b.option([]const u8, "version-extra", "String to append to version") orelse "",

        // Optional dependencies. CMake's defaults are mostly `true` — the
        // CMake build then silently disables anything `find_package` can't
        // locate. The Zig build vendors every dep we ship, so the matching
        // pattern here is: default to `true` only once the dep has actually
        // landed in this branch. Until Phase 7 vendors curl/freetype/etc.,
        // the corresponding flags below default to `false` so EngineCommon
        // builds out-of-the-box and the rest of the engine compiles cleanly.
        // Flip them back to true (or pass -Denable-...=true) as their deps
        // come in.
        .enable_curl = b.option(bool, "enable-curl", "Use cURL for HTTP (deps land in Phase 7)") orelse false,
        .enable_gettext = b.option(bool, "enable-gettext", "Use gettext for translations (Phase 7)") orelse false,
        .enable_sound = b.option(bool, "enable-sound", "Enable sound (client; Phase 7)") orelse false,
        .enable_curses = b.option(bool, "enable-curses", "Enable curses console (server)") orelse false,
        .enable_postgresql = b.option(bool, "enable-postgresql", "Enable PostgreSQL backend") orelse false,
        .enable_leveldb = b.option(bool, "enable-leveldb", "Enable LevelDB backend") orelse false,
        .enable_redis = b.option(bool, "enable-redis", "Enable Redis backend") orelse false,
        .enable_prometheus = b.option(bool, "enable-prometheus", "Enable Prometheus metrics") orelse false,
        .enable_spatial = b.option(bool, "enable-spatial", "Enable libspatialindex (server entity AOI)") orelse false,
        .enable_openssl = b.option(bool, "enable-openssl", "Use OpenSSL for SHA256 acceleration") orelse false,
        .use_luajit = b.option(bool, "use-luajit", "Use LuaJIT instead of vendored Lua 5.1") orelse false,
        .use_sdl2 = b.option(bool, "use-sdl2", "Use SDL2 as the windowing/input backend") orelse true,
        .use_system_gmp = b.option(bool, "use-system-gmp", "Link the system GMP instead of the vendored copy") orelse false,
        .use_system_jsoncpp = b.option(bool, "use-system-jsoncpp", "Link the system jsoncpp instead of the vendored copy") orelse false,

        // Custom install directories (CMakeLists.txt:184-233)
        .custom_sharedir = b.option([]const u8, "custom-sharedir", "Directory to install data files into") orelse "",
        .custom_bindir = b.option([]const u8, "custom-bindir", "Directory to install binaries into") orelse "",
        .custom_docdir = b.option([]const u8, "custom-docdir", "Directory to install documentation into") orelse "",
        .custom_mandir = b.option([]const u8, "custom-mandir", "Directory to install manpages into") orelse "",
        .custom_example_conf_dir = b.option([]const u8, "custom-example-conf-dir", "Directory to install example config into") orelse "",
        .custom_xdg_apps_dir = b.option([]const u8, "custom-xdg-apps-dir", "Directory to install .desktop files into") orelse "",
        .custom_icondir = b.option([]const u8, "custom-icondir", "Directory to install icons into") orelse "",
        .custom_localedir = b.option([]const u8, "custom-localedir", "Directory to install l10n files into") orelse "",
    };

    const version_string = computeVersionString(b, opts.version_extra, optimize);
    const dirs = computeInstallDirs(b, os_tag, opts);
    const git_version = computeGitVersion(b, version_string);

    // -------------------------------------------------------------------------
    // Generated headers (replaces src/cmake_config.h.in + GenerateVersion.cmake)
    // -------------------------------------------------------------------------
    const platform_probes = ConfigProbes.detect(os_tag);

    const generated = b.addWriteFiles();
    const cmake_config_h_lp = generated.add(
        "cmake_config.h",
        renderCmakeConfigH(b, version_string, dirs, optimize, opts, platform_probes),
    );
    const cmake_config_githash_h_lp = generated.add(
        "cmake_config_githash.h",
        b.fmt(
            \\// Filled in by the build system
            \\// Separated from cmake_config.h to avoid excessive rebuilds on every commit
            \\
            \\#pragma once
            \\
            \\#define VERSION_GITHASH "{s}"
            \\
        ,
            .{git_version},
        ),
    );

    // Install the headers so they can be inspected (and so downstream tools
    // that haven't picked up the LazyPath yet can find them).
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(cmake_config_h_lp, .header, "cmake_config.h").step);
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(cmake_config_githash_h_lp, .header, "cmake_config_githash.h").step);

    // Future C/C++ targets will consume these via:
    //   exe.addIncludePath(generated.getDirectory());
    // For now, we just expose them so they can be inspected after `zig build`.

    // -------------------------------------------------------------------------
    // Phase 2: vendored libraries from lib/
    //
    // Each lib is described inline as a vlib.VendorLib spec; the only shared
    // path is `vlib.addVendorLib`. Add a new lib here as another addVendorLib
    // call — don't introduce per-lib wrapper functions.
    //
    // The libs aren't linked into anything yet — that wiring lands in
    // Phase 5+. For now `zig build` only verifies they compile in isolation.
    // -------------------------------------------------------------------------

    const jsoncpp = vlib.addVendorLib(b, target, optimize, .{
        .name = "jsoncpp",
        .sources = &.{"lib/jsoncpp/jsoncpp.cpp"},
        .include_paths = &.{"lib/jsoncpp"},
        .install_headers_dir = .{ .src = "lib/jsoncpp/json", .dest = "json" },
        // Mirrors lib/jsoncpp/CMakeLists.txt:1.
    });

    const gmp = vlib.addVendorLib(b, target, optimize, .{
        .name = "gmp",
        .sources = &.{"lib/gmp/mini-gmp.c"},
        .flags = &vlib.c_flags,
        .include_paths = &.{"lib/gmp"},
        .install_headers = &.{.{ .src = "lib/gmp/mini-gmp.h", .dest = "mini-gmp.h" }},
        .link = .c,
        // Mirrors lib/gmp/CMakeLists.txt:1.
    });

    // sha256 needs a tiny per-library cmake_config.h that declares whether
    // <endian.h> exists on the target. We synthesize it here and feed the
    // resulting LazyPath in via `generated_include_paths`.
    // Mirrors lib/sha256/CMakeLists.txt:1-15 + lib/sha256/cmake_config.h.in.
    const sha256_config_dir = blk: {
        const has_endian_h = switch (os_tag) {
            .linux, .freebsd, .openbsd, .netbsd, .dragonfly, .haiku => true,
            else => false,
        };
        const wf = b.addWriteFiles();
        _ = wf.add("cmake_config.h", if (has_endian_h)
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

    // bitop needs the Lua headers (lib/lua/src) — the headers exist on
    // disk now; Phase 3 builds the Lua library itself. Only relevant when
    // the user is NOT on LuaJIT.
    // Mirrors lib/bitop/CMakeLists.txt:1-2.
    const bitop = vlib.addVendorLib(b, target, optimize, .{
        .name = "bitop",
        .sources = &.{"lib/bitop/bit.cpp"},
        .include_paths = &.{ "lib/bitop", "lib/lua/src" },
        .install_headers = &.{.{ .src = "lib/bitop/bit.h", .dest = "bit.h" }},
    });

    // Phase 3: vendored Lua 5.1.4
    //
    // Mirrors lib/lua/CMakeLists.txt + lib/lua/src/CMakeLists.txt. Two
    // upstream quirks worth flagging:
    //  - The 28 source files have `.c` extensions but upstream forces them
    //    to compile as C++ (set_source_files_properties LANGUAGE CXX). We
    //    do the same via `.language = .cpp` on the VendorLib spec.
    //  - LUA_USE_POSIX / LUA_USE_DLOPEN / LUA_USE_MACOSX / LUA_BUILD_AS_DLL
    //    are platform-gated. The flag composition matches CMake's branches
    //    in lib/lua/CMakeLists.txt:12-58 exactly.
    //
    // The library is skipped under -Duse-luajit=true because LuaJIT
    // replaces it wholesale; Phase 3 only adds the vendored fallback.
    const lua_flags: []const []const u8 = switch (os_tag) {
        .macos, .ios, .driverkit, .tvos, .visionos, .watchos => &.{
            "-std=c++23",
            "-DLUA_USE_POSIX",
            "-DLUA_USE_MACOSX",
            "-DLUA_USE_DLOPEN",
        },
        .linux => &.{
            "-std=c++23",
            "-DLUA_USE_POSIX",
            "-DLUA_USE_DLOPEN",
        },
        .freebsd, .openbsd, .netbsd, .dragonfly => &.{
            "-std=c++23",
            "-DLUA_USE_POSIX",
        },
        .windows => &.{
            "-std=c++23",
            "-DLUA_BUILD_AS_DLL",
        },
        else => &.{
            "-std=c++23",
            "-DLUA_ANSI",
        },
    };

    const lua = vlib.addVendorLib(b, target, optimize, .{
        .name = "lua",
        .sources = &.{
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
        },
        .flags = lua_flags,
        .language = .cpp, // upstream compiles .c as C++.
        .include_paths = &.{"lib/lua/src"},
        .install_headers = &.{
            .{ .src = "lib/lua/src/lua.h", .dest = "lua.h" },
            .{ .src = "lib/lua/src/lauxlib.h", .dest = "lauxlib.h" },
            .{ .src = "lib/lua/src/lualib.h", .dest = "lualib.h" },
            .{ .src = "lib/lua/src/luaconf.h", .dest = "luaconf.h" },
        },
    });

    // tiniergltf is header-only — expose its include paths as a Module that
    // downstream C++ targets can pull in via `addImport`.
    // Mirrors lib/tiniergltf/CMakeLists.txt:11-22.
    const tiniergltf = b.addModule("tiniergltf", .{ .target = target, .optimize = optimize });
    tiniergltf.addIncludePath(b.path("lib/tiniergltf"));
    tiniergltf.addIncludePath(b.path("lib/jsoncpp"));
    tiniergltf.addIncludePath(b.path("src"));

    // -------------------------------------------------------------------------
    // Phase 4: foundation deps (zlib, zstd, sqlite3)
    //
    // Fetched as Zig packages via build.zig.zon. Each package's own
    // build.zig compiles the upstream sources from a hashed tarball, so
    // these are vendored-from-source just like the lib/ entries above —
    // just managed by the Zig package manager instead of being checked
    // into this repo.
    // -------------------------------------------------------------------------
    const zlib_dep = b.dependency("zlib", .{ .target = target, .optimize = optimize });
    const zlib = zlib_dep.artifact("z");

    const zstd_dep = b.dependency("zstd", .{ .target = target, .optimize = optimize });
    const zstd = zstd_dep.artifact("zstd");

    const sqlite3_dep = b.dependency("sqlite3", .{ .target = target, .optimize = optimize });
    const sqlite3 = sqlite3_dep.artifact("sqlite3");

    // Install artifacts so they appear under zig-out/lib/ and zig-out/include/.
    // Bitop and Lua are conditional: only needed when the user is NOT using
    // LuaJIT (LuaJIT has its own Lua runtime AND a built-in `bit` library).
    b.installArtifact(jsoncpp);
    b.installArtifact(gmp);
    b.installArtifact(sha256);
    if (!opts.use_luajit) {
        b.installArtifact(bitop);
        b.installArtifact(lua);
    }
    b.installArtifact(zlib);
    b.installArtifact(zstd);
    b.installArtifact(sqlite3);

    // -------------------------------------------------------------------------
    // Phase 5: EngineCommon static library
    //
    // Holds the C++ engine code that is shared between client and server.
    // Mirrors what CMake assembles into the OBJECT library `EngineCommon`
    // at src/CMakeLists.txt:607-623 — i.e. `independent_SRCS` plus the
    // util/threading/content/database/network-common subtrees. mapgen,
    // scripting, server-net and client-net are deliberately NOT here; they
    // are added to their respective executables in Phases 6 and 9.
    //
    // EngineCommon picks up its compile-time configuration from
    // cmake_config.h (the generated header from Phase 1) gated by
    // -DUSE_CMAKE_CONFIG_H. Several engine .cpp files (httpfetch, curses,
    // leveldb/redis/postgres backends, prometheus, etc.) compile to stubs
    // when their feature flag is 0 — so they live unconditionally in the
    // source list and the corresponding -Denable-... option controls
    // whether their body is emitted.
    // -------------------------------------------------------------------------
    const engine_common = vlib.addVendorLib(b, target, optimize, .{
        .name = "EngineCommon",
        .sources = &engine_common_sources,
        .flags = &engine_cxx_flags,
        .include_paths = &engine_include_paths,
        .generated_include_paths = &.{generated.getDirectory()},
    });

    // Bring in include paths from the vendored deps. linkLibrary at the
    // static-lib level propagates include directories without emitting
    // any actual link, which is exactly what an OBJECT library needs.
    engine_common.root_module.linkLibrary(zlib);
    engine_common.root_module.linkLibrary(zstd);
    engine_common.root_module.linkLibrary(sqlite3);
    engine_common.root_module.linkLibrary(sha256);
    engine_common.root_module.linkLibrary(jsoncpp);
    engine_common.root_module.linkLibrary(gmp);
    if (!opts.use_luajit) engine_common.root_module.linkLibrary(lua);

    b.installArtifact(engine_common);

    // Named convenience steps so users can build a single lib in isolation,
    // e.g. `zig build jsoncpp` or `zig build EngineCommon`.
    for ([_]struct { name: []const u8, lib: *std.Build.Step.Compile }{
        .{ .name = "jsoncpp", .lib = jsoncpp },
        .{ .name = "gmp", .lib = gmp },
        .{ .name = "sha256", .lib = sha256 },
        .{ .name = "bitop", .lib = bitop },
        .{ .name = "lua", .lib = lua },
        .{ .name = "zlib", .lib = zlib },
        .{ .name = "zstd", .lib = zstd },
        .{ .name = "sqlite3", .lib = sqlite3 },
        .{ .name = "EngineCommon", .lib = engine_common },
    }) |e| {
        const step = b.step(e.name, b.fmt("Build {s} static lib", .{e.name}));
        step.dependOn(&e.lib.step);
    }
}

// -----------------------------------------------------------------------------
// Phase 5 source lists and compile config.
//
// Kept at file scope so they're easy to diff against the CMake source lists.
// If upstream adds a .cpp to one of the referenced CMakeLists, add it here too.
// -----------------------------------------------------------------------------

// Mirrors src/CMakeLists.txt:420-456 plus the PARENT_SCOPE source lists from
// src/{util,threading,content,database,network}/CMakeLists.txt.
const engine_common_sources = [_][]const u8{
    // independent_SRCS — src/CMakeLists.txt:420-449
    "src/chat.cpp",
    "src/content_nodemeta.cpp",
    "src/convert_json.cpp",
    "src/craftdef.cpp",
    "src/debug.cpp",
    "src/face_position_cache.cpp",
    "src/gettext_plural_form.cpp",
    "src/httpfetch.cpp",
    "src/hud_element.cpp",
    "src/inventory.cpp",
    "src/itemstackmetadata.cpp",
    "src/log.cpp",
    "src/metadata.cpp",
    "src/modchannels.cpp",
    "src/nameidmapping.cpp",
    "src/nodemetadata.cpp",
    "src/nodetimer.cpp",
    "src/noise.cpp",
    "src/objdef.cpp",
    "src/object_properties.cpp",
    "src/particles.cpp",
    "src/profiler.cpp",
    "src/serialization.cpp",
    "src/settings.cpp",
    "src/sound_spec.cpp",
    "src/staticobject.cpp",
    "src/terminal_chat_console.cpp",
    "src/texture_override.cpp",
    "src/tileanimation.cpp",
    "src/tool.cpp",

    // util_SRCS — src/util/CMakeLists.txt:5-26
    "src/util/areastore.cpp",
    "src/util/auth.cpp",
    "src/util/base64.cpp",
    "src/util/colorize.cpp",
    "src/util/directiontables.cpp",
    "src/util/enriched_string.cpp",
    "src/util/guid.cpp",
    "src/util/hashing.cpp",
    "src/util/ieee_float.cpp",
    "src/util/metricsbackend.cpp",
    "src/util/numeric.cpp",
    "src/util/pointedthing.cpp",
    "src/util/pointabilities.cpp",
    "src/util/quicktune.cpp",
    "src/util/serialize.cpp",
    "src/util/screenshot.cpp",
    "src/util/sha1.cpp",
    "src/util/string.cpp",
    "src/util/srp.cpp",
    "src/util/timetaker.cpp",
    "src/util/png.cpp",
    "src/util/enum_string.cpp",

    // threading_SRCS — src/threading/CMakeLists.txt:5-7
    "src/threading/event.cpp",
    "src/threading/thread.cpp",
    "src/threading/semaphore.cpp",

    // content_SRCS — src/content/CMakeLists.txt:5-9
    "src/content/content.cpp",
    "src/content/mod_configuration.cpp",
    "src/content/mods.cpp",
    "src/content/subgames.cpp",

    // database_SRCS — src/database/CMakeLists.txt:5-12
    "src/database/database.cpp",
    "src/database/database-dummy.cpp",
    "src/database/database-files.cpp",
    "src/database/database-leveldb.cpp",
    "src/database/database-postgresql.cpp",
    "src/database/database-redis.cpp",
    "src/database/database-sqlite3.cpp",

    // common_network_SRCS — src/network/CMakeLists.txt:5-11
    "src/network/address.cpp",
    "src/network/connection.cpp",
    "src/network/mtp/impl.cpp",
    "src/network/mtp/threads.cpp",
    "src/network/networkpacket.cpp",
    "src/network/networkprotocol.cpp",
    "src/network/socket.cpp",
};

// C++23, plus the USE_CMAKE_CONFIG_H toggle (src/CMakeLists.txt:281) that
// tells engine .cpp files to read cmake_config.h instead of falling back
// to default constants. -Wno-* knobs trim the noise from Luanti's C++17
// code being compiled at C++23.
const engine_cxx_flags = [_][]const u8{
    "-std=c++23",
    "-fno-strict-aliasing",
    "-DUSE_CMAKE_CONFIG_H",
};

// Include directories EngineCommon needs at compile time. Headers from the
// vendored zlib/zstd/sqlite3/lua/jsoncpp/gmp/sha256 deps come in via
// `linkLibrary` calls above (Zig propagates the dep's installed include
// paths transitively).
const engine_include_paths = [_][]const u8{
    "src",
    "src/script",
    "lib/jsoncpp",
    "lib/gmp",
    "lib/sha256",
    "lib/lua/src",
    "irr/include",
};

// =============================================================================
// Helpers
// =============================================================================

const Options = struct {
    build_client: bool,
    build_server: bool,
    build_unittests: bool,
    build_benchmarks: bool,
    build_documentation: bool,

    run_in_place: bool,
    warn_all: bool,
    enable_update_checker: bool,
    enable_lto: bool,
    build_with_tracy: bool,
    version_extra: []const u8,

    enable_curl: bool,
    enable_gettext: bool,
    enable_sound: bool,
    enable_curses: bool,
    enable_postgresql: bool,
    enable_leveldb: bool,
    enable_redis: bool,
    enable_prometheus: bool,
    enable_spatial: bool,
    enable_openssl: bool,
    use_luajit: bool,
    use_sdl2: bool,
    use_system_gmp: bool,
    use_system_jsoncpp: bool,

    custom_sharedir: []const u8,
    custom_bindir: []const u8,
    custom_docdir: []const u8,
    custom_mandir: []const u8,
    custom_example_conf_dir: []const u8,
    custom_xdg_apps_dir: []const u8,
    custom_icondir: []const u8,
    custom_localedir: []const u8,
};

const InstallDirs = struct {
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

// Compile-time feature probes — the boolean answers CMake's
// `check_include_files` calls would give. Static OS-based detection is
// good enough for the platforms Luanti supports.
const ConfigProbes = struct {
    have_endian_h: bool,
    have_strlcpy: bool,
    have_malloc_trim: bool,

    fn detect(os_tag: std.Target.Os.Tag) ConfigProbes {
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

// Mirrors CMakeLists.txt:43-59. Disable LTO on Apple targets and on
// Windows+GCC; disable on Debug builds.
fn defaultLto(os_tag: std.Target.Os.Tag, optimize: std.builtin.OptimizeMode) bool {
    if (optimize == .Debug) return false;
    if (os_tag.isDarwin()) return false;
    // GCC on Windows can't link with LTO; we can't tell GCC vs Clang at this
    // point so conservatively disable on all Windows targets. Users can
    // override with -Denable-lto=true.
    if (os_tag == .windows) return false;
    return true;
}

// Mirrors CMakeLists.txt:24-34.
fn computeVersionString(b: *std.Build, version_extra: []const u8, optimize: std.builtin.OptimizeMode) []const u8 {
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
fn computeGitVersion(b: *std.Build, version_string: []const u8) []const u8 {
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
fn computeInstallDirs(b: *std.Build, os_tag: std.Target.Os.Tag, opts: Options) InstallDirs {
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
fn buildTypeName(optimize: std.builtin.OptimizeMode) []const u8 {
    return switch (optimize) {
        .Debug => "Debug",
        .ReleaseSafe => "RelWithDebInfo",
        .ReleaseFast => "Release",
        .ReleaseSmall => "MinSizeRel",
    };
}

// Mirrors src/cmake_config.h.in line-for-line. Split across two b.fmt
// calls because std.fmt enforces a 32-argument-per-call limit.
fn renderCmakeConfigH(
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
