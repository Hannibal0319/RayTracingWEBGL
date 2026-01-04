/**
 * Renders the scene.
 */
const renderScale = typeof RENDER_SCALE !== 'undefined' ? RENDER_SCALE : 1.0;

function computeCameraRotationMatrix(rotation) {
    const yaw = rotation[0];
    const pitch = rotation[1];

    const cy = Math.cos(yaw);
    const sy = Math.sin(yaw);
    const cx = Math.cos(pitch);
    const sx = Math.sin(pitch);

    // Column-major mat3 for R = Ry * Rx
    return new Float32Array([
        cy,      0,   -sy,
        sy * sx, cx,  cy * sx,
        sy * cx, -sx, cy * cx
    ]);
}

function render() {
    if (!gl || !program) return;

    ensureNoiseTexture();

    // Handle Canvas Resizing
    const displayWidth = Math.max(1, Math.floor(canvas.clientWidth * renderScale));
    const displayHeight = Math.max(1, Math.floor(canvas.clientHeight * renderScale));

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

    // Ground Plane Uniforms
    gl.uniform1f(gl.getUniformLocation(program, 'u_planeY'), SCENE_DATA.planeY);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorA'), SCENE_DATA.planeColorA);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorB'), SCENE_DATA.planeColorB);
    
    // Camera Uniforms
    gl.uniform3fv(gl.getUniformLocation(program, 'u_cameraPos'), SCENE_DATA.cameraPos);
    gl.uniform2fv(gl.getUniformLocation(program, 'u_cameraRotation'), SCENE_DATA.cameraRotation);
    const camMat = computeCameraRotationMatrix(SCENE_DATA.cameraRotation);
    gl.uniformMatrix3fv(
        gl.getUniformLocation(program, 'u_cameraRotationMat'),
        false,
        camMat
    );
    // Camera basis vectors
    gl.uniform3fv(gl.getUniformLocation(program, 'u_cameraRight'), [camMat[0], camMat[1], camMat[2]]);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_cameraUp'),    [camMat[3], camMat[4], camMat[5]]);
    gl.uniform1f(gl.getUniformLocation(program, 'u_fov'), SCENE_DATA.fov);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_meshBoundsMin'), meshBoundsMin);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_meshBoundsMax'), meshBoundsMax);
    gl.uniform1f(gl.getUniformLocation(program, 'u_aperture'), SCENE_DATA.aperture);
    gl.uniform1f(gl.getUniformLocation(program, 'u_focalDistance'), SCENE_DATA.focalDistance);

    // Pass number of spheres
    gl.uniform1i(gl.getUniformLocation(program, 'u_sphereCount'), SCENE_DATA.spheres.length);

    // Extract data from sphere objects
    const sphereCenters = SCENE_DATA.spheres.map(s => s.center).flat();
    const sphereRadii = SCENE_DATA.spheres.map(s => s.radius);
    const sphereAABB_mins = SCENE_DATA.spheres.map(s => s.aabb_min).flat();
    const sphereAABB_maxs = SCENE_DATA.spheres.map(s => s.aabb_max).flat();
    const sphereDiffuseColors = SCENE_DATA.spheres.map(s => s.material.diffuseColor).flat();
    const sphereReflectivity = SCENE_DATA.spheres.map(s => s.material.reflectivity);
    const sphereIOR = SCENE_DATA.spheres.map(s => s.material.ior);
    const sphereMaterialTypes = SCENE_DATA.spheres.map(s => s.material.materialType);
    const sphereEmissionColors = SCENE_DATA.spheres.map(s => s.material.emissiveColor).flat();

    // Set sphere uniforms
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereCenters'), sphereCenters);
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereRadii'), sphereRadii);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereAABB_min'), sphereAABB_mins);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereAABB_max'), sphereAABB_maxs);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereDiffuseColors'), sphereDiffuseColors);
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereReflectivity'), sphereReflectivity);
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereIOR'), sphereIOR);
    gl.uniform1iv(gl.getUniformLocation(program, 'u_sphereMaterialTypes'), sphereMaterialTypes);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_sphereEmissionColors'), sphereEmissionColors);

    // Pass number of quads
    gl.uniform1i(gl.getUniformLocation(program, 'u_quadCount'), SCENE_DATA.quads.length);

    if (SCENE_DATA.quads.length > 0) {
        // Extract data from quad objects
        const quadCorners = SCENE_DATA.quads.map(q => q.corner).flat();
        const quadU = SCENE_DATA.quads.map(q => q.u).flat();
        const quadV = SCENE_DATA.quads.map(q => q.v).flat();
        const quadNormals = SCENE_DATA.quads.map(q => q.normal).flat();
        const quadAABB_mins = SCENE_DATA.quads.map(q => q.aabb_min).flat();
        const quadAABB_maxs = SCENE_DATA.quads.map(q => q.aabb_max).flat();
        const quadDiffuseColors = SCENE_DATA.quads.map(q => q.material.diffuseColor).flat();
        const quadReflectivity = SCENE_DATA.quads.map(q => q.material.reflectivity);
        const quadIOR = SCENE_DATA.quads.map(q => q.material.ior);
        const quadMaterialTypes = SCENE_DATA.quads.map(q => q.material.materialType);
        const quadEmissionColors = SCENE_DATA.quads.map(q => q.material.emissiveColor).flat();

        // Set quad uniforms
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadCorners'), quadCorners);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadU'), quadU);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadV'), quadV);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadNormals'), quadNormals);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadAABB_min'), quadAABB_mins);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadAABB_max'), quadAABB_maxs);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadDiffuseColors'), quadDiffuseColors);
        gl.uniform1fv(gl.getUniformLocation(program, 'u_quadReflectivity'), quadReflectivity);
        gl.uniform1fv(gl.getUniformLocation(program, 'u_quadIOR'), quadIOR);
        gl.uniform1iv(gl.getUniformLocation(program, 'u_quadMaterialTypes'), quadMaterialTypes);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_quadEmissionColors'), quadEmissionColors);
    }

    // Triangles via texture
    gl.uniform1i(gl.getUniformLocation(program, 'u_triangleCount'), typeof triangleCount !== 'undefined' ? triangleCount : triangleTexSize[0]);
    gl.uniform2f(gl.getUniformLocation(program, 'u_triTexSize'), triangleTexSize[0], triangleTexSize[1]);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, triangleTexture);
    gl.uniform1i(gl.getUniformLocation(program, 'u_triTex'), 0);

    // Blue noise texture
    gl.uniform2f(gl.getUniformLocation(program, 'u_noiseTexSize'), noiseTexSize[0], noiseTexSize[1]);
    gl.activeTexture(gl.TEXTURE4);
    gl.bindTexture(gl.TEXTURE_2D, noiseTexture);
    gl.uniform1i(gl.getUniformLocation(program, 'u_noiseTex'), 4);

    // BVH node textures
    gl.uniform1i(gl.getUniformLocation(program, 'u_bvhNodeCount'), typeof bvhNodeCount !== 'undefined' ? bvhNodeCount : bvhTexSize[0]);
    gl.uniform2f(gl.getUniformLocation(program, 'u_bvhTexSize'), bvhTexSize[0], bvhTexSize[1]);
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, bvhTex0);
    gl.uniform1i(gl.getUniformLocation(program, 'u_bvhTex0'), 1);
    gl.activeTexture(gl.TEXTURE2);
    gl.bindTexture(gl.TEXTURE_2D, bvhTex1);
    gl.uniform1i(gl.getUniformLocation(program, 'u_bvhTex1'), 2);
    gl.activeTexture(gl.TEXTURE3);
    gl.bindTexture(gl.TEXTURE_2D, bvhTex2);
    gl.uniform1i(gl.getUniformLocation(program, 'u_bvhTex2'), 3);

    // Point light
    gl.uniform3fv(gl.getUniformLocation(program, 'u_pointLightPos'), SCENE_DATA.pointLight.pos);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_pointLightColor'), SCENE_DATA.pointLight.color);

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
        const pitch = SCENE_DATA.cameraRotation[1];

        // Calculate forward vector including pitch for looking up/down
        const forward = [
            Math.sin(yaw) * Math.cos(pitch),
            -Math.sin(pitch),
            -Math.cos(yaw) * Math.cos(pitch)
        ];

        // Right vector should always be horizontal (on the XZ plane)
        const right = [Math.cos(yaw), 0, Math.sin(yaw)];

        switch (e.key.toLowerCase()) { // Use toLowerCase() to handle Caps Lock
            case 'w':
                SCENE_DATA.cameraPos[0] += forward[0] * moveSpeed;
                SCENE_DATA.cameraPos[1] += forward[1] * moveSpeed;
                SCENE_DATA.cameraPos[2] += forward[2] * moveSpeed;
                break;
            case 's':
                SCENE_DATA.cameraPos[0] -= forward[0] * moveSpeed;
                SCENE_DATA.cameraPos[1] -= forward[1] * moveSpeed;
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
    });
}

