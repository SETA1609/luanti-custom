//! Engine C++ source lists & shared compile flags.
//!
//! The big lists of .cpp files that make up the Luanti engine. Keep these
//! in sync with the corresponding CMakeLists.txt — if upstream adds a
//! file, mirror it here.

// Mirrors src/CMakeLists.txt:420-456 plus the PARENT_SCOPE source lists from
// src/{util,threading,content,database,network}/CMakeLists.txt. Shared by
// both the client and the server.
pub const common_sources = [_][]const u8{
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
// to default constants.
pub const cxx_flags = [_][]const u8{
    "-std=c++23",
    "-fno-strict-aliasing",
    "-DUSE_CMAKE_CONFIG_H",
};

// Include directories the engine needs at compile time. Headers from the
// vendored zlib/zstd/sqlite3/lua/jsoncpp/gmp/sha256 deps come in via
// `linkLibrary` on the consuming target (Zig propagates the dep's
// installed include paths transitively).
pub const include_paths = [_][]const u8{
    "src",
    "src/script",
    "lib/jsoncpp",
    "lib/gmp",
    "lib/sha256",
    "lib/lua/src",
    "irr/include",
};
