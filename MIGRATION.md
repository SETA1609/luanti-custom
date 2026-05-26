# zig-luanti migration checklist

CMake → Zig build-system migration. Branch: `zig-build-system`.
CMake remains the canonical build until Phase 14 deletes it.

Mark items `[x]` as they ship to this branch. Mark sub-items `[~]` when the
parent phase is partially complete but deliberately deferred (see the note
under each one).

## Phases

- [x] **Phase 0** — `build.zig` + `build.zig.zon` scaffolding
- [x] **Phase 1** — Mirror every CMake option; generate `cmake_config.h` and `cmake_config_githash.h` byte-compatibly
- [x] **Phase 2** — Vendor small in-tree libs (jsoncpp, sha256, tiniergltf, gmp, bitop)
- [x] **Phase 3** — Vendor Lua 5.1.4 (sources compiled as C++, matching upstream)
- [x] **Phase 4** — Foundation deps via Zig package manager (zlib, zstd, sqlite3)
- [x] **Phase 5** — Build `EngineCommon` static library (73 .cpp files shared by client + server)
- [x] **Phase 6** — Build `luantiserver` executable — **VALIDATION GATE 1 PASSED** ✓ runs and reports the right version
- [~] **Phase 7** — Client media stack
  - [x] libpng (allyourcodebase, 1.6.57)
  - [x] libjpeg (inline-vendored from IJG v9f tarball — no working community package)
  - [x] freetype (allyourcodebase, 2.14.3)
  - [x] SDL2 (allyourcodebase, 2.32.10)
  - [x] mbedTLS (allyourcodebase, 3.6.4) — TLS backend for curl
  - [x] curl (allyourcodebase, 8.18.0, `http-only`, mbedtls backend)
  - [ ] libogg — *deferred, only needed once `enable_sound=true`*
  - [ ] libvorbis — *deferred, sound-only*
  - [ ] openal-soft — *deferred, sound-only*
- [x] **Phase 8** — IrrlichtMt (SDL2 windowing, legacy GL + GL3 backends; Linux desktop default)
- [x] **Phase 9** — Build `luanti` (client) executable — VALIDATION GATE 2 ✓ builds, `--version` runs; full gameplay validation pending user test
- [ ] **Phase 9.5** — Translate entry-point `.cpp` files (`src/main.cpp`) to Zig via the C-ABI hourglass pattern
- [ ] **Phase 10** — Wire up Catch2 + `src/unittest/` + `src/benchmark/` (`zig build test`)
- [ ] **Phase 11** — Windows cross-compile (`-Dtarget=x86_64-windows-{gnu,msvc}`)
- [ ] **Phase 12** — macOS `.app` bundle (Info.plist substitution, aarch64-macos + x86_64-macos)
- [ ] **Phase 13** — Android `.so` (replace `externalNativeBuild` in Gradle)
- [ ] **Phase 14** — Delete all 29 `CMakeLists.txt` files, `cmake/`, `*.cmake.in`; update CI & docs
- [ ] **Phase 15+** — Modernize engine sources from C++17 to C++23 (post-migration sweep)

## Validation gates

End-to-end behavior must be confirmed by the user before crossing these:

| Gate | After phase | What runs                                                                  |
|------|-------------|----------------------------------------------------------------------------|
| 1    | Phase 6     | `zig-out/bin/luantiserver --version` reports the right Luanti version ✓    |
| 2    | Phase 9     | Zig-built client launches, renders a world, takes input, plays no sound    |

## Notes

- This file is the single source of truth for phase status. The rest of the
  build documentation in `FORK.md` just points here.
- Each phase ends with one focused commit on `zig-build-system` and a push
  to `origin` so progress is recoverable.
- Optional engine features (`enable-curl`, `enable-leveldb`, …) default to
  `false` during the migration; they flip back to CMake's `true` defaults as
  their vendored deps land in Phase 7 / Phase 9.
