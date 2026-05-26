// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2010-2025 celeron55, Perttu Ahola <celeron55@gmail.com>
// Copyright (C) 2025 the zig-luanti contributors
//
// Phase 9.5: C-ABI hourglass implementation.
// All complex C++ objects and the old main() orchestration live behind these
// narrow C functions so that src/main.zig can own the real entry point.

#include "entry_abi.h"

#include <iostream>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "irrlichttypes_bloated.h"
#include "debug.h"
#include "version.h"
#include "defaultsettings.h"
#include "gettext.h"
#include "log.h"
#include "log_internal.h"
#include "porting.h"
#include "content/subgames.h"
#include "filesys.h"
#include "settings.h"
#include "gameparams.h"
#include "test/test.h"  // for run_catch2_tests / run_catch2_benchmarks (Phase 10)

// Lua headers for version printing (only needed in the non-LuaJIT path)
#if !USE_LUAJIT
extern "C" {
#include <lua.h>
}
#endif

// The original main.cpp has a lot of static helpers and globals
// (allowed_options, file_log_output, etc.). For the hourglass we hide
// that complexity here. In later increments we will extract more of the
// real logic instead of reimplementing small pieces.

extern const char *g_version_hash;
extern const char *g_build_info;

// Forward declarations for pieces we still pull from the old main logic
// (these are defined in main.cpp today; we will gradually move them).
// For the very first cut we reimplement the simplest printers here.

static void print_worldspecs(const std::vector<WorldSpec> &worldspecs,
	std::ostream &os, bool print_name, bool print_path);

// --- Public C ABI surface ---------------------------------------------------

void luanti_print_version(void)
{
	std::cout << PROJECT_NAME_C " " << g_version_hash
		<< " (" << porting::getPlatformName() << ")" << std::endl;
#if USE_LUAJIT
	std::cout << "Using " << LUAJIT_VERSION
#ifdef OPENRESTY_LUAJIT
		<< " (OpenResty)"
#endif
		<< std::endl;
#else
	std::cout << "Using " << LUA_RELEASE << std::endl;
#endif
#if defined(__clang__)
	std::cout << "Built by Clang " << __clang_major__ << "." << __clang_minor__ << std::endl;
#elif defined(__GNUC__)
	std::cout << "Built by GCC " << __GNUC__ << "." << __GNUC_MINOR__ << std::endl;
#elif defined(_MSC_VER)
	std::cout << "Built by MSVC " << (_MSC_VER / 100) << "." << (_MSC_VER % 100) << std::endl;
#endif
	std::cout << "Running on " << porting::get_sysinfo() << std::endl;
	std::cout << g_build_info << std::endl;
}

void luanti_print_help(void)
{
	// For the first cut we emit a minimal helpful message.
	// The full beautiful --help text still lives in the old main.cpp.
	// Once the full arg-parsing + allowed_options surface is migrated or
	// wrapped, we will call the real printer here.
	std::cout << PROJECT_NAME_C " " << g_version_hash << std::endl;
	std::cout << "Zig-built binary (Phase 9.5 C-ABI hourglass path)" << std::endl;
	std::cout << "Use --version for detailed version information." << std::endl;
	std::cout << "Full --help text is still provided by the classic path for now." << std::endl;
}

void luanti_list_game_ids(void)
{
	std::set<std::string> gameids = getAvailableGameIds();
	for (const std::string &gameid : gameids)
		rawstream << gameid << std::endl;
}

void luanti_list_worlds(int mode)
{
	std::cout << _("Available worlds:") << std::endl;
	std::vector<WorldSpec> worldspecs = getAvailableWorlds();
	bool print_name = (mode == 0 || mode == 2);
	bool print_path = (mode == 1 || mode == 2);
	print_worldspecs(worldspecs, std::cout, print_name, print_path);
}

// --- Heavy run paths (stubs for initial integration) ------------------------
// These will grow to contain (or call) the real init_common + game_configure
// + run_dedicated_server / ClientLauncher logic.

int luanti_run_server(int argc, char **argv)
{
	// TODO (Phase 9.5 incremental): replicate or call the real server launch path
	// that used to live in main(). For now this proves the ABI link works.
	(void)argc; (void)argv;
	errorstream << "[entry_abi] luanti_run_server: full implementation pending" << std::endl;
	return 0;
}

int luanti_run_client(int argc, char **argv)
{
	// TODO (Phase 9.5 incremental)
	(void)argc; (void)argv;
	errorstream << "[entry_abi] luanti_run_client: full implementation pending" << std::endl;
	return 0;
}

// --- Phase 10: Catch2 runners (called from the Zig entry point) -------------

int luanti_run_catch2_tests(int argc, char **argv)
{
	return run_catch2_tests(argc, argv);
}

int luanti_run_catch2_benchmarks(int argc, char **argv)
{
	return run_catch2_benchmarks(argc, argv);
}

// --- Internal helpers (small pieces extracted for the printers) -------------

static void print_worldspecs(const std::vector<WorldSpec> &worldspecs,
	std::ostream &os, bool print_name, bool print_path)
{
	for (const WorldSpec &worldspec : worldspecs) {
		const auto &name = worldspec.name;
		const auto &path = worldspec.path;

		if (print_name && print_path) {
			os << name << " " << path << std::endl;
		} else if (print_name) {
			os << name << std::endl;
		} else if (print_path) {
			os << path << std::endl;
		}
	}
}
