# Client-side Assets and Shaders

This directory holds configuration definitions and asset packages specifically utilized by the Luanti game client.

---

## How Each Directory Works

### `serverlist/`
This folder contains static and dynamic configuration files detailing how the game client discovers, connects to, and queries multiplayer servers.
- **`favoriteservers.txt`**: (Or equivalent JSON/text configurations) Saves the IP addresses, domain names, ports, and names of servers that the player has designated as "favorites" so they can easily reconnect.
- **Server Registry Links**: Houses lists of online master-server list URLs that the client fetches in the main menu's "Join Game" tab to display active servers, player counts, ping times, and descriptions globally.

### `shaders/`
This directory contains the GLSL (OpenGL Shading Language) and CG/HLSL shader source codes loaded by the client's 3D renderer backend.
- **`opengl/` or root shaders**:
  - **`*.vert` (Vertex Shaders)**: Execute calculations on individual vertices (corners) of 3D voxel nodes and models. They translate 3D vertex positions to 2D screen coordinates and pass texture coordinates, normals, and light information down the pipeline.
  - **`*.frag` (Fragment Shaders)**: Calculate the pixel color outputs. They compute dynamic shadowing, bump maps (normal mapping), water animations (waves, reflection, refraction), foliage swaying, volumetric fog, day-night light transitions, bloom, and tone mapping post-processing.
- These files are read and compiled on startup or runtime by the graphics card, using parameters defined in settings (like enabling "Shaders", "Tone Mapping", "Bump Mapping").
