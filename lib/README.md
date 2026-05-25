# Bundled Third-party C++ and Lua Libraries

This directory contains copies of external third-party libraries bundled directly with the Luanti repository. These are built statically alongside the main engine source code to simplify compilation and ensure consistent versioning across target platforms.

---

## How Each Directory Works

### `bitop/`
This folder contains the **Lua BitOp** C source code library.
- **`bit.c`**: Implements bitwise operations (AND, OR, XOR, shifts) on 32-bit integers.
- **Why it is necessary**: Standard Lua 5.1 lacks native bitwise operators (which were only added in Lua 5.2/5.3). This library exposes a global `bit` table, enabling mods to perform complex binary operations (like processing packet structures, network protocols, or hashing) in standard Lua 5.1 environments.

### `catch2/`
Contains the **Catch2** header-only C++ unit testing framework.
- **`catch.hpp`**: Single-header configuration containing the entire testing engine.
- **How it works**: Used to write and run unit tests on the engine's core C++ math libraries, string utility functions, serialization pipelines, and mapgen noise algorithms. Test files in the `src/unittest` directory reference this header.

### `gmp/`
Contains the **GNU Multiple Precision Arithmetic Library** wrappers and headers.
- **`gmp.h`**, source files: GMP handles arbitrary-precision arithmetic, allowing calculation on integers and floats of unlimited size.
- **How it works**: Luanti uses GMP to perform complex modular exponentiations required for secure **Secure Remote Password (SRP)** authentication. When clients log in, GMP hashes passwords and exchanges authentication tokens securely without transmitting raw passwords over the network.

### `jsoncpp/`
Holds the **JsonCpp** C++ JSON serializer/deserializer.
- **`jsoncpp.cpp`**, **`json/json.h`**: Allows the C++ engine to read, parse, and write JSON formatting.
- **How it works**: Used for parsing serverlist responses, processing HTTP web requests, importing/exporting game configuration packages, and validating structured metadata.

### `lua/`
Houses the official **Lua 5.1.5** C interpreter codebase.
- Includes `lapi.c`, `lcode.c`, `ldo.c`, `lvm.c`, etc.
- **How it works**: If standard system libraries (like LuaJIT or system-installed Lua 5.1) are not detected or selected, CMake compiles this folder directly into the engine, establishing the scripting environment that executes the game's builtin Lua and external mods.

### `sha256/`
Contains a lightweight, standalone C implementation of the **SHA-256** cryptographic hash.
- **`sha256.c`**, **`sha256.h`**: Computes standard 256-bit hashes.
- **How it works**: Used by the engine for local database integrity checks, computing secure hash-keys for cached assets, and validating texture file identity.

### `tiniergltf/`
A modified, minimal version of **TinyGLTF** used to load glTF 2.0 3D assets.
- **`tiny_gltf.h`**: Loads 3D meshes, textures, node hierarchies, and skeletal animation parameters.
- **How it works**: Enables Luanti to load modern `.gltf`/`.glb` 3D model formats for player models, hand nodes, and complex entities, parsing their structural JSON files and loading vertex data into IrrlichtMT buffers.
