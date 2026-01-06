precision highp float;

// Scene Uniforms
uniform vec2 u_resolution;
uniform float u_planeY;
uniform vec3 u_planeColorA;
uniform vec3 u_planeColorB;
// Time Uniform
uniform float u_time;

// Accumulation Uniforms
uniform sampler2D u_accumTexture;
uniform int u_frameCount;

// Sphere Data Uniforms
const int MAX_SPHERES = 10;
uniform int u_sphereCount;
uniform vec3 u_sphereCenters[MAX_SPHERES];
uniform float u_sphereRadii[MAX_SPHERES];
uniform vec3 u_sphereAABB_min[MAX_SPHERES];
uniform vec3 u_sphereAABB_max[MAX_SPHERES];

// Material Uniforms for Spheres
uniform vec3 u_sphereDiffuseColors[MAX_SPHERES];
uniform float u_sphereReflectivity[MAX_SPHERES];
uniform float u_sphereIOR[MAX_SPHERES];
uniform int u_sphereMaterialTypes[MAX_SPHERES]; // 0: Lambertian, 1: Reflective, 2: Refractive
uniform vec3 u_sphereEmissionColors[MAX_SPHERES];
uniform float u_sphereMetallic[MAX_SPHERES];
uniform float u_sphereRoughness[MAX_SPHERES];

// Quad Data Uniforms
const int MAX_QUADS = 10; // Set a max limit for quads
uniform int u_quadCount;
uniform vec3 u_quadCorners[MAX_QUADS];
uniform vec3 u_quadU[MAX_QUADS];
uniform vec3 u_quadV[MAX_QUADS];
uniform vec3 u_quadNormals[MAX_QUADS];
uniform vec3 u_quadAABB_min[MAX_QUADS];
uniform vec3 u_quadAABB_max[MAX_QUADS];

// Material Uniforms for Quads
uniform vec3 u_quadDiffuseColors[MAX_QUADS];
uniform float u_quadReflectivity[MAX_QUADS];
uniform float u_quadIOR[MAX_QUADS];
uniform int u_quadMaterialTypes[MAX_QUADS];
uniform vec3 u_quadEmissionColors[MAX_QUADS];
uniform float u_quadMetallic[MAX_QUADS];
uniform float u_quadRoughness[MAX_QUADS];

// Triangle Data Uniforms
const int MAX_TRIANGLES = 20;
uniform int u_triangleCount;
uniform vec3 u_triangleV0[MAX_TRIANGLES];
uniform vec3 u_triangleE1[MAX_TRIANGLES];
uniform vec3 u_triangleE2[MAX_TRIANGLES];
uniform vec3 u_triangleNormals[MAX_TRIANGLES];
uniform vec3 u_triangleAABB_min[MAX_TRIANGLES];
uniform vec3 u_triangleAABB_max[MAX_TRIANGLES];

// Material Uniforms for Triangles
uniform vec3 u_triangleDiffuseColors[MAX_TRIANGLES];
uniform float u_triangleReflectivity[MAX_TRIANGLES];
uniform float u_triangleIOR[MAX_TRIANGLES];
uniform int u_triangleMaterialTypes[MAX_TRIANGLES];
uniform vec3 u_triangleEmissionColors[MAX_TRIANGLES];
uniform float u_triangleMetallic[MAX_TRIANGLES];
uniform float u_triangleRoughness[MAX_TRIANGLES];

// CAMERA UNIFORMS
uniform vec3 u_cameraPos;
uniform vec2 u_cameraRotation;
uniform float u_aperture;
uniform float u_focalDistance;

// Constants
const vec3 SKY_HORIZON_COLOR = vec3(0.9, 0.95, 1.0);
const vec3 SKY_ZENITH_COLOR = vec3(0.05, 0.2, 0.4);
const float AMBIENT_INTENSITY = 0.05;
const float EPSILON = 0.001;
const int MAX_BOUNCES = 20;
const int SAMPLES_PER_PIXEL = 1;
const float PI = 3.14159265359;

// Material Types (as defined in JS)
const int LAMBERTIAN = 0;
const int REFLECTIVE = 1;
const int REFRACTIVE = 2;
const int EMISSIVE = 3;
const int METALLIC_ROUGHNESS = 4;

// Object IDs
const int PLANE_ID = MAX_SPHERES + MAX_QUADS + MAX_TRIANGLES;
