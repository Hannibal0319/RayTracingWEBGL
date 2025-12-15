// Global WebGL state variables
var gl;
var canvas;
var positionsBuffer;
var program;

// Scene Data
const SCENE_DATA = {
    lightSphereCenter: [-1.5, 3.0, -4.0],
    lightSphereRadius: 0.5,
    
    spheres: [
        // SPHERE 1: REFRACTIVE (Left Foreground)
        new Sphere([-2.0, -0.2, -5.0], 0.8, new Material([0.1, 0.3, 0.2], 0.9, 1.5, REFRACTIVE)),
        
        // SPHERE 2: REFLECTIVE (Center Foreground)
        new Sphere([0.5, 0.0, -6.0], 1.0, new Material([0.3, 0.3, 0.3], 0.9, 1.0, REFLECTIVE)),
        
        // SPHERE 3: SHADOW (Right Foreground)
        new Sphere([3.0, -0.4, -7.0], 0.6, new Material([0.8, 0.1, 0.1], 0.0, 1.0, LAMBERTIAN))
    ],

    quads: [
        // Example Quad (floor)
        new Quad([-10.0, -1.0, -10.0], [20.0, 0.0, 0.0], [0.0, 0.0, 20.0], new Material([0.5, 0.5, 0.5], 0.1, 1.0, LAMBERTIAN)),
        // Gold unit square
        new Quad([1.5, -0.5, -4.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], new Material([1.0, 0.84, 0.0], 0.9, 1.0, REFLECTIVE))
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
