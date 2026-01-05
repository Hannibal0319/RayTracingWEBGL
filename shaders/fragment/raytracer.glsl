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
        vec3 localColor = shade(hit, currentRayOrigin, currentRayDir);
        
        // Calculate effective reflectivity
        float effectiveReflectivity = hit.material.reflectivity;
        if (hit.material.materialType == METALLIC_ROUGHNESS) {
            effectiveReflectivity = 1.0;
        }
        
        accumulatedColor += totalWeight * localColor * (1.0 - effectiveReflectivity);
        
        // For reflective materials, tint the totalWeight by the material color
        if (hit.material.materialType == REFLECTIVE) {
            totalWeight *= hit.material.reflectivity * hit.material.diffuseColor;
        } else if (hit.material.materialType == METALLIC_ROUGHNESS) {
            // For metallic materials, use Fresnel-based weighting
            vec3 F0 = mix(vec3(0.04), hit.material.diffuseColor, hit.material.metallic);
            vec3 F = fresnelSchlick(max(dot(hit.normal, -currentRayDir), 0.0), F0);
            totalWeight *= F;
        } else {
            totalWeight *= hit.material.reflectivity;
        }

        if (totalWeight.x < 0.01 && totalWeight.y < 0.01 && totalWeight.z < 0.01) break;

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
        } else if (hit.material.materialType == METALLIC_ROUGHNESS) {
            vec3 V = -currentRayDir; // View direction
            vec3 N = hit.normal;
            
            // Importance sample GGX for specular reflection
            vec2 Xi = vec2(random(gl_FragCoord.xy + vec2(float(bounce), 0.0)), 
                          random(gl_FragCoord.xy + vec2(float(bounce), 1.0)));
            vec3 H = importanceSampleGGX(Xi, N, hit.material.roughness);
            nextRayDir = reflect(currentRayDir, H);
            
            // Ensure the ray is in the correct hemisphere
            if (dot(nextRayDir, N) < 0.0) {
                nextRayDir = reflect(nextRayDir, N);
            }
        } else { // Lambertian
            nextRayDir = cosineSampleHemisphere(hit.normal);
        }
        
        currentRayDir = nextRayDir;
        currentRayOrigin = hitPoint + currentRayDir * EPSILON;
    }
    return accumulatedColor;
}
