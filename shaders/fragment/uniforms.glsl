precision highp float;

// Scene Uniforms
uniform vec2 u_resolution;
uniform float u_planeY;
uniform vec3 u_planeColorA;
uniform vec3 u_planeColorB;

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

// Triangle Data via texture
const int MAX_TRIANGLES = 20000;
uniform int u_triangleCount;
uniform highp sampler2D u_triTex;
uniform vec2 u_triTexSize; // width = triangleCount, height = rows (6)

// Blue-noise texture for RNG
uniform highp sampler2D u_noiseTex;
uniform vec2 u_noiseTexSize;

// BVH Data
uniform int u_bvhNodeCount;
uniform highp sampler2D u_bvhTex0;
uniform highp sampler2D u_bvhTex1;
uniform highp sampler2D u_bvhTex2;
uniform vec2 u_bvhTexSize; // width = nodeCount, height = 1
const int MAX_BVH_NODES = 35536;
uniform vec3 u_meshBoundsMin;
uniform vec3 u_meshBoundsMax;

// Point light (sky)
uniform vec3 u_pointLightPos;
uniform vec3 u_pointLightColor; // includes intensity

// CAMERA UNIFORMS
uniform vec3 u_cameraPos;
uniform vec2 u_cameraRotation; // yaw (x), pitch (y)
uniform mat3 u_cameraRotationMat; // precomputed rotation matrix
uniform vec3 u_cameraRight;
uniform vec3 u_cameraUp;
uniform float u_aperture;
uniform float u_focalDistance;
uniform float u_fov;

// Constants
const vec3 SKY_HORIZON_COLOR = vec3(0.9, 0.95, 1.0);
const vec3 SKY_ZENITH_COLOR = vec3(0.05, 0.2, 0.4);
const float AMBIENT_INTENSITY = 0.1;
const float EPSILON = 0.001;
const int MAX_BOUNCES = 4;
const int SAMPLES_PER_PIXEL = 4;
const float PI = 3.14159265359;

// Material Types (as defined in JS)
const int LAMBERTIAN = 0;
const int REFLECTIVE = 1;
const int REFRACTIVE = 2;
const int EMISSIVE = 3;

// Object IDs
const int PLANE_ID = MAX_SPHERES + MAX_QUADS + MAX_TRIANGLES;
