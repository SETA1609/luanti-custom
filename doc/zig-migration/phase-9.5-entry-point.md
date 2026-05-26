# Phase 9.5 Design: C-ABI Hourglass Entry Point Migration

**Status**: Design phase (plan mode)  
**Branch**: `zig-build-system`  
**Goal**: Move the application entry-point logic from `src/main.cpp` into `src/main.zig` while keeping the CMake build 100% unaffected and the C++ engine logic untouched for now.

---

## Context & Motivation

- MIGRATION.md lists Phase 9.5 as the next step after the client executable (Phase 9) builds and runs.
- The current Zig build compiles `src/main.cpp` (via `server_sources`) as a normal C++ source; the real `main` symbol comes from there.
- Goal of this phase: **Zig owns the true program entry point** (`pub fn main` in `src/main.zig`).
- This enables future benefits:
  - Better panic handling, std.process, cross-platform arg handling from Zig.
  - Incremental port of startup/orchestration logic out of C++.
  - Cleaner separation (Zig layer on top, C-ABI "hourglass" in the middle, C++ engine below).

The user clarified the desired direction (2025-04):

> "instead of calling the main file from the main file extern c the functions that where called in main and migrate main.cpp to main.zig"

This means:
- Do **not** just wrap the entire body of `main()` behind one `extern "C" luanti_run()`.
- Instead, expose (via C ABI) the individual high-level functions that `main()` calls, and re-implement the orchestration/flow in `src/main.zig`.

---

## Current State (from exploration)

### Key file
- [src/main.cpp](/home/sebastian/private/luanti-custom/src/main.cpp) (~1400 lines)
  - One large `main()` function.
  - ~30 `static` helper functions defined only inside this translation unit (print_version, list_worlds, game_configure_*, get_world_from_*, determine_subgame, setup_log_params, etc.).
  - Early exits for `--version`, `--help`, `--worldlist`, `--run-unittests`, `--run-tests`, `--run-benchmarks`.
  - Heavy use of `Settings`, `GameStartData` / `GameParams`, `std::string`, `std::vector<WorldSpec>`.
  - Calls into `porting::`, `g_logger`, `ClientLauncher::run()`, `run_dedicated_server()`, `init_common()`, `game_configure()`, etc.

### Data types that cross the boundary today
- `GameParams` / `GameStartData` (contain `std::string`, `SubgameSpec`, `WorldSpec`).
- `Settings` (rich C++ class with layers, callbacks, parsing).
- `std::ostream&` for printing helpers.
- Many private helpers only exist in `main.cpp`.

### Existing C-ABI patterns in the tree
- Lua C API wrappers (`extern "C"` around Lua state usage).
- Very little application-level C ABI surface today.

### Build integration points
- `build_engine.zig:268` — `main.cpp` lives in `server_sources` (thus compiled for both server and client).
- `build.zig` (lines ~344-401 for server, ~417-490 for client):
  - Creates `exe_mod` (C++ module with `link_libcpp`).
  - Adds dozens of `.cpp` via `addCSourceFile` using `server_flags` / `client_flags`.
  - Never sets `root_source_file` today → the C++ `main` is the entry point.
- CMake side (src/CMakeLists.txt:474) simply lists `main.cpp` for both targets.

---

## Recommended Approach

**"Narrow C-ABI hourglass + progressive logic migration"**

1. **Introduce a new narrow C-ABI surface** (new files, compiled only when needed):
   - `src/entry_abi.h` — pure C declarations.
   - `src/entry_abi.cpp` — C++ implementations that wrap the real engine functions. These are thin shims that hide `std::string`, `Settings`, `GameStartData`, etc.

   Initial proposed surface (minimal for a working `--version` / `--help` / launch path):

   ```c
   // Early / informational paths (easy to implement)
   void luanti_print_version(void);
   void luanti_print_help(void);
   void luanti_list_worlds(int mode);           // 0=name, 1=path, 2=both
   void luanti_list_game_ids(void);

   // High-level run paths (the real hourglass)
   // These will internally do init_common + game_configure + the right launcher.
   int luanti_run_server(int argc, char **argv);
   int luanti_run_client(int argc, char **argv);

   // Or even narrower single entry for first cut:
   int luanti_run_from_cli(int argc, char **argv);
   ```

   Over time we can split further (expose `luanti_init_common`, `luanti_game_configure`, `luanti_run_dedicated_server`, a `ClientLauncher` handle, etc.) as more logic moves into Zig.

2. **Create `src/main.zig`** (the real replacement for the C++ `main` body):
   - `pub fn main() void`.
   - Collects args (via `std.os.argv` or `std.process.argsAlloc`).
   - Implements the early-return decision tree currently in C++ (`--version`, `--help`, `--worldlist`, test modes, etc.).
   - For the heavy paths, calls the C-ABI functions above.
   - Handles exit codes.
   - Over time, more of the helper logic (world selection, subgame determination, etc.) can be ported or re-expressed in Zig, calling only leaf C++ operations.

3. **Build system changes (Zig side only)** — [build.zig](/home/sebastian/private/luanti-custom/build.zig):
   - When building `luantiserver` / `luanti` executables:
     - Set `exe_mod.root_source_file = b.path("src/main.zig")`.
     - **Do not** compile `src/main.cpp` into the Zig executables (remove it from the source lists or guard it).
     - Compile `src/entry_abi.cpp` (add it via `addCSourceFile` or as a small static lib).
     - Pass any necessary defines (e.g. `-DLUANTI_BUILDING_WITH_ZIG`) if entry_abi.cpp needs to know.
   - The `server_sources` / `client_only_sources` lists in `build_engine.zig` stay unchanged for now (we just stop pulling `main.cpp` at the exe level).
   - Optional later cleanup: move `main.cpp` out of `server_sources` entirely and treat it as "CMake-only".

4. **CMake compatibility (zero breakage)**:
   - `src/main.cpp` keeps its original `int main(int argc, char *argv[])` completely unchanged.
   - `src/entry_abi.cpp` and `src/entry_abi.h` are simply additional files that CMake will need to be told about (or we can `#ifdef` them out for CMake builds, or put the new files under a Zig-only guard).
   - Easiest: add the two new files to the appropriate CMake targets (or make them empty/no-op when `BUILD_WITH_ZIG` is not defined). Since CMake remains canonical until Phase 14, we must not require the new files for a working CMake build.

5. **Incremental migration strategy** (important for this phase):
   - **Milestone 0 (this phase)**: Get a working `--version`, `--help`, server launch, and client launch through the new path.
   - Later (post 9.5): Gradually move individual helpers (`print_version`, world listing, game_configure logic, etc.) from C++ into Zig, shrinking the C++ side of the hourglass.
   - The C-ABI surface can be expanded on demand as Zig code wants to drive more pieces directly.

---

## Files to Create / Modify

### New files
| Path                              | Purpose                                      | Language |
|-----------------------------------|----------------------------------------------|----------|
| `src/entry_abi.h`                 | Pure C declarations for the hourglass        | C header |
| `src/entry_abi.cpp`               | Thin C++ shims that call real engine logic   | C++      |
| `src/main.zig`                    | Zig implementation of the old main() flow    | Zig      |
| `doc/zig-migration/phase-9.5-entry-point.md` | This design doc (and future updates)     | Markdown |

### Modified files
| Path                    | Change                                                                 |
|-------------------------|------------------------------------------------------------------------|
| `build.zig`             | Wire `root_source_file`, stop compiling old `main.cpp` for Zig exes, add `entry_abi.cpp` |
| `build_engine.zig`      | (Optional) stop listing `main.cpp` in `server_sources` if we move it   |
| `src/CMakeLists.txt`    | Add the two new entry files so CMake builds still work (or guard them) |
| `MIGRATION.md`          | Mark Phase 9.5 complete once validated                                   |

---

## Detailed Design Notes

### Why not one big `luanti_run()` wrapper?

The user explicitly rejected the "whole main body behind one extern C" approach. Exposing the functions that `main` actually calls gives us:
- A real migration of the entry-point logic (not just a trampoline).
- Ability to rewrite pieces in Zig over time (arg parsing, help text, world selection heuristics, etc.).
- Better testability from the Zig side in the future.

### Handling rich C++ types across the ABI

Options (in order of preference for this phase):

1. **Hide them completely** inside the C-ABI shims (`entry_abi.cpp` constructs `Settings`, `GameStartData`, etc. internally and only exposes `const char*`, `bool`, simple ints).
2. **Provide opaque handles** + accessor functions only if Zig code genuinely needs to inspect them later.
3. **Serialize** to simple C structs for the most common cases (world path, gameid, address, etc.).

For Phase 9.5 we strongly recommend option 1 for the first cut.

### Example thin wrapper (sketch)

```cpp
// entry_abi.cpp
extern "C" int luanti_run_server(int argc, char **argv) {
    // replicate just enough of the old main() path
    Settings cmd_args;
    // ... parse, init_common, game_configure ...
    GameParams params; // or GameStartData
    // ...
    return run_dedicated_server(params, cmd_args) ? 0 : 1;
}
```

The Zig side only ever sees `int` / `[*c][*c]u8`.

### What about all the private static helpers?

They fall into categories:
- Pure output (print_version, print_help, list_worlds, list_game_ids) → expose directly or reimplement in Zig + call C++ printing primitives.
- Decision logic (get_world_from_cmdline, determine_subgame, auto_select_world, game_configure_*) → either port the logic to Zig over time or wrap the whole "configure" step.
- Setup (setup_log_params, create_userdata_path, use_debugger, init_common) → wrap at the appropriate granularity.

We don't have to expose all 30 on day one. Start with the minimal set needed to make the four main launch modes work.

---

## Verification Plan

1. **Build both sides**
   - `zig build luantiserver` and `zig build luanti` succeed.
   - Classic `cmake && make` still succeeds and produces identical behavior.

2. **Smoke tests (Zig-built binaries)**
   - `./zig-out/bin/luantiserver --version` prints the correct Luanti version string.
   - `./zig-out/bin/luanti --version`
   - `./zig-out/bin/luanti --help` (and server --help)
   - `./zig-out/bin/luanti --worldlist name|path|both`
   - `./zig-out/bin/luantiserver --gameid devtest --worldname TestWorld` (creates world and runs briefly, or at least doesn't crash on startup).
   - Client launch into a local world (smoke GUI or headless as appropriate).

3. **No behavior change**
   - Compare output of `--version`, `--help`, world listing between CMake-built and Zig-built binaries.
   - Run the same world creation + short dedicated server session with both builds.

4. **CMake still works unchanged**
   - After changes, a clean CMake configure + build + install must still produce a working `luanti` and `luantiserver`.

5. **Update checklist**
   - Tick Phase 9.5 in [MIGRATION.md](/home/sebastian/private/luanti-custom/MIGRATION.md).
   - Note any follow-up work (further logic migration, removal of old main.cpp from common sources, etc.).

---

## Open Questions / Risks (to resolve before or during implementation)

- How much of the private helper logic do we want to port in this phase vs keep behind the ABI for now?
- Do we want nicer Zig-native `--help` text eventually, or keep calling the C++ printers for identical output?
- Will we need any changes to `porting::initializePaths()` or global state setup order when the entry point moves?
- Should `entry_abi.cpp` live under `src/` or a new `src/entry/` subdir?

These can be answered incrementally; the design above gives a safe starting surface.

---

## Next Steps After Approval

1. Create the three new source files (`entry_abi.h`, `entry_abi.cpp`, `main.zig`) with minimal working surface.
2. Wire them in `build.zig` (and update CMakeLists.txt).
3. Implement the first working path (e.g. `--version` + dedicated server launch).
4. Expand to full client + all early options.
5. Validate, commit, update MIGRATION.md, push.

This phase is deliberately scoped to the entry point only — no changes to Irrlicht, media, or the rest of the engine.
