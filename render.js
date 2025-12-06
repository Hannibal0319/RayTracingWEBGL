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

    // LIGHT SPHERE UNIFORMS
    gl.uniform3fv(gl.getUniformLocation(program, 'u_lightSphereCenter'), SCENE_DATA.lightSphereCenter);
    gl.uniform1f(gl.getUniformLocation(program, 'u_lightSphereRadius'), SCENE_DATA.lightSphereRadius);
    
    // Ground Plane Uniforms
    gl.uniform1f(gl.getUniformLocation(program, 'u_planeY'), SCENE_DATA.planeY);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorA'), SCENE_DATA.planeColorA);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorB'), SCENE_DATA.planeColorB);
    
    // Camera Uniforms
    gl.uniform3fv(gl.getUniformLocation(program, 'u_cameraPos'), SCENE_DATA.cameraPos);
    gl.uniform2fv(gl.getUniformLocation(program, 'u_cameraRotation'), SCENE_DATA.cameraRotation);

    // Scene Sphere Array Uniforms (Indices 1, 2, and 3)
    const sphereCenters = [SCENE_DATA.sphereCenter1, SCENE_DATA.sphereCenter2, SCENE_DATA.sphereCenter3];
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereCenters'), sphereCenters.flat());

    const sphereRadii = [SCENE_DATA.sphereRadius1, SCENE_DATA.sphereRadius2, SCENE_DATA.sphereRadius3];
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereRadii'), sphereRadii);

    // Calculate AABBs for each sphere
    const sphereAABB_mins = [];
    const sphereAABB_maxs = [];
    for (let i = 0; i < 3; i++) {
        const center = sphereCenters[i];
        const radius = sphereRadii[i];
        sphereAABB_mins.push([center[0] - radius, center[1] - radius, center[2] - radius]);
        sphereAABB_maxs.push([center[0] + radius, center[1] + radius, center[2] + radius]);
    }
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereAABB_min'), sphereAABB_mins.flat());
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereAABB_max'), sphereAABB_maxs.flat());
    
    const sphereDiffuseColors = [SCENE_DATA.sphereDiffuseColor1, SCENE_DATA.sphereDiffuseColor2, SCENE_DATA.sphereDiffuseColor3].flat();
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereDiffuseColors'), sphereDiffuseColors);

    const sphereReflectivity = [SCENE_DATA.sphereReflectivity1, SCENE_DATA.sphereReflectivity2, SCENE_DATA.sphereReflectivity3];
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereReflectivity'), sphereReflectivity);

    const sphereIOR = [SCENE_DATA.sphereIOR1, SCENE_DATA.sphereIOR2, SCENE_DATA.sphereIOR3];
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereIOR'), sphereIOR);

    // 3. Draw the Quad
    gl.drawArrays(gl.TRIANGLES, 0, 6); // Draw 6 vertices (2 triangles)
}

// FPS Counter state
let frameCount = 0;
let lastTime = performance.now();
const fpsElement = document.getElementById('fps-counter');

// NEW: Continuous Animation Loop
function animate(now) {
    // FPS calculation
    if (fpsElement) {
        frameCount++;
        const deltaTime = now - lastTime;
        if (deltaTime >= 1000) {
            fpsElement.textContent = `FPS: ${frameCount}`;
            frameCount = 0;
            lastTime = now;
        }
    }

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

    canvas.addEventListener('wheel', (e) => {
        e.preventDefault(); // Prevent the page from scrolling

        const zoomSpeed = 0.2;
        const zoomDirection = e.deltaY < 0 ? 1.0 : -1.0; // Scroll up to zoom in, down to zoom out

        // This is a simple dolly zoom. We move the camera along its forward vector.
        const yaw = SCENE_DATA.cameraRotation[0];
        const pitch = SCENE_DATA.cameraRotation[1];

        // Calculate the forward vector based on current camera rotation
        const forwardX = Math.sin(yaw) * Math.cos(pitch);
        const forwardY = Math.sin(pitch);
        const forwardZ = -Math.cos(yaw) * Math.cos(pitch);
        
        // Update camera position
        SCENE_DATA.cameraPos[0] += forwardX * zoomSpeed * zoomDirection;
        SCENE_DATA.cameraPos[1] += forwardY * zoomSpeed * zoomDirection;
        SCENE_DATA.cameraPos[2] += forwardZ * zoomSpeed * zoomDirection;

        // No need to call render() here as the animate loop will pick up the change
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

