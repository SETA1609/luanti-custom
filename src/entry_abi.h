// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2010-2025 celeron55, Perttu Ahola <celeron55@gmail.com>
// Copyright (C) 2025 the zig-luanti contributors
//
// Phase 9.5: C-ABI hourglass for the application entry point.
// This header declares the narrow interface that src/main.zig (Zig build)
// uses to drive startup. All complex C++ types (Settings, GameStartData,
// std::string, etc.) are hidden inside the implementation in entry_abi.cpp.
//
// CMake builds continue to use the original main() in src/main.cpp unchanged.
// These symbols are only referenced when building via Zig.

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// --- Informational / early-exit paths (called before full engine init) ---

/// Print the classic version string to stdout (matches old print_version behavior).
void luanti_print_version(void);

/// Print the full --help text (matches old print_help behavior).
void luanti_print_help(void);

/// List available game IDs (one per line).
void luanti_list_game_ids(void);

/// List worlds. mode: 0 = name only, 1 = path only, 2 = both (matches --worldlist).
void luanti_list_worlds(int mode);

// --- High-level run paths (the real "hourglass") ---
// These perform argument parsing, init_common, game_configure, and dispatch
// to either the dedicated server or ClientLauncher, exactly as the old main()
// did. They return the traditional process exit code (0 on success).

/// Full entry point for dedicated server builds / --server mode.
int luanti_run_server(int argc, char **argv);

/// Full entry point for the interactive client (and local singleplayer).
int luanti_run_client(int argc, char **argv);

// --- Phase 10: Test / benchmark runners (exposed for the Zig entry point) ---

int luanti_run_catch2_tests(int argc, char **argv);
int luanti_run_catch2_benchmarks(int argc, char **argv);

#ifdef __cplusplus
}
#endif
