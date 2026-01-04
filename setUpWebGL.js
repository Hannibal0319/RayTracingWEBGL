/**
 * Initializes WebGL context and shaders.
 */
function setupWebGL() {
    canvas = document.getElementById('rayTraceCanvas');
    // Require WebGL2 for float textures used by triangle data
    gl = canvas.getContext('webgl2', { antialias: false });

    const glVersionEl = document.getElementById('gl-version');
    if (glVersionEl) {
        if (gl) {
            const type = gl instanceof WebGL2RenderingContext ? 'WebGL 2' : 'WebGL 1';
            glVersionEl.textContent = `Running ${type}`;
        } else {
            glVersionEl.textContent = 'WebGL 2 required but not available';
        }
    }

    if (!gl) {
        console.error("Unable to initialize WebGL2. Your browser may not support it.");
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