# CMake Helper Modules

This directory contains utility modules, compiler configuration scripts, and find-package macros for the CMake build system.

---

## How Each File in this Directory Works

### `Modules/`
This subdirectory holds standard and custom CMake modules named `Find<Dependency>.cmake`. They are executed by CMake's `find_package()` directives when generating the project's build systems.

- **`FindIrrlicht.cmake`**:
  Queries standard system paths (under Linux `/usr/include`, `/usr/lib`, or Windows environmental directories) to locate the Irrlicht engine headers and library files (`libIrrlicht.a` or `Irrlicht.lib`). It sets variables like `IRRLICHT_FOUND` and libraries paths to expose them to the C++ compiler.
- **`FindGMP.cmake`**:
  Searches for the GNU Multiple Precision Arithmetic Library headers (`gmp.h`) and libraries. GMP is used by Luanti for secure cryptographic SRP calculations.
- **`FindJsonCpp.cmake`**:
  Checks the system for a pre-installed `jsoncpp` library, configuring compilation to use it instead of our bundled `lib/jsoncpp` module if the system library is preferred.
- **`FindSQLite3.cmake`**:
  Searches for SQLite3 database headers and binary libraries, which are required to read and write saved voxel worlds.
- **`FindOpenAL.cmake`**:
  Locates the OpenAL headers and library files, enabling 3D positional audio support in the engine.
- **`FindVorbis.cmake`**:
  Locates the Vorbis / Ogg audio compression libraries needed to decode in-game sound effect assets.
- **`FindZlib.cmake`**:
  Finds Zlib compression helper libraries, crucial for compressing voxel mapblocks when saving worlds or transmitting blocks over the network.
