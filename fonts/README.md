# Engine TrueType Fonts

This directory contains the TrueType Font (`.ttf`) files bundled with the Luanti engine. These fonts are used to render text, menus, chat consoles, and HUD metrics inside the application.

---

## How Each File in this Directory Works

### `Arimo-Regular.ttf`
This is the default sans-serif font used for primary UI elements (buttons, labels, drop-downs) and main menu text under normal display resolutions. It is chosen for its excellent readability and neutral appearance across various operating systems.

### `Arimo-Bold.ttf`
A bolder variation of the Arimo font. The engine selects this file when rendering emphasized headings, button hover states, window titles, or high-priority warning dialogues.

### `Arimo-Italic.ttf` and `Arimo-BoldItalic.ttf`
Italicized and bold-italicized variations of the Arimo font. Used primarily when rendering detailed book contents, special mod descriptions, or developer tooltips that require italic stylings.

### `Arimo-LICENSE.txt`
A text file containing the licensing terms for the Arimo font family. Arimo is licensed under the **Apache License, Version 2.0**, which permits copying, distributing, and modifying the font freely.

---

### `Cousine-Regular.ttf`
This is a fixed-width (monospaced) font. The engine uses it inside text environments that require precise vertical alignment—specifically the in-game developer chat console (`F10`) and code inputs.

### `Cousine-Bold.ttf`, `Cousine-Italic.ttf`, `Cousine-BoldItalic.ttf`
Bold, italic, and bold-italic variations of Cousine. They style text segments in the console, profiler listings, or debugging reports.

### `Cousine-LICENSE.txt`
Contains the licensing terms for Cousine. Like Arimo, Cousine is licensed under the open-source **Apache License, Version 2.0**.

---

### `DroidSansFallbackFull.ttf`
A massive, comprehensive TrueType font file containing extensive unicode character glyph mappings.
- **Why it is necessary**: The default Arimo font does not contain glyphs for East Asian languages (Chinese, Japanese, Korean - CJK) or complex script languages.
- **How it works**: If the player sets their game language to a CJK locale, or if a mod or player tries to type characters not supported by Arimo, the engine's font manager falls back to this file to fetch the correct glyphs, preventing characters from rendering as generic blocks or question marks.

### `DroidSansFallbackFull-LICENSE.txt`
Documents the licensing terms for the Droid Sans Fallback font. It is licensed under the open-source **Apache License, Version 2.0**.
