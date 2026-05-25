# Developer Utilities and Helper Scripts

This directory contains utility scripts, continuous integration configurations, automation routines, and benchmarking tools used by Luanti engine developers.

---

## How Each File in this Directory Works

### `bump_version.sh`
A bash script that automates incrementing the engine version.
- **How it works**: It takes arguments (like major, minor, or patch release types) and parses the codebase, updating the version number in `CMakeLists.txt`, `AndroidManifest.xml`, package configurations, and developer manuals automatically, then generating standard commit messages.

### `updatepo.sh`
A shell script that maintains localization files.
- **How it works**: It scans `src/` and `builtin/` looking for localized text tags, runs translation compiler utilities (`xgettext`), updates the master `po/luanti.pot` template file, and runs `msgmerge` to seamlessly integrate new strings into existing language `.po` files.

### `gather_git_credits.py`
A Python script that generates contributor reports.
- **How it works**: Scans the Git commit logs, filters emails, standardizes name spellings, ranks contributions based on commit counts, and updates the credits list displayed in the engine's main menu/documentation.

### `reorder_translation_commits.py`
A Python developer utility.
- **How it works**: Cleans up and reorders translation merge commits in the git history before releasing updates, ensuring the codebase history remains clean.

### `stress_mapgen.sh`
A shell benchmarking script.
- **How it works**: Launches headless local server instances with aggressive map generation limits, measuring CPU time, memory footprint, and thread locking on different biome configurations.

### `test_multiplayer.sh` and `test_error_cases.sh`
Integration shell scripts that launch local testing instances.
- **`test_multiplayer.sh`**: Boots up a local headless server and connects simulated clients to test protocol integrity under network loads.
- **`test_error_cases.sh`**: Deliberately executes malformed Lua codes or bad packets to verify that the sandbox security and exception handling catch errors properly.

---

## How Subdirectories Work

- **`buildbot/`**: Builds and signs binaries for target platforms automatically upon commit pushes.
- **`ci/`**: Integrates with continuous delivery servers, containing runner environment setup scripts and validation hooks.
- **`helper_mod/`**: Developer benchmark Lua files verifying engine math APIs.
- **`wireshark/`**: Custom Lua script package dissector plugins for Wireshark, enabling real-time sniffing and debugging of Luanti binary packet streams.
- **`xcode/`**: Apple macOS Xcode build schemas and configuration settings.
