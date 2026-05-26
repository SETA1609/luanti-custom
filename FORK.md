# zig-luanti

A fork of [Luanti](https://github.com/luanti-org/luanti) that swaps the CMake
build system for [Zig](https://ziglang.org/)'s `build.zig`. Maintained by
[@SETA1609](https://github.com/SETA1609).

## Why fork?

Modernising the build system is invasive — it touches every dependency, every
target, every platform. Keeping that work as a fork lets us:

1. **Move fast on `build.zig`** without disrupting upstream's release cadence.
2. **Vendor all dependencies through Zig** (no system pkg-config probing) so
   builds are hermetic and trivially cross-compile.
3. **Improve maintainability**: fewer build files, declarative library
   descriptions, options that read like a config file.

## What is intentionally *not* forked

zig-luanti is **build-system only**. The following remain identical to
upstream and any divergence here is a bug:

- Engine behavior, physics, rendering pipeline
- The Lua / client-Lua / SSCSM API (`doc/lua_api.md`, `doc/client_lua_api.md`,
  `doc/sscsm_api.md`)
- The mod and game on-disk format (`doc/world_format.md`,
  `doc/builtin_entities.md`)
- Network protocol versions
- LGPL 2.1+ licensing of engine code and the licenses of vendored libs
  in `lib/` and `irr/`

If a build-system change forces a source modification, it goes into the
smallest possible patch and is documented in the commit message.

## Migration status

The CMake → Zig migration is happening in phases on branch
`zig-build-system`. CMake remains the canonical build until the final
phase deletes `CMakeLists.txt` everywhere.

**See [MIGRATION.md](MIGRATION.md)** for the live checklist — phases
are ticked off there as they ship.

## Zig build-system reference

Conventions used across `build.zig`, `build_lib.zig`, `build_config.zig`,
`build_options.zig`, and `build_engine.zig` are documented in
[`doc/zig-0-1-6-guide.md`](doc/zig-0-1-6-guide.md). If you touch the
build, read that first — it's where the canonical 0.16 API patterns
(Module-based `addCSourceFile`/`addIncludePath`, `addLibrary` with
`.linkage = .static`, `addTranslateC`) are spelled out.

## Pulling upstream

```
git remote add upstream https://github.com/luanti-org/luanti.git
git fetch upstream
git rebase upstream/master    # on zig-build-system
```

Rebases stay clean as long as the fork's edits are confined to:

- `build.zig`, `build.zig.zon`, `build_lib.zig`, `build_config.zig`,
  `build_options.zig`, `build_engine.zig`
- `MIGRATION.md`, `FORK.md`, `doc/zig-0-1-6-guide.md`
- `README.md` (just the small fork-header block above the existing intro)
- `.gitignore` (entries for `.zig-cache/`, `zig-out/`, `zig-pkg/`)

If you find yourself editing any other file, ask whether it belongs upstream
instead.

## License

zig-luanti inherits Luanti's licensing in full:
[LGPL 2.1 or later](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)
for the engine, plus the per-asset / per-vendored-lib licenses listed in
`LICENSE.txt`, `irr/LICENSE`, and the individual `lib/*` directories.
