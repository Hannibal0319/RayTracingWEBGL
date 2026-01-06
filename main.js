// Global WebGL state variables
var gl;
var canvas;
var positionsBuffer;
var program;
var triangleTexture;
var triangleTexSize = [0, 0]; // [width, height]
var triangleCount = 0;
var bvhTex0, bvhTex1, bvhTex2;
var bvhTexSize = [0, 1]; // width = node count, height = 1
var bvhNodeCount = 0;
var noiseTexture;
var noiseTexSize = [64, 64];
var TEX_FORMATS = null; // chosen once after GL init
var meshBoundsMin = [0, 0, 0];
var meshBoundsMax = [0, 0, 0];

const RENDER_SCALE = 1.0; // render at native canvas resolution

// Shader-side triangle cap (must match MAX_TRIANGLES in fragment/uniforms.glsl)
const MAX_TRIANGLES = 18000; // keep in sync with fragment/uniforms.glsl

const M_GLASS = new Material([0.95, 0.95, 0.95], 0.9, 1.5, REFRACTIVE);
const M_LOW_REFRACT = new Material([0.9, 0.9, 0.9], 0.9, 1.5, REFRACTIVE);
const M_GOLD = new Material([1.0, 0.71, 0.29], 0.7, 0.47, REFLECTIVE);
const M_SILVER = new Material([0.6, 0.6, 0.6], 0.7, 0.14, REFLECTIVE);
const M_WATER = new Material([0.8, 0.9, 1.0], 0.7, 1.33, REFRACTIVE);
const M_WOOD = new Material([0.4, 0.2, 0.1], 0.1, 1.0, LAMBERTIAN);
const M_LIGHT_SOFT = new Material([1.0, 0.95, 0.9], 0.0, 1.0, EMISSIVE, [8.0, 7.5, 6.5]);

// Scene Data
const SCENE_DATA = {
    spheres: [
        //new Sphere([-2.0, -0.2, -5.0], 0.8, new Material([0.1, 0.3, 0.2], 0.9, 1.5, REFRACTIVE)),
        
        new Sphere([-7.0, 0.0, -8.0], 1.0, M_GOLD),
        
        //new Sphere([3.0, -0.4, -7.0], 0.6, new Material([0.8, 0.1, 0.1], 0.0, 1.0, LAMBERTIAN)),

        //new Sphere([0.0, 0.0, -7.0], 0.7, M_SILVER),

        // New emissive sphere light (soft, warm glow)
        new Sphere([-1.0, 1.8, -4.5], 0.4, M_GOLD),
    ],

    quads: [
        new Quad([1.5, -0.5, -4.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0], M_GOLD),
        //new Quad([3.5, -0.5, -4.0], [0.0, 0.0, 1.0],[0.0, 1.0, 0.0], M_LIGHT_SOFT),

    ],

    triangles: [], // Filled via OBJ loading
    
    planeY: -1.0, 
    planeColorA: [0.3, 0.3, 0.3], 
    planeColorB: [0.5, 0.5, 0.5], 
    
    // Camera Controls
    cameraPos: [0.0, 0.0, 0.0],
    cameraRotation: [0.0, 0.0],
    fov: 60.0,
    aperture: 0.000,
    focalDistance: 5.0,

    // Sky/point light used by the shader (position in world space, color includes intensity)
    pointLight: {
        pos: [3.0, 6.0, -3.0],
        color: [4.0, 4.0, 4.0]
    }
};

// --- OBJ Loading Helpers ---

async function loadOBJ(url) {
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`Failed to load OBJ at ${url}: ${response.status} ${response.statusText}`);
    }
    const text = await response.text();
    if (!window.OBJ || !OBJ.Mesh) {
        throw new Error('webgl-obj-loader (OBJ.Mesh) is not available on window.OBJ');
    }
    return new OBJ.Mesh(text);
}

function meshToTriangles(mesh, material, options = {}) {
    const targetSize = Number(options.targetSize ?? options.targetsize ?? 1.0);
    const translateInput = options.translate ?? options.translation ?? [0.0, 0.0, -3.0];
    const translate = Array.isArray(translateInput) && translateInput.length === 3
        ? translateInput.map(Number)
        : [0.0, 0.0, -3.0];
    // Normalize and place the mesh so it sits in front of the camera.
    let minB = [Infinity, Infinity, Infinity];
    let maxB = [-Infinity, -Infinity, -Infinity];
    const verts = mesh.vertices;
    for (let i = 0; i + 2 < verts.length; i += 3) {
        const x = verts[i], y = verts[i + 1], z = verts[i + 2];
        if (x < minB[0]) minB[0] = x; if (x > maxB[0]) maxB[0] = x;
        if (y < minB[1]) minB[1] = y; if (y > maxB[1]) maxB[1] = y;
        if (z < minB[2]) minB[2] = z; if (z > maxB[2]) maxB[2] = z;
    }
    const center = [
        0.5 * (minB[0] + maxB[0]),
        0.5 * (minB[1] + maxB[1]),
        0.5 * (minB[2] + maxB[2])
    ];
    const extent = [maxB[0] - minB[0], maxB[1] - minB[1], maxB[2] - minB[2]];
    const maxExtent = Math.max(extent[0], extent[1], extent[2], 1e-6);
    const scale = targetSize / maxExtent;

    const transform = (v) => [
        (v[0] - center[0]) * scale + translate[0],
        (v[1] - center[1]) * scale + translate[1],
        (v[2] - center[2]) * scale + translate[2]
    ];
    const triangles = [];
    const indices = mesh.indices;

    for (let i = 0; i + 2 < indices.length && triangles.length < MAX_TRIANGLES; i += 3) {
        const ia = indices[i] * 3;
        const ib = indices[i + 1] * 3;
        const ic = indices[i + 2] * 3;

        const v0 = transform([verts[ia], verts[ia + 1], verts[ia + 2]]);
        const v1 = transform([verts[ib], verts[ib + 1], verts[ib + 2]]);
        const v2 = transform([verts[ic], verts[ic + 1], verts[ic + 2]]);

        const e1 = subtract(v1, v0);
        const e2 = subtract(v2, v0);

        const tri = new Triangle(v0, e1, e2, material);
        triangles.push(tri);
    }

    if (indices.length / 3 > triangles.length) {
        console.warn(`Clamped OBJ triangles to shader limit (${MAX_TRIANGLES}).`);
    }

    return triangles;
}

// --- BVH Construction & Upload ---

function unionBounds(minA, maxA, minB, maxB) {
    return {
        min: [
            Math.min(minA[0], minB[0]),
            Math.min(minA[1], minB[1]),
            Math.min(minA[2], minB[2])
        ],
        max: [
            Math.max(maxA[0], maxB[0]),
            Math.max(maxA[1], maxB[1]),
            Math.max(maxA[2], maxB[2])
        ]
    };
}

function buildBVH(triangles, leafSize = 16) {
    const count = Math.min(triangles.length, MAX_TRIANGLES);
    const indices = Array.from({ length: count }, (_, i) => i);
    const nodes = [];

    function computeBounds(start, end) {
        let minB = [Infinity, Infinity, Infinity];
        let maxB = [-Infinity, -Infinity, -Infinity];
        for (let i = start; i < end; i++) {
            const tri = triangles[indices[i]];
            const tmin = tri.aabb_min;
            const tmax = tri.aabb_max;
            minB[0] = Math.min(minB[0], tmin[0]);
            minB[1] = Math.min(minB[1], tmin[1]);
            minB[2] = Math.min(minB[2], tmin[2]);
            maxB[0] = Math.max(maxB[0], tmax[0]);
            maxB[1] = Math.max(maxB[1], tmax[1]);
            maxB[2] = Math.max(maxB[2], tmax[2]);
        }
        return { min: minB, max: maxB };
    }

    function computeCentroidBounds(start, end) {
        let minC = [Infinity, Infinity, Infinity];
        let maxC = [-Infinity, -Infinity, -Infinity];
        for (let i = start; i < end; i++) {
            const tri = triangles[indices[i]];
            const tmin = tri.aabb_min;
            const tmax = tri.aabb_max;
            const c = [
                0.5 * (tmin[0] + tmax[0]),
                0.5 * (tmin[1] + tmax[1]),
                0.5 * (tmin[2] + tmax[2])
            ];
            minC[0] = Math.min(minC[0], c[0]);
            minC[1] = Math.min(minC[1], c[1]);
            minC[2] = Math.min(minC[2], c[2]);
            maxC[0] = Math.max(maxC[0], c[0]);
            maxC[1] = Math.max(maxC[1], c[1]);
            maxC[2] = Math.max(maxC[2], c[2]);
        }
        return { min: minC, max: maxC };
    }

    function recurse(start, end) {
        const bounds = computeBounds(start, end);
        const triCount = end - start;

        if (triCount <= leafSize) {
            const idx = nodes.length;
            nodes.push({
                min: bounds.min,
                max: bounds.max,
                left: -1,
                right: -1,
                firstTri: start,
                triCount,
                leaf: true
            });
            return idx;
        }

        const centroidBounds = computeCentroidBounds(start, end);
        const extent = [
            centroidBounds.max[0] - centroidBounds.min[0],
            centroidBounds.max[1] - centroidBounds.min[1],
            centroidBounds.max[2] - centroidBounds.min[2]
        ];
        let axis = 0;
        if (extent[1] > extent[axis]) axis = 1;
        if (extent[2] > extent[axis]) axis = 2;

        const slice = indices.slice(start, end);
        slice.sort((a, b) => {
            const ta = triangles[a];
            const tb = triangles[b];
            const ca = 0.5 * (ta.aabb_min[axis] + ta.aabb_max[axis]);
            const cb = 0.5 * (tb.aabb_min[axis] + tb.aabb_max[axis]);
            return ca - cb;
        });
        for (let i = 0; i < slice.length; i++) {
            indices[start + i] = slice[i];
        }

        const mid = start + Math.floor(triCount / 2);
        const left = recurse(start, mid);
        const right = recurse(mid, end);

        const idx = nodes.length;
        nodes.push({
            min: bounds.min,
            max: bounds.max,
            left,
            right,
            firstTri: -1,
            triCount: 0,
            leaf: false
        });

        return idx;
    }

    let rootIndex = -1;
    if (count > 0) {
        rootIndex = recurse(0, count);
    }

    return { nodes, order: indices.slice(0, count), rootIndex };
}

function ensureTexFormats() {
    if (!gl) return;
    if (TEX_FORMATS) return;
    const useHalf = false; // need full precision for indices and bounds
    TEX_FORMATS = {
        triInternalFormat: useHalf ? gl.RGB16F : gl.RGB32F,
        triType: useHalf ? gl.HALF_FLOAT : gl.FLOAT,
        bvhInternalFormat: useHalf ? gl.RGBA16F : gl.RGBA32F,
        bvhType: useHalf ? gl.HALF_FLOAT : gl.FLOAT
    };
}

function generateBlueNoise(width = 64, height = 64, iterations = 3) {
    const size = width * height;
    const data = new Float32Array(size);
    for (let i = 0; i < size; i++) {
        data[i] = Math.random();
    }

    const temp = new Float32Array(size);
    for (let iter = 0; iter < iterations; iter++) {
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                let sum = 0;
                let count = 0;
                for (let oy = -1; oy <= 1; oy++) {
                    for (let ox = -1; ox <= 1; ox++) {
                        const nx = (x + ox + width) % width;
                        const ny = (y + oy + height) % height;
                        sum += data[ny * width + nx];
                        count++;
                    }
                }
                temp[y * width + x] = sum / count;
            }
        }

        for (let i = 0; i < size; i++) {
            const high = data[i] - temp[i];
            data[i] = Math.min(1, Math.max(0, 0.5 + high * 0.75));
        }
    }

    const bytes = new Uint8Array(size);
    for (let i = 0; i < size; i++) bytes[i] = Math.floor(data[i] * 255);
    return { bytes, width, height };
}

function ensureNoiseTexture() {
    if (!gl) return;
    if (noiseTexture) return;
    const { bytes, width, height } = generateBlueNoise(noiseTexSize[0], noiseTexSize[1]);
    noiseTexSize = [width, height];
    noiseTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, noiseTexture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.R8, width, height, 0, gl.RED, gl.UNSIGNED_BYTE, bytes);
}

function uploadBVH(nodes) {
    if (!gl) return;
    ensureTexFormats();
    const nodeCount = nodes.length;
    bvhNodeCount = nodeCount;

    const maxSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
    const width = Math.max(1, Math.min(maxSize, nodeCount));
    const height = Math.max(1, Math.ceil(nodeCount / width));
    bvhTexSize = [width, height];

    if (nodeCount === 0) {
        bvhTex0 = bvhTex0 || gl.createTexture();
        bvhTex1 = bvhTex1 || gl.createTexture();
        bvhTex2 = bvhTex2 || gl.createTexture();
        const zero = new Float32Array([0, 0, 0, 0]);
        [bvhTex0, bvhTex1, bvhTex2].forEach(tex => {
            gl.bindTexture(gl.TEXTURE_2D, tex);
            gl.texImage2D(gl.TEXTURE_2D, 0, TEX_FORMATS.bvhInternalFormat, 1, 1, 0, gl.RGBA, TEX_FORMATS.bvhType, zero);
        });
        return;
    }

    const texelCount = width * height;
    const data0 = new Float32Array(texelCount * 4);
    const data1 = new Float32Array(texelCount * 4);
    const data2 = new Float32Array(texelCount * 4);

    for (let i = 0; i < nodeCount; i++) {
        const n = nodes[i];
        const row = Math.floor(i / width);
        const col = i - row * width;
        const base = (row * width + col) * 4;

        data0[base + 0] = n.min[0];
        data0[base + 1] = n.min[1];
        data0[base + 2] = n.min[2];
        data0[base + 3] = n.leaf ? n.firstTri : n.left;

        data1[base + 0] = n.max[0];
        data1[base + 1] = n.max[1];
        data1[base + 2] = n.max[2];
        data1[base + 3] = n.leaf ? n.triCount : n.right;

        data2[base + 0] = n.leaf ? 1.0 : 0.0;
        data2[base + 1] = 0.0;
        data2[base + 2] = 0.0;
        data2[base + 3] = 0.0;
    }

    if (!bvhTex0) bvhTex0 = gl.createTexture();
    if (!bvhTex1) bvhTex1 = gl.createTexture();
    if (!bvhTex2) bvhTex2 = gl.createTexture();

    const upload = (tex, data) => {
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texImage2D(gl.TEXTURE_2D, 0, TEX_FORMATS.bvhInternalFormat, width, height, 0, gl.RGBA, TEX_FORMATS.bvhType, data);
    };

    upload(bvhTex0, data0);
    upload(bvhTex1, data1);
    upload(bvhTex2, data2);
}

function rebuildBVH(triangles) {
    const { nodes, order, rootIndex } = buildBVH(triangles);
    if (order && order.length > 0) {
        const reordered = order.map(i => triangles[i]);
        triangles.length = reordered.length;
        for (let i = 0; i < reordered.length; i++) triangles[i] = reordered[i];
    }
    if (nodes.length > 0 && rootIndex >= 0 && rootIndex < nodes.length) {
        const root = nodes[rootIndex];
        meshBoundsMin = root.min.slice();
        meshBoundsMax = root.max.slice();
    } else {
        meshBoundsMin = [0, 0, 0];
        meshBoundsMax = [0, 0, 0];
    }
    uploadTriangleTexture(triangles);
    uploadBVH(nodes);
}

function uploadTriangleTexture(triangles) {
    if (!gl) return;
    ensureTexFormats();
    const triCount = Math.min(triangles.length, MAX_TRIANGLES);
    triangleCount = triCount;
    const rows = 6; // v0, e1, e2, diffuse, info, emission
    const maxSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
    const width = Math.max(1, Math.min(maxSize, triCount));
    const blocks = Math.max(1, Math.ceil(triCount / width));
    const height = rows * blocks;
    triangleTexSize = [width, height];

    if (triCount === 0) {
        triangleTexture = triangleTexture || gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, triangleTexture);
        gl.texImage2D(gl.TEXTURE_2D, 0, TEX_FORMATS.triInternalFormat, 1, 1, 0, gl.RGB, TEX_FORMATS.triType, new Float32Array([0, 0, 0]));
        return;
    }

    const texelCount = width * height;
    const triData = new Float32Array(texelCount * 3);

    for (let i = 0; i < triCount; i++) {
        const t = triangles[i];
        const block = Math.floor(i / width);
        const col = i - block * width;
        const rowBase = block * rows;

        const writeVec3 = (rowOffset, v) => {
            const rowIndex = rowBase + rowOffset;
            const base = (rowIndex * width + col) * 3;
            triData[base + 0] = v[0];
            triData[base + 1] = v[1];
            triData[base + 2] = v[2];
        };

        writeVec3(0, t.v0);
        writeVec3(1, t.e1);
        writeVec3(2, t.e2);
        writeVec3(3, t.material.diffuseColor);
        writeVec3(4, [t.material.reflectivity, t.material.ior, t.material.materialType]);
        writeVec3(5, t.material.emissiveColor);
    }

    if (!triangleTexture) {
        triangleTexture = gl.createTexture();
    }

    gl.bindTexture(gl.TEXTURE_2D, triangleTexture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        TEX_FORMATS.triInternalFormat,
        width,
        height,
        0,
        gl.RGB,
        TEX_FORMATS.triType,
        triData
    );
}

async function loadOBJIntoScene(url, material = M_WOOD, append = false, options = {}) {
    try {
        const mesh = await loadOBJ(url);
        const triList = meshToTriangles(mesh, material, options);
        if (triList.length === 0) {
            console.warn('OBJ loaded but produced no triangles.');
            return;
        }

        const combined = append ? [...SCENE_DATA.triangles, ...triList] : triList;
        SCENE_DATA.triangles = combined.slice(0, MAX_TRIANGLES);
        rebuildBVH(SCENE_DATA.triangles);
        console.info(`Loaded ${triList.length} OBJ triangles (using ${SCENE_DATA.triangles.length}).`);
        console.info('Mesh bounds', meshBoundsMin, meshBoundsMax);
        if (SCENE_DATA.triangles.length > 0) {
            const t0 = SCENE_DATA.triangles[0];
            console.info('First triangle v0/e1/e2', t0.v0, t0.e1, t0.e2);
        }
    } catch (err) {
        console.warn('OBJ load failed:', err);
    }
}

// Mouse State for Interaction
let mouse = { x: 0, y: 0, lastX: 0, lastY: 0 };
let isDragging = false;
const rotationSpeed = 0.005;


const add_teapot = true
/**
 * Initializes and sets up the rendering loop.
 */
async function main() {
    try {
        setupWebGL();
        rebuildBVH(SCENE_DATA.triangles);
        if (add_teapot) {
            await loadOBJIntoScene(
                'models/teapot.obj',
                M_GOLD,
                true,
                { targetSize: 40.0, translate: [0.0, 15, -50.0] }
            );
        }
        setupMouseControls();
        setupWASDControls();
        animate();
        // We render once, but for responsiveness, we add a resize listener
        window.addEventListener('resize', render);
        render();
    } catch (e) {
        console.error("An error occurred during ray tracer initialization:", e);
        // Optionally display error message on screen
        document.getElementById('rayTraceCanvas').style.backgroundColor = 'red';
    }
}

// Run the application when the window is loaded
window.onload = main;
