#version 300 es
precision mediump float;

out vec4 fragColor;

#define HAS_INTERPOLATED_RAYS 1

#include "fragment/uniforms.glsl"
#include "fragment/structs.glsl"
#include "fragment/utils.glsl"
#include "fragment/intersections.glsl"
#include "fragment/scene.glsl"
#include "fragment/shading.glsl"
#include "fragment/raytracer.glsl"

in vec3 v_rayDirCenter;
in vec2 v_uvPlane;

void main() {
    vec3 finalColor = vec3(0.0);
    vec2 pixelSize = 1.0 / u_resolution.xy;

    vec3 camRight = u_cameraRight;
    vec3 camUp = u_cameraUp;
    vec3 baseRayDir = normalize(v_rayDirCenter);

    for (int i = 0; i < SAMPLES_PER_PIXEL; i++) {
        vec2 jitter = vec2(random(gl_FragCoord.xy + float(i)), random(gl_FragCoord.xy - float(i))) - 0.5;
        vec2 fragCoord = gl_FragCoord.xy + jitter;
        vec2 uv = (2.0 * fragCoord - u_resolution.xy) / u_resolution.y;
        float fovScale = tan(radians(u_fov) * 0.5);
        vec2 uvFov = uv * fovScale;

        // Offset interpolated base ray by the jitter delta in view-plane space
        vec2 delta = uvFov - v_uvPlane;
        vec3 rayDirCenter = normalize(v_rayDirCenter + camRight * delta.x + camUp * delta.y);

        vec3 focalPoint = u_cameraPos + rayDirCenter * u_focalDistance;

        vec2 randDisk = vec2(random(uv + float(i)), random(uv - float(i)));
        float r = u_aperture * sqrt(randDisk.x);
        float theta = 2.0 * 3.1415926535 * randDisk.y;
        vec3 lensOffset = camRight * r * cos(theta) + camUp * r * sin(theta);

        vec3 rayOrigin = u_cameraPos + lensOffset;
        vec3 rayDir = normalize(focalPoint - rayOrigin);

        finalColor += traceRay(rayOrigin, rayDir);
    }

    finalColor /= float(SAMPLES_PER_PIXEL);
    fragColor = vec4(finalColor, 1.0);
}
