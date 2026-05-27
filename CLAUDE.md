# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`zig-luanti` is a **build-system-only fork** of [Luanti](https://github.com/luanti-org/luanti)
that replaces CMake with Zig's `build.zig`. Engine behavior, the Lua/SSCSM API, the
mod/game on-disk format, and the network protocol are **intentionally identical to
upstream — any divergence there is a bug** (see `FORK.md`). For engine work, go upstream.

The active work is a phased CMake→Zig migration on branch `zig-build-system`.
**`MIGRATION.md` is the single source of truth for phase status** — read it first to know
what's done (`[x]`), partial (`[~]`), or outstanding (`[ ]`). `CMakeLists.txt` remains the
**canonical** build until Phase 14 deletes it; the Zig build is validated A/B against it.

When editing the build, keep changes confined to the files `FORK.md` lists as fork-owned
(`build*.zig`, `build.zig.zon`, `MIGRATION.md`, `FORK.md`, `doc/zig-0-1-6-guide.md`,
the README fork header, `.gitignore`). Touching any other source file means you're either
fixing a real build-forced patch (keep it minimal, document it in the commit) or doing work
that belongs upstream instead.

## Build commands

Requires **Zig 0.16.0** (pinned in `build.zig.zon`). All output lands in `zig-out/`.

```bash
zig build                       # build + install everything to zig-out/
zig build luantiserver          # dedicated server exe only  -> zig-out/bin/luantiserver
zig build luanti                # client exe only            -> zig-out/bin/luanti
zig build <libname>             # one vendored static lib (jsoncpp, lua, sqlite3, IrrlichtMt, ...)
zig build --summary all         # show the full step graph
zig build -Doptimize=ReleaseFast        # Debug (default) | ReleaseFast | ReleaseSafe | ReleaseSmall
zig build -Dtarget=x86_64-windows-gnu   # cross-compile (Windows/macOS/Android phases still open)
```

Common `-D` options (full list + CMake-divergent defaults in `build_options.zig`):
`-Dbuild-client=` / `-Dbuild-server=` (both default **true**), `-Dbuild-unittests=`,
`-Denable-curl=`, `-Denable-sound=`, `-Duse-luajit=`. **Optional features default to `false`
during the migration** — they flip back to CMake's `true` only once their vendored dep lands.

Run / smoke-test the binaries:

```bash
./zig-out/bin/luantiserver --version    # Validation Gate 1 (passes)
./zig-out/bin/luanti                     # client; mainmenu render is the open Gate 2 blocker
```

### Running tests

The engine's test/benchmark suites run *inside* the binaries via the upstream CLI convention
(`--run-tests`, `--run-unittests`, `--test-module <name>`; see `src/main.cpp`). A `zig build test`
step **does not exist yet** — wiring `src/unittest/*`, `src/test/*`, and `src/benchmark/*` into the
exe is **Phase 10** (Catch2 groundwork is in, sources not yet attached). Until then, run the
existing suite through the **CMake reference build**.

### CMake reference build (canonical until Phase 14)

There is no checked-in `build/` dir; create one to A/B against the Zig output. See
`doc/compiling/linux.md`. Roughly: `cmake -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build`,
then `./build/bin/luanti --run-unittests`.

## Build-system architecture

`build.zig` is deliberately thin — it wires together four sibling modules:

| File | Responsibility |
|------|----------------|
| `build_options.zig` | Every `b.option(...)` behind `Options.parse(...)`; mirrors CMake's `option()`/cache vars. Documents where defaults intentionally diverge from CMake. |
| `build_config.zig`  | Version constants, install-dir layout, feature probes, and the generators for `cmake_config.h` + `cmake_config_githash.h`. |
| `build_engine.zig`  | The big `.cpp` source lists (`common_sources`, `server_sources`, `client_only_sources`, `irr_sources`) and shared compile flags/include paths. |
| `build_lib.zig`     | `addVendorLib(b, target, optimize, spec)` — the one reusable static-lib helper — plus `findLib` and the shared `cxx_flags`/`c_flags`. |

**Generated headers:** `cmake_config.h` and `cmake_config_githash.h` are produced by
`build_config.zig` (byte-compatible drop-ins for the CMake `.h.in` templates), written via
`addWriteFiles`, and reach every engine `.cpp` through the `-DUSE_CMAKE_CONFIG_H` define.

**Two ways deps are vendored:**
1. **In-tree** (`lib/…`, `irr/`): built via `addVendorLib` with an inline `VendorLib` spec
   literal in `build.zig` — jsoncpp, gmp, sha256, bitop, lua, lstrpack, tiniergltf (header-only
   Module), IrrlichtMt, EngineCommon.
2. **Fetched packages** (hash-pinned in `build.zig.zon`, mostly `allyourcodebase`): zlib, zstd,
   sqlite3, libpng, freetype, SDL2, mbedTLS, curl, Catch2. `libjpeg` is the exception —
   inline-compiled from the raw IJG tarball with a synthesized `jconfig.h`.

## Engine target structure

Three executables/libs share source lists exactly as upstream's CMake does:

- **EngineCommon** (`common_sources`) — the static lib of engine code shared by both binaries.
- **luantiserver** = `server_sources` on top of EngineCommon, compiled with `-DMT_BUILDTARGET=2`.
- **luanti** (client) = `server_sources` **+** `client_only_sources` on top of EngineCommon
  **+** IrrlichtMt, compiled with `-DMT_BUILDTARGET=1`. `MT_BUILDTARGET` gates the
  client/server branches in `src/main.cpp` via `src/config.h`.

`IrrlichtMt` (`irr_sources`) is the in-tree Irrlicht fork built as one static lib (SDL2 windowing
+ legacy GL + GL3 on Linux). The engine source tree under `src/` is upstream Luanti unchanged:
`client/`, `server/`, `script/` (Lua/SSCSM bindings), `mapgen/`, `network/`, `database/`, `gui/`,
`irrlicht_changes/`, `util/`, `content/`.

## Conventions & gotchas

- **Source lists mirror CMakeLists.txt line-for-line.** Each list in `build_engine.zig` cites
  the exact `src/**/CMakeLists.txt` lines it came from. When upstream adds/removes a `.cpp`,
  update the matching Zig list — that's the main recurring maintenance task during the migration.
- **`-fno-sanitize=undefined` is intentional** on every engine/Irrlicht TU. CMake doesn't enable
  UBSan in Debug; Zig's Debug C compile does, and the engine has float→int casts / signed overflow
  that trap. Do **not** remove this until Phase 15 fixes the underlying UB.
- **C++ standard is `c++17`** (client uses `gnu++17` — `irr/CFileSystem.cpp` breaks on
  `__STRICT_ANSI__`). The bump to C++23 is deliberately deferred to **Phase 15**, after CMake is gone.
- **Data dirs are installed under `zig-out/share/luanti/`** so the runtime `porting::setSystemPaths()`
  finds the `builtin/` marker; without them you get an `UNINITIALIZED/...` path error at startup.
- **Zig 0.16 API specifics** (Module-based `addCSourceFile`/`addIncludePath`, `addLibrary` with
  `.linkage = .static`, `link_libc`/`link_libcpp` as Module fields not methods): see
  `doc/zig-0-1-6-guide.md` — read it before touching the build.
- **Per-phase commits:** each phase ends in one focused commit on `zig-build-system`, pushed to
  `origin`, and flips its `[ ]`→`[x]` in `MIGRATION.md` in the same commit.
- **Lua lint:** `.luacheckrc` governs `builtin/` and game Lua; **C++ lint:** `.clang-tidy`.
