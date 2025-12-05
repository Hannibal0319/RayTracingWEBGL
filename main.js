// Global WebGL state variables
var gl;
var canvas;
var positionsBuffer;
var program;

// Scene Data - Now includes parameters for three spheres
const SCENE_DATA = {
    // SPHERE 0: REFLECTIVE (Left)
    sphereCenter0: [-1.5, -0.2, -4.5], 
    sphereRadius0: 0.8,
    sphereDiffuseColor0: [0.9, 0.9, 0.9], // Silver
    sphereReflectivity0: 0.9,
    sphereIOR0: 1.0, // Non-refractive
    
    // SPHERE 1: REFRACTIVE (Center)
    sphereCenter1: [-5.0, -0.0, -5.0], 
    sphereRadius1: 1.0,
    sphereDiffuseColor1: [0.1, 0.3, 0.4], // Light Blue/Glass tint
    sphereReflectivity1: 0.2, // Some reflection on surface
    sphereIOR1: 1.5, // Glass IOR
    
    // SPHERE 2: SHADOW (Right)
    sphereCenter2: [2.0, -0.4, -6.0], 
    sphereRadius2: 0.6,
    sphereDiffuseColor2: [0.8, 0.1, 0.6], // Red
    sphereReflectivity2: 0.0,
    sphereIOR2: 1.0,
    
    lightDir: [1.0, 1.0, 1.0], 
    planeY: -1.0, 
    planeColorA: [0.3, 0.3, 0.3], 
    planeColorB: [0.5, 0.5, 0.5], 
    
    // Camera Controls
    cameraPos: [0.0, 0.0, 0.0],
    cameraRotation: [0.0, 0.0]
};

// NEW: Mouse State for Interaction
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
