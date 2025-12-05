/**
 * Initializes WebGL context and shaders.
 */
function setupWebGL() {
    canvas = document.getElementById('rayTraceCanvas');
    // Try to get the WebGL 2.0 context first, fall back to WebGL 1.0
    gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');

    if (!gl) {
        console.error("Unable to initialize WebGL. Your browser may not support it.");
        return;
    }
    program = initShaders(gl, 'shaders/vertex-shader.glsl', 'shaders/fragment-shader.glsl');

    if (!program) {
        return;
    }
    gl.useProgram(program);

    // Create geometry for a fullscreen quad (two triangles)
    const positions = new Float32Array([
        -1, -1, // Bottom-left
            1, -1, // Bottom-right
        -1,  1, // Top-left
        -1,  1, // Top-left (repeated)
            1, -1, // Bottom-right (repeated)
            1,  1  // Top-right
    ]);
    
    positionsBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionsBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);
}