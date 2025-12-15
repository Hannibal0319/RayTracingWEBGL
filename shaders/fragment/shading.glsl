// --- Shading Functions ---

float calculateShadow(vec3 hitPoint, vec3 N) {
    vec3 lightVec = u_lightSphereCenter - hitPoint;
    vec3 shadowRayDir = normalize(lightVec);
    float distanceToLight = length(lightVec);
    vec3 shadowRayOrigin = hitPoint + N * EPSILON * 5.0;

    // Corrected Loop for Spheres
    for (int i = 0; i < MAX_SPHERES; ++i) {
        if (i >= u_sphereCount) break; // Check against uniform inside the loop
        float t = intersectSphere(shadowRayOrigin, shadowRayDir, u_sphereCenters[i], u_sphereRadii[i]);
        if (t > EPSILON && t < distanceToLight) {
            return 0.2; // Shadowed
        }
    }

    // Corrected Loop for Quads
    for (int i = 0; i < MAX_QUADS; ++i) {
        if (i >= u_quadCount) break; // Check against uniform inside the loop
        float t = intersectQuad(shadowRayOrigin, shadowRayDir, u_quadCorners[i], u_quadU[i], u_quadV[i], u_quadNormals[i]);
        if (t > EPSILON && t < distanceToLight) {
            return 0.2; // Shadowed
        }
    }

    return 1.0; // Lit
}

vec3 shade(HitRecord hit, vec3 rayOrigin, vec3 rayDir) {
    vec3 hitPoint = rayOrigin + rayDir * hit.t;
    // Use a shading normal that faces the incoming ray to avoid black backfaces,
    // while keeping the geometric normal in hit.normal for refraction logic.
    vec3 N = dot(hit.normal, rayDir) > 0.0 ? -hit.normal : hit.normal;

    vec3 lightVec = u_lightSphereCenter - hitPoint;
    vec3 normalizedLightDir = normalize(lightVec);

    float distanceToLightSq = dot(lightVec, lightVec);
    float attenuation = 1.0 / (1.0 + 0.1 * distanceToLightSq);

    float lightFactor = calculateShadow(hitPoint, N);
    float ndotl = dot(N, normalizedLightDir);
    // Make quads two-sided and give them stronger baseline light so vertical walls remain visible
    float diffuseIntensity = (hit.objectID >= u_sphereCount && hit.objectID < u_sphereCount + u_quadCount)
        ? max(0.4, abs(ndotl))
        : max(0.0, ndotl);

    vec3 ambientColor = vec3(AMBIENT_INTENSITY);
    // Check if the hit object is the plane
    if (hit.objectID == PLANE_ID) {
        ambientColor = mix(vec3(AMBIENT_INTENSITY * 0.5), SKY_HORIZON_COLOR * 0.7, 0.9);
    } 
    else if (hit.objectID >= u_sphereCount) {
        // This is a quad, apply standard ambient
        ambientColor = hit.material.diffuseColor * AMBIENT_INTENSITY;
    }
    else {
        // This is a sphere, apply standard ambient
        ambientColor = hit.material.diffuseColor * AMBIENT_INTENSITY;
    }

    // Give quads a tiny emissive lift to stay visible when nearly edge-on
    vec3 emissiveBoost = (hit.objectID >= u_sphereCount && hit.objectID < u_sphereCount + u_quadCount)
        ? hit.material.diffuseColor * 0.1
        : vec3(0.0);

    return hit.material.diffuseColor * (ambientColor + diffuseIntensity * lightFactor * attenuation * 3.0) + emissiveBoost;
}
