# Luanti Engine Built-in Lua Scripts

This directory contains the built-in Lua scripting API, framework modules, and UI environments loaded automatically by the Luanti engine on startup. These files are essential for defining basic engine-mod interfaces, gameplay handlers, menus, and client/server integrations.

---

## How Each File in this Directory Works

### `init.lua`
This is the master entry point file for the engine's built-in Lua environment. When the engine starts up (both client-side and server-side), it runs this script first.
- **Global Table Initializations**: Sets up standard tables like `core`, `minetest`, `gamedef`, and utility scopes.
- **Loading Sequence**: Runs through the folders under `builtin` (like `common`, `game`, `async`, `fstk`) and sequentially loads their scripts using `dofile()` and `loadfile()`.
- **Mod Sandbox**: Sets up the security bounds for mods, isolating them to prevent raw operating system calls unless explicitly permitted.

### `settingtypes.txt`
This file contains the configuration schema for every setting supported by the engine.
- **Format**: Each setting is defined with its type (integer, float, string, boolean, key, enum, or path), default value, a readable name, and descriptive text.
- **Role in mainmenu**: The Lua-based main menu reads this file dynamically to populate the interactive settings interface (under the Settings tab), allowing users to click toggles, type paths, or use sliders to update their `minetest.conf` directly.

---

## How Subdirectories Work

- **`async/`**: Contains Lua scripts managing background threads and task queues (e.g. `async/dispatcher.lua`), allowing mods to make non-blocking HTTP requests or complex calculations without stalling the main game tick loop.
- **`client/`**: Houses Lua APIs, HUD managers, and event registrations loaded only when the engine runs as a client.
- **`common/`**: Contains core Lua scripts (like math helpers, string manipulations, vector libraries, and serialization) loaded by both client and server environments.
- **`emerge/`**: Contains emerge helpers that coordinate block queue generations and handle callback registration when new areas of voxels are loaded.
- **`fstk/`**: Implements the Formspec Toolkit (FSTK). It acts as an object-oriented layout and callback wrapper over the engine's raw string-based Formspec UI syntax.
- **`game/`**: Implements the standard API for register/callbacks:
  - Registers items, nodes (blocks), craft recipes, ABMs (Active Block Modifiers), and LBMs (Loading Block Modifiers).
  - Handles base gameplay functions, chat logs, falling nodes, entity physics, and default privilege mappings.
- **`locale/`**: Built-in translation tables (`.tr` files) utilized to translate built-in main menus and settings text.
- **`mainmenu/`**: The complete graphical user interface of the main menu (world manager, multiplayer tab, mods loader, game installer) written in Lua.
- **`pause_menu/`**: Implements the standard overlay menu shown when the escape key is pressed during gameplay.
- **`profiler/`**: Standard Lua performance meters tracking memory, function call durations, and CPU spikes in mod routines.
