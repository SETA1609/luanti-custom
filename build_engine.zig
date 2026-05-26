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

// IrrlichtMt sources. Mirrors irr/src/CMakeLists.txt — the union of the
// five OBJECT libraries (IRRMESHOBJ, IRRVIDEOOBJ, IRRIOOBJ, IRROTHEROBJ,
// IRRGUIOBJ) plus the scene-node sources added to the final IrrlichtMt
// STATIC target. Linux defaults: ENABLE_OPENGL=true, ENABLE_OPENGL3=true,
// USE_SDL2=true, ENABLE_GLES2=false. Other targets (Android, Emscripten)
// will need branched lists — added when their phases come up.
pub const irr_sources = [_][]const u8{
    // IRRMESHOBJ + IRRMESHLOADER — irr/src/CMakeLists.txt:257-278
    "irr/src/WeightBuffer.cpp",
    "irr/src/SkinnedMesh.cpp",
    "irr/src/CMeshSceneNode.cpp",
    "irr/src/AnimatedMeshSceneNode.cpp",
    "irr/src/CB3DMeshFileLoader.cpp",
    "irr/src/CGLTFMeshFileLoader.cpp",
    "irr/src/COBJMeshFileLoader.cpp",
    "irr/src/CXMeshFileLoader.cpp",

    // IRRDRVROBJ base — irr/src/CMakeLists.txt:282-292
    "irr/src/CNullDriver.cpp",
    "irr/src/CEGLManager.cpp",
    "irr/src/CSDLManager.cpp",
    "irr/src/mt_opengl_loader.cpp",
    "irr/src/HWBuffer.cpp",

    // IRRDRVROBJ legacy OpenGL — irr/src/CMakeLists.txt:296-309 (ENABLE_OPENGL)
    "irr/src/COpenGLCacheHandler.cpp",
    "irr/src/COpenGLDriver.cpp",
    "irr/src/COpenGLSLMaterialRenderer.cpp",
    "irr/src/COpenGLExtensionHandler.cpp",

    // IRRDRVROBJ unified OpenGL/GLES2 backend — irr/src/CMakeLists.txt:313-326
    "irr/src/OpenGL/Driver.cpp",
    "irr/src/OpenGL/ExtensionHandler.cpp",
    "irr/src/OpenGL/FixedPipelineRenderer.cpp",
    "irr/src/OpenGL/MaterialRenderer.cpp",
    "irr/src/OpenGL/Renderer2D.cpp",
    "irr/src/OpenGL/BufferObject.cpp",

    // IRRDRVROBJ OpenGL3+ — irr/src/CMakeLists.txt:328-334 (ENABLE_OPENGL3)
    "irr/src/OpenGL3/DriverGL3.cpp",

    // IRRIMAGEOBJ — irr/src/CMakeLists.txt:344-360
    "irr/src/CColorConverter.cpp",
    "irr/src/CImage.cpp",
    "irr/src/CImageLoaderJPG.cpp",
    "irr/src/CImageLoaderPNG.cpp",
    "irr/src/CImageLoaderTGA.cpp",
    "irr/src/CImageWriterJPG.cpp",
    "irr/src/CImageWriterPNG.cpp",

    // IRRIOOBJ — irr/src/CMakeLists.txt:367-383
    "irr/src/CFileList.cpp",
    "irr/src/CFileSystem.cpp",
    "irr/src/CLimitReadFile.cpp",
    "irr/src/CMemoryFile.cpp",
    "irr/src/CReadFile.cpp",
    "irr/src/CWriteFile.cpp",
    "irr/src/CZipReader.cpp",

    // IRROTHEROBJ — irr/src/CMakeLists.txt:385-398
    "irr/src/CIrrDeviceSDL.cpp",
    "irr/src/CIrrDeviceStub.cpp",
    "irr/src/CLogger.cpp",
    "irr/src/COSOperator.cpp",
    "irr/src/Irrlicht.cpp",
    "irr/src/os.cpp",

    // IRRGUIOBJ — irr/src/CMakeLists.txt:415-445
    "irr/src/CGUIButton.cpp",
    "irr/src/CGUICheckBox.cpp",
    "irr/src/CGUIComboBox.cpp",
    "irr/src/CGUIEditBox.cpp",
    "irr/src/CGUIEnvironment.cpp",
    "irr/src/CGUIFileOpenDialog.cpp",
    "irr/src/CGUIFont.cpp",
    "irr/src/CGUIImage.cpp",
    "irr/src/CGUIListBox.cpp",
    "irr/src/CGUIScrollBar.cpp",
    "irr/src/CGUISkin.cpp",
    "irr/src/CGUIStaticText.cpp",
    "irr/src/CGUITabControl.cpp",
    "irr/src/CGUISpriteBank.cpp",
    "irr/src/CGUIImageList.cpp",

    // IrrlichtMt main scene nodes — irr/src/CMakeLists.txt:452-471
    "irr/src/CBillboardSceneNode.cpp",
    "irr/src/CCameraSceneNode.cpp",
    "irr/src/CDummyTransformationSceneNode.cpp",
    "irr/src/CEmptySceneNode.cpp",
    "irr/src/CMeshManipulator.cpp",
    "irr/src/CSceneCollisionManager.cpp",
    "irr/src/CSceneManager.cpp",
    "irr/src/CMeshCache.cpp",
};

// IrrlichtMt compile flags for a Linux SDL2 + OpenGL + OpenGL3 build.
// Mirrors the add_compile_definitions calls in irr/src/CMakeLists.txt:66-92,
// 125-136. Uses -std=gnu++17 (not c++17) because IrrlichtMt's
// CFileSystem.cpp errors out on __STRICT_ANSI__ — that's the same
// behaviour CMake's defaults give us via implicit -std=gnu++17.
// Platform-specific bits (_IRR_WINDOWS_, _IRR_OSX_PLATFORM_, ...) will
// be branched on target.os.tag when their phases land.
pub const irr_cxx_flags_linux = [_][]const u8{
    "-std=gnu++17",
    "-fno-strict-aliasing",
    "-D_IRR_POSIX_API_",
    "-D_IRR_COMPILE_WITH_SDL_DEVICE_",
    "-D_IRR_COMPILE_WITH_JOYSTICK_EVENTS_",
    "-D_IRR_COMPILE_WITH_OPENGL_",
    "-DENABLE_OPENGL3",
};

// IrrlichtMt include paths. The `irr/include` PUBLIC dir is what
// downstream client code (Phase 9) `#include`s from. `irr/src` is
// private (internal headers).
pub const irr_include_paths = [_][]const u8{
    "irr/include",
    "irr/src",
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
