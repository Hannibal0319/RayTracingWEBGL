// Global WebGL state variables
var gl;
var canvas;
var positionsBuffer;
var program;

const M_GLASS = new Material([0.95, 0.95, 0.95], 0.9, 1.5, REFRACTIVE);
const M_GOLD = new Material([1.0, 0.71, 0.29], 0.7, 0.47, REFLECTIVE);
const M_SILVER = new Material([0.6, 0.6, 0.6], 0.7, 0.14, REFLECTIVE);
const M_WATER = new Material([0.8, 0.9, 1.0], 0.7, 1.33, REFRACTIVE);
const M_WOOD = new Material([0.9, 0.6, 0.5], 0.1, 1.0, LAMBERTIAN);
const M_WHITE_WALL = new Material([1., 2., 2.], 0.2, 1.0, LAMBERTIAN);
const M_LAMB = new Material([1., 2., 2.], 0.2, 1.0, LAMBERTIAN);
const M_RED_WALL = new Material([1., 0.5, 0.5], 0.2, 1.0, LAMBERTIAN);
const M_GREEN_WALL = new Material([0.5, 2., 0.5], 0.2, 1.0, LAMBERTIAN);
const M_LIGHT_SOFT = new Material([1.0, 0.95, 0.9], 0.0, 1.0, EMISSIVE, [5, 5, 5]);
const M_ROUGH = new Material([0.8, 0.7, 0.6], 0.3, 1.0, METALLIC_ROUGHNESS, [0, 0, 0], 0.8, 0.9);

// Scene Data
const SCENE_DATA = {
    spheres: [
        new Sphere([-2.0, .0, -2.0], 1, M_GOLD),
        new Sphere([-2.0, .0, 2.0], 1, M_SILVER),
        new Sphere([2.0, .0, -2.0], 1, M_ROUGH),
        
        // new Sphere([-7.0, 0.0, -8.0], 1.0, M_GOLD),
        
        new Sphere([2.0, .0, 2], 1, M_GLASS),
        new Sphere([0.0, .0, -0.], 1, M_LAMB),

        // new Sphere([0.0, 0.0, -7.0], 0.7, M_SILVER),

        // New emissive sphere light (soft, warm glow)
        // new Sphere([-1.0, 0., -3], 1, M_GOLD),
    ],

    quads: [
        // new Quad([1.5, -0.5, -4.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0], M_GOLD),
        new Quad([-5.5, 9.0, -5.5], [12.0, 0.0, 0.0],[0.0, 0.0, 12.0], M_LIGHT_SOFT), // TOP
        new Quad([ 5.5, -1.0, -5.5], [0.0, 0.0, 12.0],[0.0, 12.0, 0.0], M_GREEN_WALL), // RIGHT
        new Quad([-5.5, -1.0,  5.5], [0.0, 0.0, -12.0],[0.0, 12.0, 0.0], M_RED_WALL), // LEFT
        new Quad([ 5.5, -1.0, -5.5], [-12.0, 0.0, 0.0],[0.0, 0.0, 12.0], M_WHITE_WALL),
        new Quad([ 5.5, -1.0,  5.5], [-12.0, 0.0, 0.0],[0.0, 12.0, 0.1], M_WHITE_WALL),
        new Quad([-5.5, -1.0, -5.5], [ 12.0, 0.0, 0.0],[0.0, 12.0, 0.1], M_WHITE_WALL),
    ],

    triangles: [
        // new Triangle([-2.5, -0.5, -4.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0], new Material([0.2, 0.6, 0.9], 0.05, 1.0, LAMBERTIAN)),
        // new Triangle([4.0, -0.5, -6.0], [0.0, 0.0, 1.0],[0.0, 1.0, 0.0], new Material([0.9, 0.4, 0.2], 0.2, 1.0, LAMBERTIAN)),
    ],
    
    planeY: -1.0, 
    planeColorA: [0.3, 0.3, 0.3], 
    planeColorB: [0.5, 0.5, 0.5], 
    
    // Camera Controls
    cameraPos: [0.0, .5, 2.0],
    cameraRotation: [0.0, 0.0],
    aperture: 0.01,
    focalDistance: 5.0
};

// Mouse State for Interaction
let mouse = { x: 0, y: 0, lastX: 0, lastY: 0 };
let isDragging = false;
const rotationSpeed = 0.005;


/**
 * Initializes and sets up the rendering loop.
 */
function main() {
    try {
        setupWebGL();
        setupMouseControls();
        setupWASDControls();
        if (typeof setupObjectPicking === 'function') setupObjectPicking();
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
