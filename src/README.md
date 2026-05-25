# Luanti Core Engine C++ Source Code

This is the main C++ source code directory for the Luanti (formerly Minetest) game engine. It contains the implementation of the voxel database, client/server network protocol, rendering pipelines, game loop, and the Lua API bindings.

---

## How Key Files in the `src/` Directory Work

### `main.cpp`
This is the main application entry point for the compiled executable.
- Parses command line parameters (like `--server`, `--port`, `--config`, `--world`).
- Reads configuration files, boots up platform-specific initialization code (using `porting.cpp`), and decides whether to launch the dedicated console server or set up graphics device layers (SDL2/OpenGL/IrrlichtMt) to run the graphical client and main menu.

### `server.cpp` and `server.h`
Implements the `Server` class, which handles the authoritative simulation of the voxel world.
- Tracks all connected players, validates their movements, and broadcasts world updates.
- Manages the main server ticking loop: steps active entities, updates active block modifiers (ABMs), and serializes/saves blocks to the database.

### `client/` Files (including `client.cpp`, `clientmap.cpp`)
Contains the game client instance (`Client`), handling the local rendering loop, audio playback, local player inputs, and predictions.
- **`clientmap.cpp`**: Implements specialized client-side map code that optimizes rendering map blocks, applying view frustum culling, and fetching mesh nodes.

### `map.cpp` and `map.h`
Implements the core spatial engine representing the voxel world.
- Manages coordinate transformations, load-on-demand block structures, active block ranges, and queries.
- Coordinates the C++ classes `MapSector` (a vertical column of blocks) and `MapBlock` (a 16x16x16 chunk of voxels).

### `mapnode.cpp` and `mapnode.h`
Defines `MapNode`, the fundamental data structure representing a single voxel block in the grid.
- Optimization: Uses a highly compressed, memory-efficient layout storing only a 16-bit block ID (`param0`), light level metadata (`param1`), and rotation/face orientation variables (`param2`).

### `nodedef.cpp` and `nodedef.h`
Manages the `NodeDefinitionManager` which registers block templates.
- Resolves block metadata properties (e.g. is a node walkable, buildable-to, liquid, transparent, what texture maps represent it, and what sounds it triggers on step/dig).

### `craftdef.cpp` and `craftdef.h`
Implements the in-game crafting system:
- Registers craft recipes (normal grid shapes, shapeless recipes, cooking/smelting times, fuel values) and computes outputs when players place ingredients in inventory grids.

### `settings.cpp` and `settings.h`
Implements the global configuration reader/writer (`Settings`).
- Reads `minetest.conf` values, stores settings maps, and provides fallback default parameters.

### `environment.cpp` and `environment.h`
Defines `ServerEnvironment` and `ClientEnvironment`.
- Coordinates active entities (`ActiveObject`), time-of-day changes, weather patterns, and coordinates physics equations on player objects.

---

## How Subdirectories Work

- **`client/`**: Specific rendering, sounds, cameras, HUDs, and client-side predictions.
- **`server/`**: Server-side ticks, command handlers, connection pools, and player authorization.
- **`database/`**: Voxel storage backends (SQLite3, PostgreSQL, LevelDB, Redis) for loading and saving mapblocks.
- **`gui/`**: Engine GUI rendering, standard widgets, and modular Formspec layout handlers.
- **`mapgen/`**: Multithreaded map block terrain calculators, Perlin noise generators, and biome maps.
- **`network/`**: TCP/UDP wrapper networking sockets and serialization protocols.
- **`script/`**: Lua wrappers, sandboxing APIs, and callbacks bridging the C++ engine to Lua scripts.
- **`threading/`**: Standard cross-platform multi-threading abstractions.
- **`unittest/`**: Core unit verification tests written using Catch2.
