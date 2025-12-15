// --- Shading Functions ---

float calculateShadow(vec3 hitPoint, vec3 N) {
    vec3 lightVec = u_lightSphereCenter - hitPoint;
    vec3 shadowRayDir = normalize(lightVec);
    float distanceToLight = length(lightVec);
    vec3 shadowRayOrigin = hitPoint + N * EPSILON * 5.0;

    for (int i = 0; i < 3; ++i) {
        float t = intersectSphere(shadowRayOrigin, shadowRayDir, u_sphereCenters[i], u_sphereRadii[i]);
        if (t > EPSILON && t < distanceToLight) {
            return 0.2; // Shadowed
        }
    }

    for (int i = 0; i < MAX_QUADS; ++i) {
        if (i >= u_quadCount) break;
        float t = intersectQuad(shadowRayOrigin, shadowRayDir, u_quadCorners[i], u_quadU[i], u_quadV[i], u_quadNormals[i]);
        if (t > EPSILON && t < distanceToLight) {
            return 0.2; // Shadowed
        }
    }

    return 1.0; // Lit
}

vec3 shade(HitRecord hit, vec3 rayOrigin, vec3 rayDir) {
    vec3 hitPoint = rayOrigin + rayDir * hit.t;
    vec3 N = hit.normal;

    vec3 lightVec = u_lightSphereCenter - hitPoint;
    vec3 normalizedLightDir = normalize(lightVec);

    float distanceToLightSq = dot(lightVec, lightVec);
    float attenuation = 1.0 / (1.0 + 0.1 * distanceToLightSq);

    float lightFactor = calculateShadow(hitPoint, N);
    float diffuseIntensity = max(0.0, dot(N, normalizedLightDir));

    vec3 ambientColor = vec3(AMBIENT_INTENSITY);
    if (hit.objectID == PLANE_ID) {
        ambientColor = mix(vec3(AMBIENT_INTENSITY * 0.5), SKY_HORIZON_COLOR * 0.7, 0.9);
    }

    return hit.material.diffuseColor * (ambientColor + diffuseIntensity * lightFactor * attenuation * 3.0);
}
