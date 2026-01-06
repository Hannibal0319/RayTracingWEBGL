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
        setupFramebufferTexture(canvas.width, canvas.height);
        frameCount = 0;
    }

    // --- Render to Texture ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    gl.viewport(0, 0, canvas.width, canvas.height);
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
    const timeLocation = gl.getUniformLocation(program, 'u_time');
    gl.uniform1f(timeLocation, performance.now() * .000001);
    gl.uniform1f(gl.getUniformLocation(program, 'u_planeY'), SCENE_DATA.planeY);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorA'), SCENE_DATA.planeColorA);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_planeColorB'), SCENE_DATA.planeColorB);
    gl.uniform3fv(gl.getUniformLocation(program, 'u_cameraPos'), SCENE_DATA.cameraPos);
    gl.uniform2fv(gl.getUniformLocation(program, 'u_cameraRotation'), SCENE_DATA.cameraRotation);
    gl.uniform1f(gl.getUniformLocation(program, 'u_aperture'), SCENE_DATA.aperture);
    gl.uniform1f(gl.getUniformLocation(program, 'u_focalDistance'), SCENE_DATA.focalDistance);
    gl.uniform1i(gl.getUniformLocation(program, 'u_sphereCount'), SCENE_DATA.spheres.length);
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

    // Accumulation uniforms
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, accumTexture);
    gl.uniform1i(gl.getUniformLocation(program, 'u_accumTexture'), 0);
    gl.uniform1i(gl.getUniformLocation(program, 'u_frameCount'), frameCount);

    // 3. Draw the Quad
    gl.drawArrays(gl.TRIANGLES, 0, 6); // Draw 6 vertices (2 triangles)

    // --- Render Texture to Canvas ---
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArrays(gl.TRIANGLES, 0, 6);

    // Copy renderTexture to accumTexture for next frame
    gl.bindFramebuffer(gl.READ_FRAMEBUFFER, framebuffer);
    gl.bindTexture(gl.TEXTURE_2D, accumTexture);
    gl.copyTexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 0, 0, canvas.width, canvas.height, 0);
    gl.bindTexture(gl.TEXTURE_2D, null);

    frameCount++;
}

// FPS Counter state
let frameCount = 0;
let fpsFrameCount = 0;
let lastTime = performance.now();
const fpsElement = document.getElementById('fps-counter');

// NEW: Continuous Animation Loop
function animate(now) {
    // FPS calculation
    if (fpsElement) {
        fpsFrameCount++;
        const deltaTime = now - lastTime;
        if (deltaTime >= 1000) {
            fpsElement.textContent = `FPS: ${fpsFrameCount}`;
            fpsFrameCount = 0;
            lastTime = now;
        }
    }

    render();
    requestAnimationFrame(animate);
}

var framebuffer = null;
var renderTexture = null;
var accumTexture = null;

function setupFramebufferTexture(width, height) {
    // Create texture
    renderTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, renderTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    accumTexture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, accumTexture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    // Create framebuffer
    framebuffer = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, renderTexture, 0);

    // Unbind for now
    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
}

// --- Render to Texture ---
gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
gl.viewport(0, 0, canvas.width, canvas.height);
gl.clearColor(0.0, 0.0, 0.0, 1.0);
gl.clear(gl.COLOR_BUFFER_BIT);

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
        SCENE_DATA.cameraRotation[0] -= deltaX * rotationSpeed;
        SCENE_DATA.cameraRotation[1] += deltaY * rotationSpeed;
        SCENE_DATA.cameraRotation[1] = Math.max(-1.5, Math.min(1.5, SCENE_DATA.cameraRotation[1]));
        mouse.lastX = mouse.x;
        mouse.lastY = mouse.y;
        resetAccumulation(); // Reset accumulation on camera move
    });

    canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const zoomSpeed = 0.2;
        const zoomDirection = e.deltaY < 0 ? 1.0 : -1.0;
        const yaw = SCENE_DATA.cameraRotation[0];
        const pitch = SCENE_DATA.cameraRotation[1];
        const forwardX = Math.sin(yaw) * Math.cos(pitch);
        const forwardY = Math.sin(pitch);
        const forwardZ = -Math.cos(yaw) * Math.cos(pitch);
        SCENE_DATA.cameraPos[0] += forwardX * zoomSpeed * zoomDirection;
        SCENE_DATA.cameraPos[1] += forwardY * zoomSpeed * zoomDirection;
        SCENE_DATA.cameraPos[2] += forwardZ * zoomSpeed * zoomDirection;
        resetAccumulation(); // Reset accumulation on zoom
    });
    window.addEventListener('resize', render);
}

function setupWASDControls() {
    const moveSpeed = 0.1;
    window.addEventListener('keydown', (e) => {
        const yaw = SCENE_DATA.cameraRotation[0];
        const pitch = SCENE_DATA.cameraRotation[1];
        const forward = [
            Math.sin(yaw) * Math.cos(pitch),
            -Math.sin(pitch),
            -Math.cos(yaw) * Math.cos(pitch)
        ];
        const right = [Math.cos(yaw), 0, Math.sin(yaw)];
        let moved = false;
        switch (e.key.toLowerCase()) {
            case 'w':
                SCENE_DATA.cameraPos[0] += forward[0] * moveSpeed;
                SCENE_DATA.cameraPos[1] += forward[1] * moveSpeed;
                SCENE_DATA.cameraPos[2] += forward[2] * moveSpeed;
                moved = true;
                break;
            case 's':
                SCENE_DATA.cameraPos[0] -= forward[0] * moveSpeed;
                SCENE_DATA.cameraPos[1] -= forward[1] * moveSpeed;
                SCENE_DATA.cameraPos[2] -= forward[2] * moveSpeed;
                moved = true;
                break;
            case 'a':
                SCENE_DATA.cameraPos[0] -= right[0] * moveSpeed;
                SCENE_DATA.cameraPos[2] -= right[2] * moveSpeed;
                moved = true;
                break;
            case 'd':
                SCENE_DATA.cameraPos[0] += right[0] * moveSpeed;
                SCENE_DATA.cameraPos[2] += right[2] * moveSpeed;
                moved = true;
                break;
        }
        if (moved) resetAccumulation(); // Reset accumulation on WASD move
    });
}

// To reset accumulation on camera movement, add this to camera controls:
function resetAccumulation() {
    frameCount = 0;
}

