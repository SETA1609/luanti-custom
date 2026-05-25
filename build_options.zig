//! Build options.
//!
//! All `b.option(...)` calls live here behind a single `Options.parse(b, ...)`
//! entry point. Mirrors the option / set CACHE lines in CMakeLists.txt and
//! src/CMakeLists.txt. The defaults for optional features deliberately
//! diverge from CMake during the migration: see the comment block in
//! `parse` for the rationale.

const std = @import("std");
const cfg = @import("build_config.zig");

pub const Options = struct {
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

    pub fn parse(
        b: *std.Build,
        os_tag: std.Target.Os.Tag,
        optimize: std.builtin.OptimizeMode,
    ) Options {
        return .{
            // Top-level build switches (CMakeLists.txt:37-42).
            // CMake defaults: client=true, server=false, unittests=true.
            // The zig-luanti fork flips two during the migration:
            //  - server defaults to true (server-first validation path).
            //  - unittests defaults to false until Phase 10 vendors Catch2.
            .build_client = b.option(bool, "build-client", "Build client") orelse true,
            .build_server = b.option(bool, "build-server", "Build server") orelse true,
            .build_unittests = b.option(bool, "build-unittests", "Build unittests (needs Catch2; Phase 10)") orelse false,
            .build_benchmarks = b.option(bool, "build-benchmarks", "Build benchmarks (needs Catch2; Phase 10)") orelse false,
            .build_documentation = b.option(bool, "build-documentation", "Build Doxygen docs") orelse true,

            // Misc top-level (CMakeLists.txt:60-90)
            .run_in_place = b.option(bool, "run-in-place", "Run directly in source directory structure") orelse (os_tag == .windows),
            .warn_all = b.option(bool, "warn-all", "Enable -Wall for Release build") orelse true,
            .enable_update_checker = b.option(bool, "enable-update-checker", "Enable update checks by default") orelse !cfg.DEVELOPMENT_BUILD,
            .enable_lto = b.option(bool, "enable-lto", "Use Link Time Optimization") orelse cfg.defaultLto(os_tag, optimize),
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
    }
};
