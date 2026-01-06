// --- Ray Tracing Logic ---

vec3 traceRay(vec3 rayOrigin, vec3 rayDir) {
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
        // For refractive hits we defer shading to transmission; otherwise accumulate local
        vec3 localColor = (hit.material.materialType == REFRACTIVE) ? vec3(0.0) : shade(hit, currentRayOrigin, currentRayDir);
        accumulatedColor += totalWeight * localColor * (1.0 - hit.material.reflectivity);

        vec3 baseTint = hit.material.diffuseColor;
        float baseReflect = clamp(hit.material.reflectivity, 0.0, 0.99);

        if (totalWeight.x < 0.01 && totalWeight.y < 0.01 && totalWeight.z < 0.01) break;

        vec3 nextRayDir;
        if (hit.material.materialType == REFRACTIVE) {
            float n1 = 1.0, n2 = hit.material.ior;
            vec3 N = hit.normal;
            float cosI = dot(N, -currentRayDir);
            bool exiting = cosI < 0.0;
            if (exiting) {
                N = -N;
                cosI = -cosI;
                n1 = hit.material.ior;
                n2 = 1.0;
            }
            float eta = n1 / n2;
            vec3 refractedDir = refract(currentRayDir, N, eta);

            float R0 = pow((n1 - n2) / (n1 + n2), 2.0);
            float fresnel = R0 + (1.0 - R0) * pow(1.0 - cosI, 5.0);
            fresnel = clamp(fresnel, 0.08, 0.98); // favor reflection at grazing to avoid see-through rims
            if (length(refractedDir) < EPSILON) {
                fresnel = 1.0; // total internal reflection
            }

            float r = random(gl_FragCoord.xy + vec2(float(bounce), totalWeight.x + totalWeight.y + totalWeight.z));
            if (r < fresnel) {
                nextRayDir = reflect(currentRayDir, N);
                totalWeight *= baseTint * (1.0 / max(fresnel, 1e-3));
            } else {
                nextRayDir = normalize(refractedDir);
                totalWeight *= baseTint * (1.0 / max(1.0 - fresnel, 1e-3));
            }
        } else if (hit.material.materialType == REFLECTIVE) {
            nextRayDir = reflect(currentRayDir, hit.normal);
            totalWeight *= baseTint * baseReflect;
        } else { // Lambertian
            nextRayDir = cosineSampleHemisphere(hit.normal);
            totalWeight *= baseTint * baseReflect;
        }
        // Clamp throughput to avoid exploding values and guard against NaNs/Infs
        totalWeight = clamp(totalWeight, vec3(0.0), vec3(10.0));
        if (any(isnan(totalWeight)) || any(isinf(totalWeight))) break;

        currentRayDir = normalize(nextRayDir);
        float offset = (hit.material.materialType == REFRACTIVE) ? EPSILON * 8.0 : EPSILON * 2.0;
        currentRayOrigin = hitPoint + currentRayDir * offset;
    }
    return accumulatedColor;
}

