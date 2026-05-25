# Localization and Gettext Translations

This directory manages localization and multi-language translations for the Luanti game engine. It uses the standard GNU Gettext framework.

---

## How Each File in this Directory Works

### `luanti.pot`
This is the master **Portable Object Template (POT)** file.
- **How it is generated**: Generated automatically by running translation scripts (e.g. `util/updatepo.sh`) which scan the C++ codebase (`src/`) and the builtin Lua files (`builtin/`) looking for translation marking functions like `wgettext(...)` or `fgettext(...)`.
- **How it works**: It serves as a unified dictionary template. It lists every unique, translatable English text string along with references to the source code files and line numbers where they occur. This file is not translated directly; it is copied to create individual language `.po` files.

---

## How Subdirectories Work

- **`<locale_code>/` Directories** (e.g. `de/`, `fr/`, `es_US/`, `ja/`):
  Each of these folders represents a supported language or regional dialect. Inside each folder, you will find:
  - **`luanti.po` (Portable Object)**: The actual translation dictionary file for that specific language. Translators edit this file, matching the English strings defined in the master `luanti.pot` template with their local translations.
  - **`luanti.mo` (Machine Object)**: During the engine compilation process, the build system compiles the human-readable `.po` files into binary `.mo` files using the `msgfmt` tool. The compiled engine reads these binary `.mo` files at runtime to load translations instantly without performance overhead.
