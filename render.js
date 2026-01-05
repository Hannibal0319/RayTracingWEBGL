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

    // Ground Plane Uniforms
    gl.uniform1f(gl.getUniformLocation(program, 'u_planeY'), SCENE_DATA.planeY);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorA'), SCENE_DATA.planeColorA);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorB'), SCENE_DATA.planeColorB);
    
    // Camera Uniforms
    gl.uniform3fv(gl.getUniformLocation(program, 'u_cameraPos'), SCENE_DATA.cameraPos);
    gl.uniform2fv(gl.getUniformLocation(program, 'u_cameraRotation'), SCENE_DATA.cameraRotation);
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
    const sphereMetallic = SCENE_DATA.spheres.map(s => s.material.metallic);
    const sphereRoughness = SCENE_DATA.spheres.map(s => s.material.roughness);

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
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereMetallic'), sphereMetallic);
    gl.uniform1fv(gl.getUniformLocation(program, 'u_sphereRoughness'), sphereRoughness);

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
        const quadMetallic = SCENE_DATA.quads.map(q => q.material.metallic);
        const quadRoughness = SCENE_DATA.quads.map(q => q.material.roughness);

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
        gl.uniform1fv(gl.getUniformLocation(program, 'u_quadMetallic'), quadMetallic);
        gl.uniform1fv(gl.getUniformLocation(program, 'u_quadRoughness'), quadRoughness);
    }

    // Triangles
    gl.uniform1i(gl.getUniformLocation(program, 'u_triangleCount'), SCENE_DATA.triangles.length);
    if (SCENE_DATA.triangles.length > 0) {
        const triV0 = SCENE_DATA.triangles.map(t => t.v0).flat();
        const triE1 = SCENE_DATA.triangles.map(t => t.e1).flat();
        const triE2 = SCENE_DATA.triangles.map(t => t.e2).flat();
        const triNormals = SCENE_DATA.triangles.map(t => t.normal).flat();
        const triAABB_mins = SCENE_DATA.triangles.map(t => t.aabb_min).flat();
        const triAABB_maxs = SCENE_DATA.triangles.map(t => t.aabb_max).flat();
        const triDiffuseColors = SCENE_DATA.triangles.map(t => t.material.diffuseColor).flat();
        const triReflectivity = SCENE_DATA.triangles.map(t => t.material.reflectivity);
        const triIOR = SCENE_DATA.triangles.map(t => t.material.ior);
        const triMaterialTypes = SCENE_DATA.triangles.map(t => t.material.materialType);
        const triEmissionColors = SCENE_DATA.triangles.map(t => t.material.emissiveColor).flat();
        const triMetallic = SCENE_DATA.triangles.map(t => t.material.metallic);
        const triRoughness = SCENE_DATA.triangles.map(t => t.material.roughness);

        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleV0'), triV0);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleE1'), triE1);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleE2'), triE2);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleNormals'), triNormals);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleAABB_min'), triAABB_mins);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleAABB_max'), triAABB_maxs);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleDiffuseColors'), triDiffuseColors);
        gl.uniform1fv(gl.getUniformLocation(program, 'u_triangleReflectivity'), triReflectivity);
        gl.uniform1fv(gl.getUniformLocation(program, 'u_triangleIOR'), triIOR);
        gl.uniform1iv(gl.getUniformLocation(program, 'u_triangleMaterialTypes'), triMaterialTypes);
        gl.uniform3fv(gl.getUniformLocation(program, 'u_triangleEmissionColors'), triEmissionColors);
        gl.uniform1fv(gl.getUniformLocation(program, 'u_triangleMetallic'), triMetallic);
        gl.uniform1fv(gl.getUniformLocation(program, 'u_triangleRoughness'), triRoughness);
    }

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

