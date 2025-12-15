// --- Main Function ---

void main() {
    vec3 finalColor = vec3(0.0);
    vec2 pixelSize = 1.0 / u_resolution.xy;

    mat3 camRotation = rotateY(u_cameraRotation.x) * rotateX(u_cameraRotation.y);
    vec3 camRight = camRotation * vec3(1.0, 0.0, 0.0);
    vec3 camUp = camRotation * vec3(0.0, 1.0, 0.0);

    for (int i = 0; i < SAMPLES_PER_PIXEL; i++) {
        vec2 jitter = vec2(random(gl_FragCoord.xy + float(i)), random(gl_FragCoord.xy - float(i))) - 0.5;
        vec2 fragCoord = gl_FragCoord.xy + jitter;
        vec2 uv = (2.0 * fragCoord - u_resolution.xy) / u_resolution.y;

        vec3 rayDirCenter = normalize(vec3(uv.x, uv.y, -1.0));
        rayDirCenter = camRotation * rayDirCenter;

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
    gl_FragColor = vec4(finalColor, 1.0);
}
