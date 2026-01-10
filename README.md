# WebGL Path Tracing Demo

A modular fragment-shader path tracer rendering spheres, quads, and triangles with basic PBR features (Lambertian, reflective, refractive, metallic/roughness), accumulation, and simple object picking for live material tweaks.

## Getting Started
1) Serve the folder (required for shader loading via XHR). Examples:
- Python 3: `python -m http.server 8000`
- Node: `npx serve .`
2) Open http://localhost:8000 and you’ll see the canvas from [index.html](index.html).

## Controls
- Orbit: Mouse drag
- Zoom: Mouse wheel
- Move: WASD
- Pick sphere: Click on a sphere to reveal the material panel (diffuse, reflectivity, IOR, metallic, roughness). Adjusting sliders calls `resetAccumulation()` to restart denoising.
- Accumulation: Moves or edits reset the progressive buffer.

## Project Structure
- App bootstrap: [main.js](main.js)
- WebGL init: [`setupWebGL`](setUpWebGL.js) and [`initShaders`](initShaders2.js)
- Scene definitions: [scene.js](scene.js) (`Material`, `Sphere`, `Quad`, `Triangle`)
- Rendering loop & UI: [render.js](render.js) (accumulation buffer, controls, picking)
- Math helpers: [MV.js](MV.js)
- Shaders:
  - Vertex: [shaders/vertex-shader.glsl](shaders/vertex-shader.glsl)
  - Fragment entry: [shaders/fragment-shader.glsl](shaders/fragment-shader.glsl)
  - Includes: [shaders/fragment/uniforms.glsl](shaders/fragment/uniforms.glsl), [shaders/fragment/structs.glsl](shaders/fragment/structs.glsl), [shaders/fragment/utils.glsl](shaders/fragment/utils.glsl), [shaders/fragment/intersections.glsl](shaders/fragment/intersections.glsl), [shaders/fragment/scene.glsl](shaders/fragment/scene.glsl), [shaders/fragment/shading.glsl](shaders/fragment/shading.glsl), [shaders/fragment/raytracer.glsl](shaders/fragment/raytracer.glsl)

## Notable Features
- Progressive accumulation with framebuffer copy for temporally smoothed output.
- Depth of field via aperture & focal distance (see `u_aperture`, `u_focalDistance` uniforms).
- PBR-ish BRDF helpers: GGX importance sampling and Fresnel in [`cookTorranceBRDF`](shaders/fragment/utils.glsl) (used for metallic/roughness paths).
- Object picking projected to ray space for sphere selection and live material editing.

## License
MIT — see [LICENSE](LICENSE).