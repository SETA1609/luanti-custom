//! Zig entry point for Luanti (Phase 9.5 — C-ABI hourglass migration).
//!
//! This file is the real `main` when the project is built with the Zig
//! build system. It owns the high-level startup orchestration that used
//! to live in src/main.cpp.
//!
//! Instead of wrapping the entire old main() behind one extern "C"
//! function, we call the individual operations that main() used to call
//! (the "functions that were called in main") via the narrow C-ABI surface
//! declared in entry_abi.h / implemented in entry_abi.cpp.
//!
//! CMake builds are completely unaffected — they still use the original
//! main() in src/main.cpp.

const std = @import("std");
const c = @cImport({
    @cInclude("entry_abi.h");
});

/// Very small hand-rolled argument scanner for the early paths.
/// We deliberately keep this tiny for the first cut. Full command-line
/// parsing (the old allowed_options table, etc.) will be migrated or
/// wrapped in follow-up work inside this file or the ABI layer.
fn has_flag(args: []const [:0]const u8, name: []const u8) bool {
    for (args) |a| {
        if (std.mem.eql(u8, a, name)) return true;
    }
    return false;
}

fn get_flag_value(args: []const [:0]const u8, name: []const u8) ?[:0]const u8 {
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], name) and i + 1 < args.len) {
            return args[i + 1];
        }
    }
    return null;
}

pub fn main() void {
    // Proper argument collection for Zig 0.16.
    // This enables --run-tests / --run-benchmarks (Phase 10) and all the
    // other flags that the old main.cpp used to handle.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args_iter = std.process.argsWithAllocator(allocator) catch {
        std.debug.print("Failed to read process arguments\n", .{});
        std.process.exit(1);
    };
    defer args_iter.deinit();

    var arg_list = std.ArrayList([:0]const u8).init(allocator);
    defer arg_list.deinit();

    while (args_iter.next()) |arg| {
        arg_list.append(arg) catch std.process.exit(1);
    }
    const all_args = arg_list.items;

    // argv[0] is the program name; the rest are real arguments.
    const args = if (all_args.len > 0) all_args[1..] else all_args[0..0];

    // --- Early informational paths (no engine init required) ---

    if (has_flag(args, "--version") or has_flag(args, "-v")) {
        c.luanti_print_version();
        return;
    }

    if (has_flag(args, "--help") or has_flag(args, "-h") or has_flag(args, "-?")) {
        c.luanti_print_help();
        return;
    }

    if (has_flag(args, "--worldlist")) {
        // Accept the same values the old code did: name / path / both
        if (get_flag_value(args, "--worldlist")) |val| {
            if (std.mem.eql(u8, val, "name")) {
                c.luanti_list_worlds(0);
            } else if (std.mem.eql(u8, val, "path")) {
                c.luanti_list_worlds(1);
            } else {
                c.luanti_list_worlds(2);
            }
        } else {
            c.luanti_list_worlds(2);
        }
        return;
    }

    if (has_flag(args, "--gameid") and get_flag_value(args, "--gameid") != null and
        std.mem.eql(u8, get_flag_value(args, "--gameid").?, "list"))
    {
        c.luanti_list_game_ids();
        return;
    }

    // --- Test / benchmark runners (Phase 10) ---
    if (has_flag(args, "--run-tests")) {
        const rc = c.luanti_run_catch2_tests(@intCast(all_args.len), @ptrCast(all_args.ptr));
        std.process.exit(@intCast(@max(0, @min(255, rc))));
    }

    if (has_flag(args, "--run-benchmarks")) {
        const rc = c.luanti_run_catch2_benchmarks(@intCast(all_args.len), @ptrCast(all_args.ptr));
        std.process.exit(@intCast(@max(0, @min(255, rc))));
    }

    // --- Real run paths ---
    // For now we dispatch to the (still-stub) ABI functions.
    // Once the heavy lifting (init_common, game_configure, run_dedicated_server,
    // ClientLauncher, etc.) is properly exposed or moved, these will do real work.

    // Very naive server detection, matching the spirit of the old main().
    const is_server = has_flag(args, "--server") or has_flag(args, "-s");

    // Build a proper null-terminated C argv for the ABI boundary.
    var c_argv = allocator.alloc([*c]u8, all_args.len + 1) catch {
        std.process.exit(1);
    };
    defer allocator.free(c_argv);

    for (all_args, 0..) |arg, i| {
        c_argv[i] = @constCast(@ptrCast(arg.ptr));
    }
    c_argv[all_args.len] = null;

    const rc: c_int = if (is_server)
        c.luanti_run_server(@intCast(all_args.len), c_argv.ptr)
    else
        c.luanti_run_client(@intCast(all_args.len), c_argv.ptr);

    if (rc != 0) {
        std.process.exit(@intCast(@max(0, @min(255, rc))));
    }
}
