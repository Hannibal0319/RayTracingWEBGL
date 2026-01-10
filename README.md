# RayTracingWEBGL

WebGL2 path-traced renderer using a fullscreen quad and fragment-shader ray tracing.

## Features
- Spheres, quads, textured triangle meshes (OBJ)
- BVH traversal on GPU for triangle meshes
- Reflective/refractive materials, emissive lights, checker ground
- Depth of field, blue-noise sampling
- Modular GLSL with `#include` support

## Project Structure
- **Entry**: `index.html`
- **JS**
  - `initShaders2.js` — shader loader with `#include`
  - `setUpWebGL.js` — WebGL2 setup
  - `render.js` — render loop, uniforms, accumulation
  - `main.js` — scene setup, OBJ load, BVH build/upload, blue-noise
  - `scene.js` — scene/material helpers
  - `MV.js` — math utilities
- **Shaders**
  - `shaders/vertex-shader.glsl`
  - `shaders/fragment-shader.glsl` (includes scene, shading, intersections, raytracer, utils, uniforms, structs inside `shaders/fragment/`)

## Controls
- Mouse drag (LMB): orbit yaw/pitch
- Mouse wheel: dolly zoom
- WASD: move in view plane/forward

## Requirements
- WebGL2-capable browser
- Serve over HTTP (needed for AJAX shader/OBJ loading)
- Models in `models/`, shaders in `shaders/`
- Uses CDN `webgl-obj-loader`

## Running
```bash
python -m http.server 8000
```
Open: http://localhost:8000 and load `index.html`.

## Configuration
- Scene data: `SCENE_DATA` in `main.js` (camera, plane, lights, spheres/quads)
- OBJ load & transforms: `loadOBJIntoScene` in `main.js`
- Render scale: `RENDER_SCALE` in `main.js`
- Shader constants (samples, bounces, limits): `shaders/fragment/uniforms.glsl`
- Triangle cap must match `MAX_TRIANGLES` in both JS and GLSL

## Notes
- BVH and triangle textures are built in `rebuildBVH` (main.js) and consumed in fragment traversal.

## License
MIT — see `LICENSE`.