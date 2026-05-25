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
    "-std=c++17",
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
    "lib/lstrpack",
    "irr/include",
};

// Sources that the luantiserver executable adds on top of `common_sources`
// (the EngineCommon static lib). This is what CMake calls `server_SRCS =
// common_SRCS`, minus the files already in EngineCommon. Source: walking
// src/CMakeLists.txt:462-499 and the PARENT_SCOPE lists in
// src/{server,script,script/common,script/cpp_api,script/lua_api,mapgen,
// network}/CMakeLists.txt.
pub const server_sources = [_][]const u8{
    // common_SRCS direct files — src/CMakeLists.txt:462-494
    // (these are NOT in independent_SRCS / EngineCommon).
    "src/clientdynamicinfo.cpp",
    "src/collision.cpp",
    "src/content_mapnode.cpp",
    "src/defaultsettings.cpp",
    "src/emerge.cpp",
    "src/environment.cpp",
    "src/filesys.cpp",
    "src/gettext.cpp",
    "src/inventorymanager.cpp",
    "src/itemdef.cpp",
    "src/light.cpp",
    "src/main.cpp",
    "src/map_settings_manager.cpp",
    "src/map.cpp",
    "src/mapblock.cpp",
    "src/mapnode.cpp",
    "src/mapsector.cpp",
    "src/nodedef.cpp",
    "src/pathfinder.cpp",
    "src/player.cpp",
    "src/porting.cpp",
    "src/raycast.cpp",
    "src/reflowscan.cpp",
    "src/remoteplayer.cpp",
    "src/rollback_interface.cpp",
    "src/server.cpp",
    "src/serverenvironment.cpp",
    "src/servermap.cpp",
    "src/translation.cpp",
    "src/version.cpp",
    "src/voxel.cpp",
    "src/voxelalgorithms.cpp",

    // mapgen_SRCS — src/mapgen/CMakeLists.txt:5-20
    "src/mapgen/cavegen.cpp",
    "src/mapgen/dungeongen.cpp",
    "src/mapgen/mapgen_carpathian.cpp",
    "src/mapgen/mapgen.cpp",
    "src/mapgen/mapgen_flat.cpp",
    "src/mapgen/mapgen_fractal.cpp",
    "src/mapgen/mapgen_singlenode.cpp",
    "src/mapgen/mapgen_v5.cpp",
    "src/mapgen/mapgen_v6.cpp",
    "src/mapgen/mapgen_v7.cpp",
    "src/mapgen/mapgen_valleys.cpp",
    "src/mapgen/mg_biome.cpp",
    "src/mapgen/mg_decoration.cpp",
    "src/mapgen/mg_ore.cpp",
    "src/mapgen/mg_schematic.cpp",
    "src/mapgen/treegen.cpp",

    // common_SCRIPT_SRCS top-level — src/script/CMakeLists.txt:9-17
    "src/script/scripting_server.cpp",
    "src/script/scripting_emerge.cpp",

    // common_SCRIPT_COMMON_SRCS — src/script/common/CMakeLists.txt:5-9
    "src/script/common/c_content.cpp",
    "src/script/common/c_converter.cpp",
    "src/script/common/c_internal.cpp",
    "src/script/common/c_packer.cpp",
    "src/script/common/helper.cpp",

    // common_SCRIPT_CPP_API_SRCS — src/script/cpp_api/CMakeLists.txt:5-17
    "src/script/cpp_api/s_async.cpp",
    "src/script/cpp_api/s_base.cpp",
    "src/script/cpp_api/s_entity.cpp",
    "src/script/cpp_api/s_env.cpp",
    "src/script/cpp_api/s_inventory.cpp",
    "src/script/cpp_api/s_item.cpp",
    "src/script/cpp_api/s_mapgen.cpp",
    "src/script/cpp_api/s_modchannels.cpp",
    "src/script/cpp_api/s_node.cpp",
    "src/script/cpp_api/s_nodemeta.cpp",
    "src/script/cpp_api/s_player.cpp",
    "src/script/cpp_api/s_security.cpp",
    "src/script/cpp_api/s_server.cpp",

    // common_SCRIPT_LUA_API_SRCS — src/script/lua_api/CMakeLists.txt:5-30
    "src/script/lua_api/l_areastore.cpp",
    "src/script/lua_api/l_async.cpp",
    "src/script/lua_api/l_auth.cpp",
    "src/script/lua_api/l_base.cpp",
    "src/script/lua_api/l_craft.cpp",
    "src/script/lua_api/l_env.cpp",
    "src/script/lua_api/l_http.cpp",
    "src/script/lua_api/l_inventory.cpp",
    "src/script/lua_api/l_ipc.cpp",
    "src/script/lua_api/l_item.cpp",
    "src/script/lua_api/l_itemstackmeta.cpp",
    "src/script/lua_api/l_mapgen.cpp",
    "src/script/lua_api/l_metadata.cpp",
    "src/script/lua_api/l_modchannels.cpp",
    "src/script/lua_api/l_nodemeta.cpp",
    "src/script/lua_api/l_nodetimer.cpp",
    "src/script/lua_api/l_noise.cpp",
    "src/script/lua_api/l_object.cpp",
    "src/script/lua_api/l_particles.cpp",
    "src/script/lua_api/l_playermeta.cpp",
    "src/script/lua_api/l_rollback.cpp",
    "src/script/lua_api/l_server.cpp",
    "src/script/lua_api/l_settings.cpp",
    "src/script/lua_api/l_storage.cpp",
    "src/script/lua_api/l_util.cpp",
    "src/script/lua_api/l_vmanip.cpp",

    // common_server_SRCS — src/server/CMakeLists.txt:3-15
    "src/server/activeobjectmgr.cpp",
    "src/server/ban.cpp",
    "src/server/blockmodifier.cpp",
    "src/server/clientiface.cpp",
    "src/server/luaentity_sao.cpp",
    "src/server/mods.cpp",
    "src/server/player_sao.cpp",
    "src/server/rollback.cpp",
    "src/server/serveractiveobject.cpp",
    "src/server/serverinventorymgr.cpp",
    "src/server/serverlist.cpp",
    "src/server/unit_sao.cpp",

    // server_network_SRCS — src/network/CMakeLists.txt:15-18
    "src/network/serveropcodes.cpp",
    "src/network/serverpackethandler.cpp",
};
