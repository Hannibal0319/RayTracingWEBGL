// --- Ray Tracing Logic ---

vec3 traceRay(vec3 rayOrigin, vec3 rayDir) {
    vec3 accumulatedColor = vec3(0.0);
    vec3 currentRayOrigin = rayOrigin;
    vec3 currentRayDir = rayDir;
    float totalWeight = 1.0;

    for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce) {
        float t_light = intersectSphere(currentRayOrigin, currentRayDir, u_lightSphereCenter, u_lightSphereRadius);
        if (t_light > EPSILON) {
            accumulatedColor += totalWeight * LIGHT_EMISSION;
            break;
        }

        HitRecord hit = findClosestHit(currentRayOrigin, currentRayDir);

        if (hit.t < 0.0) {
            accumulatedColor += totalWeight * getSkyColor(currentRayDir);
            break;
        }

        vec3 hitPoint = currentRayOrigin + currentRayDir * hit.t;
        vec3 localColor = shade(hit, currentRayOrigin, currentRayDir);
        accumulatedColor += totalWeight * localColor * (1.0 - hit.material.reflectivity);
        totalWeight *= hit.material.reflectivity;

        if (totalWeight < 0.01) break;

        vec3 nextRayDir;
        if (hit.material.materialType == REFRACTIVE) {
            float n1 = 1.0, n2 = hit.material.ior;
            vec3 N = hit.normal;
            if (dot(hit.normal, currentRayDir) > 0.0) {
                n1 = hit.material.ior;
                n2 = 1.0;
                N = -N;
            }
            vec3 refractedDir = refract(currentRayDir, N, n1 / n2);
            nextRayDir = length(refractedDir) < EPSILON ? reflect(currentRayDir, N) : refractedDir;
        } else if (hit.material.materialType == REFLECTIVE) {
            nextRayDir = reflect(currentRayDir, hit.normal);
        } else { // Lambertian
            // For a purely lambertian surface, we would ideally do diffuse reflection.
            // For this simplified model, we'll just stop bouncing for non-reflective/refractive surfaces.
            break;
        }
        
        currentRayDir = nextRayDir;
        currentRayOrigin = hitPoint + currentRayDir * EPSILON;
    }
    return accumulatedColor;
}
