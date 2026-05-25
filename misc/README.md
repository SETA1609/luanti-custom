# Miscellaneous Integration and Packaging Assets

This directory contains utility files, icons, metadata, and scripts required to package and integrate the Luanti engine on various desktop operating systems (Linux, macOS, Windows).

---

## How Each File in this Directory Works

### `AppImageBuilder.yml`
This is a YAML configuration file utilized by the AppImageBuilder utility. It contains instructions, environment specifications, and package lists needed to package Luanti and all its dependent shared libraries into a single, executable, standalone `.AppImage` binary file that runs on almost any modern Linux distribution.

### `CPACK_WIX_UI_BANNER.BMP` and `CPACK_WIX_UI_DIALOG.BMP`
These are BMP format image assets used during the Windows installation generation process using CPack's WiX installer backend.
- `CPACK_WIX_UI_BANNER.BMP` is displayed at the top of subsequent installation setup windows.
- `CPACK_WIX_UI_DIALOG.BMP` is the larger vertical background banner image displayed on the initial welcome screen of the `.msi` setup wizard.

### `luanti.exe.manifest`
A Windows XML manifest file embedded directly into the compiled executable binary. It guides the Windows OS loader on how to run `luanti.exe` by:
- Stating compatibility parameters for modern Windows versions (7/8/10/11).
- Directing the system to load standard common controls DLLs for modernized visual stylings.
- Declaring DPI-awareness configurations to prevent blurry UI rendering on high-resolution displays.

### `winresource.rc`
This is a Windows Resource Compiler script. It defines structural metadata embedded in the compiled `luanti.exe` executable:
- Binds the primary application icon (`luanti-icon.ico`) so it displays in Windows File Explorer.
- Defines file descriptors, copyright info, and version information displayed when users check "Properties -> Details" on the executable file.

### `org.luanti.luanti.desktop`
A standard Linux desktop launcher entry file. It defines menu configurations for application launchers (like GNOME Activities, KDE Application Menu):
- Specifying the application name (`Luanti`).
- Providing commands to run the engine (`Exec=luanti`).
- Associating icons, tags, categories (`Game;ActionGame;`), and MIME types.

### `org.luanti.luanti.metainfo.xml`
An AppStream metainfo specification file. Linux software catalogs (like the software centers in Ubuntu, Fedora, or Flathub) parse this XML file to populate store listings:
- Holds detailed multilingual descriptions and categories.
- References screenshots of the game.
- Specifies development details, release histories, and application licensing.

### `redirect.html` and `make_redirects.sh`
- **`redirect.html`**: A skeletal HTML page containing a JavaScript redirect script.
- **`make_redirects.sh`**: A shell script that generates static HTML redirect pages linking developers or documentation pages directly to local reference logs or specific engine URLs.

### `luanti-icon-*`, `luanti-icon.ico`, `luanti-icon.icns`, `luanti.svg`
Graphical assets in various resolutions and formats containing the official Luanti logo:
- `*.png`: Low/high-resolution pixel assets.
- `luanti-icon.ico`: Standard multi-size icon bundle utilized by Windows executable and installer systems.
- `luanti-icon.icns`: Standard icon bundle format for macOS Finder desktop environments.
- `luanti.svg`: Scalable Vector Graphics format used to generate clean, scale-independent icons for Linux desktops.
- `luanti-xorg-icon-128.png`: Specific PNG dimension mapped by window managers utilizing X11.

---

## How Subdirectories Work

- **`macos/`**: Contains configuration files (such as `.plist` layout XMLs) and entitlement parameters needed to package, sign, and build the native macOS `.app` bundle using Xcode or Makefile build systems.
