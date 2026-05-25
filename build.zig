const std = @import("std");

// Phase 0: scaffolding only. No targets are produced yet.
// Subsequent phases will incrementally add:
//   - build options mirroring CMakeLists.txt (Phase 1)
//   - generated headers (cmake_config.h, cmake_config_githash.h) (Phase 1)
//   - vendored libraries from lib/ (Phase 2-3)
//   - foundation deps zlib/zstd/sqlite3 (Phase 4)
//   - EngineCommon static lib (Phase 5)
//   - luantiserver executable (Phase 6)
//   - client media stack + IrrlichtMt + luanti client (Phases 7-9)
//   - tests, platform targets, CMake removal (Phases 10-14)
pub fn build(b: *std.Build) void {
    _ = b;
}
