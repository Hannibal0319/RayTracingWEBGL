// --- Ray Tracing Logic ---

vec3 traceRay(vec3 rayOrigin, vec3 rayDir, float time) {
    vec3 accumulatedColor = vec3(0.0);
    vec3 currentRayOrigin = rayOrigin;
    vec3 currentRayDir = rayDir;
    vec3 totalWeight = vec3(1.0);

    for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce) {
        HitRecord hit = findClosestHit(currentRayOrigin, currentRayDir);

        if (hit.t < 0.0) {
            accumulatedColor += totalWeight * getSkyColor(currentRayDir);
            break;
        }

        if (hit.material.materialType == EMISSIVE) {
            accumulatedColor += totalWeight * hit.material.emissiveColor;
            break;
        }

        vec3 hitPoint = currentRayOrigin + currentRayDir * hit.t;
        vec3 localColor = shade(hit, currentRayOrigin, currentRayDir);
        accumulatedColor += totalWeight * localColor * (1.0 - hit.material.reflectivity);// * dot(hit.normal, currentRayDir) * -1.0;
        
        // For reflective materials, tint the totalWeight by the material color
        if (hit.material.materialType == REFLECTIVE) {
            totalWeight *= hit.material.reflectivity * hit.material.diffuseColor;
        } else {
            totalWeight *= hit.material.reflectivity;
        }

        if (totalWeight.x < 0.01 && totalWeight.y < 0.01 && totalWeight.z < 0.01) {break;};

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
            nextRayDir = cosineSampleHemisphere(hit.normal, time);
        }
        
        currentRayDir = nextRayDir;
        currentRayOrigin = hitPoint + currentRayDir * EPSILON;
    }
    return sqrt(accumulatedColor * totalWeight);
}
