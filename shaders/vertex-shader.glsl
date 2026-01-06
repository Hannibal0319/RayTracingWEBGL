#version 300 es
precision highp float;

in vec2 a_position;

uniform mat3 u_cameraRotationMat;
uniform vec2 u_resolution;

out vec3 v_rayDirCenter; // unnormalized camera-space ray for this vertex
out vec2 v_uvPlane;     // view-plane coords used for this vertex

void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);

    // Map clip-space to view-plane coordinates scaled by aspect (FOV applied in fragment)
    vec2 ndc = a_position; // already in [-1, 1]
    v_uvPlane = vec2(ndc.x * (u_resolution.x / u_resolution.y), ndc.y);

    // Build camera-space ray (before normalization) and rotate
    vec3 ray = u_cameraRotationMat * vec3(v_uvPlane, -1.0);
    v_rayDirCenter = ray;
}