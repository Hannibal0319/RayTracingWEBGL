// Global WebGL state variables
var gl;
var canvas;
var positionsBuffer;
var program;

// Scene Data - Now includes parameters for three spheres
const SCENE_DATA = {
    // SPHERE 0: THE LIGHT SOURCE
    lightSphereCenter: [-1.5, 3.0, -4.0], // Positioned higher up
    lightSphereRadius: 0.5,
    
    // SPHERE 1: REFRACTIVE (Left Foreground) - Maps to u_sphereCenters[0] in GLSL
    sphereCenter1: [-2.0, -0.2, -5.0], // Moved left
    sphereRadius1: 0.8,
    sphereDiffuseColor1: [0.1, 0.3, 0.2], 
    sphereReflectivity1: 0.9, // High reflectivity to show reflection/refraction contrast
    sphereIOR1: 1.5, 
    
    // SPHERE 2: REFLECTIVE (Center Foreground) - Maps to u_sphereCenters[1] in GLSL
    sphereCenter2: [0.5, 0.0, -6.0], // New sphere position
    sphereRadius2: 1.0,
    sphereDiffuseColor2: [0.3, 0.3, 0.3], // Silver/White
    sphereReflectivity2: 0.9, // Mirror
    sphereIOR2: 1.0,
    
    // SPHERE 3: SHADOW (Right Foreground) - Maps to u_sphereCenters[2] in GLSL
    sphereCenter3: [3.0, -0.4, -7.0], 
    sphereRadius3: 0.6,
    sphereDiffuseColor3: [0.8, 0.1, 0.1], 
    sphereReflectivity3: 0.0,
    sphereIOR3: 1.0,
    
    planeY: -1.0, 
    planeColorA: [0.3, 0.3, 0.3], 
    planeColorB: [0.5, 0.5, 0.5], 
    
    // Camera Controls
    cameraPos: [0.0, 0.0, 0.0],
    cameraRotation: [0.0, 0.0],
    aperture: 0.01,       // NEW: Lens radius for defocus blur
    focalDistance: 5.0   // NEW: Distance to the plane of perfect focus
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
