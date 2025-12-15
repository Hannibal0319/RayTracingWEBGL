// Global WebGL state variables
var gl;
var canvas;
var positionsBuffer;
var program;

const M_GLASS = new Material([0.95, 0.95, 0.95], 0.9, 1.5, REFRACTIVE);
const M_GOLD = new Material([1.0, 0.71, 0.29], 0.7, 0.47, REFLECTIVE);
const M_SILVER = new Material([0.6, 0.6, 0.6], 0.7, 0.14, REFLECTIVE);
const M_WATER = new Material([0.8, 0.9, 1.0], 0.7, 1.33, REFRACTIVE);

// Scene Data
const SCENE_DATA = {
    lightSphereCenter: [-1.5, 3.0, -4.0],
    lightSphereRadius: 0.5,
    
    spheres: [
        new Sphere([-2.0, -0.2, -5.0], 0.8, new Material([0.1, 0.3, 0.2], 0.9, 1.5, REFRACTIVE)),
        
        new Sphere([-7.0, 0.0, -8.0], 1.0, M_GOLD),
        
        new Sphere([3.0, -0.4, -7.0], 0.6, new Material([0.8, 0.1, 0.1], 0.0, 1.0, LAMBERTIAN)),

        new Sphere([0.0, 0.0, -7.0], 0.7, M_SILVER),
    ],

    quads: [
        // Gold unit square
        new Quad([1.5, -0.5, -4.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0], new Material([1.0, 0.84, 0.0], 0.15, 1.0, LAMBERTIAN)),
        new Quad([3.5, -0.5, -4.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], new Material([1.0, 0.84, 0.0], 0.15, 1.0, LAMBERTIAN))
        
    ],
    
    planeY: -1.0, 
    planeColorA: [0.3, 0.3, 0.3], 
    planeColorB: [0.5, 0.5, 0.5], 
    
    // Camera Controls
    cameraPos: [0.0, 0.0, 0.0],
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
