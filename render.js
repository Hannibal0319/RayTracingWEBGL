/**
 * Renders the scene.
 */
function render() {
    if (!gl || !program) return;

    // Handle Canvas Resizing
    const displayWidth = canvas.clientWidth;
    const displayHeight = canvas.clientHeight;

    if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
        canvas.width = displayWidth;
        canvas.height = displayHeight;
        gl.viewport(0, 0, canvas.width, canvas.height);
    }

    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    // 1. Set Attributes (The Quad)
    const positionLocation = gl.getAttribLocation(program, 'a_position');
    gl.enableVertexAttribArray(positionLocation);
    gl.bindBuffer(gl.ARRAY_BUFFER, positionsBuffer);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

    // 2. Set Uniforms (Scene Data)
    
    const resolutionLocation = gl.getUniformLocation(program, 'u_resolution');
    gl.uniform2f(resolutionLocation, canvas.width, canvas.height);

    const lightDirLocation = gl.getUniformLocation(program, 'u_lightDir');
    gl.uniform3fv(lightDirLocation, SCENE_DATA.lightDir);
    
    // Ground Plane Uniforms
    const planeYLocation = gl.getUniformLocation(program, 'u_planeY');
    gl.uniform1f(planeYLocation, SCENE_DATA.planeY);

    const planeColorALocation = gl.getUniformLocation(program, 'u_planeColorA');
    gl.uniform3fv(planeColorALocation, SCENE_DATA.planeColorA);

    const planeColorBLocation = gl.getUniformLocation(program, 'u_planeColorB');
    gl.uniform3fv(planeColorBLocation, SCENE_DATA.planeColorB);
    
    // Camera Uniforms
    const cameraPosLocation = gl.getUniformLocation(program, 'u_cameraPos');
    gl.uniform3fv(cameraPosLocation, SCENE_DATA.cameraPos);
    
    const cameraRotLocation = gl.getUniformLocation(program, 'u_cameraRotation');
    gl.uniform2fv(cameraRotLocation, SCENE_DATA.cameraRotation);

    // NEW: Sphere Array Uniforms (Must be loaded as arrays)
    const sphereCenters = [
        SCENE_DATA.sphereCenter0, SCENE_DATA.sphereCenter1, SCENE_DATA.sphereCenter2
    ].flat();
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereCenters'), sphereCenters);

    const sphereRadii = [
        SCENE_DATA.sphereRadius0, SCENE_DATA.sphereRadius1, SCENE_DATA.sphereRadius2
    ];
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereRadii'), sphereRadii);
    
    const sphereDiffuseColors = [
        SCENE_DATA.sphereDiffuseColor0, SCENE_DATA.sphereDiffuseColor1, SCENE_DATA.sphereDiffuseColor2
    ].flat();
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereDiffuseColors'), sphereDiffuseColors);

    const sphereReflectivity = [
        SCENE_DATA.sphereReflectivity0, SCENE_DATA.sphereReflectivity1, SCENE_DATA.sphereReflectivity2
    ];
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereReflectivity'), sphereReflectivity);

    const sphereIOR = [
        SCENE_DATA.sphereIOR0, SCENE_DATA.sphereIOR1, SCENE_DATA.sphereIOR2
    ];
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereIOR'), sphereIOR);

    // 3. Draw the Quad
    gl.drawArrays(gl.TRIANGLES, 0, 6); // Draw 6 vertices (2 triangles)
}

// NEW: Continuous Animation Loop
function animate() {
    render();
    requestAnimationFrame(animate);
}

// NEW: Mouse Interaction Handlers
function setupMouseControls() {
    canvas.addEventListener('mousedown', (e) => {
        isDragging = true;
        mouse.lastX = e.clientX;
        mouse.lastY = e.clientY;
    });

    window.addEventListener('mouseup', () => {
        isDragging = false;
    });

    canvas.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        
        mouse.x = e.clientX;
        mouse.y = e.clientY;

        const deltaX = mouse.x - mouse.lastX;
        const deltaY = mouse.y - mouse.lastY;

        // Yaw (Rotation around Y axis) - controls left/right looking
        SCENE_DATA.cameraRotation[0] -= deltaX * rotationSpeed; 
        
        // Pitch (Rotation around X axis) - controls up/down looking, clamped
        SCENE_DATA.cameraRotation[1] += deltaY * rotationSpeed;
        // Clamp pitch to prevent camera flipping over
        SCENE_DATA.cameraRotation[1] = Math.max(-1.5, Math.min(1.5, SCENE_DATA.cameraRotation[1]));

        mouse.lastX = mouse.x;
        mouse.lastY = mouse.y;
    });

    window.addEventListener('resize', render); // Keep resize handler
}

function setupWASDControls() {
    const moveSpeed = 0.1;
    window.addEventListener('keydown', (e) => {
        const yaw = SCENE_DATA.cameraRotation[0];
        const forward = [Math.sin(yaw), 0, -Math.cos(yaw)];
        const right = [Math.cos(yaw), 0, Math.sin(yaw)];
        switch (e.key) {
            case 'w':
                SCENE_DATA.cameraPos[0] += forward[0] * moveSpeed;
                SCENE_DATA.cameraPos[2] += forward[2] * moveSpeed;
                break;
            case 's':
                SCENE_DATA.cameraPos[0] -= forward[0] * moveSpeed;
                SCENE_DATA.cameraPos[2] -= forward[2] * moveSpeed;
                break;
            case 'a':
                SCENE_DATA.cameraPos[0] -= right[0] * moveSpeed;
                SCENE_DATA.cameraPos[2] -= right[2] * moveSpeed;
                break;
            case 'd':
                SCENE_DATA.cameraPos[0] += right[0] * moveSpeed;
                SCENE_DATA.cameraPos[2] += right[2] * moveSpeed;
                break;
        }
        render(); // Re-render the scene after camera movement
    });
}

