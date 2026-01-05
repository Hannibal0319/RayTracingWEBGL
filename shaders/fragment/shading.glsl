// --- Shading Functions ---

// Accumulate direct lighting from emissive spheres with simple point-sphere attenuation and visibility.
vec3 accumulateEmissiveLights(vec3 hitPoint, vec3 N, int hitObjectID) {
    vec3 result = vec3(0.0);

    // Sphere emitters
    for (int i = 0; i < MAX_SPHERES; ++i) {
        if (i >= u_sphereCount) break;
        if (u_sphereMaterialTypes[i] != EMISSIVE) continue;
        if (i == hitObjectID) continue; // avoid self-lighting

        vec3 lightVec = u_sphereCenters[i] - hitPoint;
        float distSq = dot(lightVec, lightVec);
        float dist = sqrt(distSq);
        vec3 L = lightVec / dist;

        float ndotl = max(0.0, dot(N, L));
        if (ndotl <= 0.0) continue;

        // Shadow check
        vec3 shadowOrigin = hitPoint + N * EPSILON * 4.0;
        float maxT = dist - u_sphereRadii[i];

        bool blocked = false;
        // spheres
        for (int s = 0; s < MAX_SPHERES; ++s) {
            if (s >= u_sphereCount) break;
            if (s == i) continue; // allow hitting the light itself
            if (u_sphereMaterialTypes[s] == EMISSIVE) continue; // emitters do not cast shadows
            float t = intersectSphere(shadowOrigin, L, u_sphereCenters[s], u_sphereRadii[s]);
            if (t > EPSILON && t < maxT) { blocked = true; break; }
        }
        // quads
        if (!blocked) {
            for (int q = 0; q < MAX_QUADS; ++q) {
                if (q >= u_quadCount) break;
                if (u_quadMaterialTypes[q] == EMISSIVE) continue;
                float t = intersectQuad(shadowOrigin, L, u_quadCorners[q], u_quadU[q], u_quadV[q], u_quadNormals[q]);
                if (t > EPSILON && t < maxT) { blocked = true; break; }
            }
        }
        // triangles
        if (!blocked) {
            for (int tIdx = 0; tIdx < MAX_TRIANGLES; ++tIdx) {
                if (tIdx >= u_triangleCount) break;
                if (u_triangleMaterialTypes[tIdx] == EMISSIVE) continue;
                float t = intersectTriangle(shadowOrigin, L, u_triangleV0[tIdx], u_triangleE1[tIdx], u_triangleE2[tIdx]);
                if (t > EPSILON && t < maxT) { blocked = true; break; }
            }
        }

        if (blocked) continue;

        // Simple inverse-square attenuation, clamp to avoid huge values when very close
        float attenuation = 1.0 / max(1.0, distSq);
        result += u_sphereEmissionColors[i] * ndotl * attenuation;
    }

    // Quad emitters (sample multiple points to avoid point-light look, two-sided)
    for (int i = 0; i < MAX_QUADS; ++i) {
        if (i >= u_quadCount) break;
        if (u_quadMaterialTypes[i] != EMISSIVE) continue;
        int quadObjectID = i + u_sphereCount;
        if (quadObjectID == hitObjectID) continue;

        vec3 p0 = u_quadCorners[i];
        vec3 p1 = u_quadCorners[i] + u_quadU[i];
        vec3 p2 = u_quadCorners[i] + u_quadV[i];
        vec3 p3 = p1 + u_quadV[i];
        vec3 pC = (p0 + p1 + p2 + p3) * 0.25;

        vec3 lightVec = pC - hitPoint;
            float distSq = dot(lightVec, lightVec);
            float dist = sqrt(distSq);
            vec3 L = lightVec / dist;

            float ndotl = abs(dot(N, L));
            if (ndotl <= 0.0) continue;

            vec3 shadowOrigin = hitPoint + N * EPSILON * 4.0;
            float maxT = dist;

            bool blocked = false;
            // spheres
            for (int s = 0; s < MAX_SPHERES; ++s) {
                if (s >= u_sphereCount) break;
                if (u_sphereMaterialTypes[s] == EMISSIVE) continue;
                float t = intersectSphere(shadowOrigin, L, u_sphereCenters[s], u_sphereRadii[s]);
                if (t > EPSILON && t < maxT) { blocked = true; break; }
            }
            // quads
            if (!blocked) {
                for (int q = 0; q < MAX_QUADS; ++q) {
                    if (q >= u_quadCount) break;
                    if (q == i) continue; // allow hitting the light itself
                    if (u_quadMaterialTypes[q] == EMISSIVE) continue;
                    float t = intersectQuad(shadowOrigin, L, u_quadCorners[q], u_quadU[q], u_quadV[q], u_quadNormals[q]);
                    if (t > EPSILON && t < maxT) { blocked = true; break; }
                }
            }
            // triangles
            if (!blocked) {
                for (int tIdx = 0; tIdx < MAX_TRIANGLES; ++tIdx) {
                    if (tIdx >= u_triangleCount) break;
                    if (u_triangleMaterialTypes[tIdx] == EMISSIVE) continue;
                    float t = intersectTriangle(shadowOrigin, L, u_triangleV0[tIdx], u_triangleE1[tIdx], u_triangleE2[tIdx]);
                    if (t > EPSILON && t < maxT) { blocked = true; break; }
                }
            }

            if (blocked) continue;

            float attenuation = 1.0 / max(1.0, distSq);
            result += u_quadEmissionColors[i] * ndotl * attenuation;
    }

    // Triangle emitters (sample at triangle centroid, two-sided)
    for (int i = 0; i < MAX_TRIANGLES; ++i) {
        if (i >= u_triangleCount) break;
        if (u_triangleMaterialTypes[i] != EMISSIVE) continue;
        int triObjectID = i + u_sphereCount + u_quadCount;
        if (triObjectID == hitObjectID) continue;

        vec3 triCenter = u_triangleV0[i] + 0.5 * u_triangleE1[i] + 0.5 * u_triangleE2[i];
        vec3 lightVec = triCenter - hitPoint;
        float distSq = dot(lightVec, lightVec);
        float dist = sqrt(distSq);
        vec3 L = lightVec / dist;

        float ndotl = abs(dot(N, L));
        if (ndotl <= 0.0) continue;

        vec3 shadowOrigin = hitPoint + N * EPSILON * 4.0;
        float maxT = dist;

        bool blocked = false;
        // spheres
        for (int s = 0; s < MAX_SPHERES; ++s) {
            if (s >= u_sphereCount) break;
            if (u_sphereMaterialTypes[s] == EMISSIVE) continue;
            float t = intersectSphere(shadowOrigin, L, u_sphereCenters[s], u_sphereRadii[s]);
            if (t > EPSILON && t < maxT) { blocked = true; break; }
        }
        // quads
        if (!blocked) {
            for (int q = 0; q < MAX_QUADS; ++q) {
                if (q >= u_quadCount) break;
                if (u_quadMaterialTypes[q] == EMISSIVE) continue;
                float t = intersectQuad(shadowOrigin, L, u_quadCorners[q], u_quadU[q], u_quadV[q], u_quadNormals[q]);
                if (t > EPSILON && t < maxT) { blocked = true; break; }
            }
        }
        // triangles
        if (!blocked) {
            for (int tIdx = 0; tIdx < MAX_TRIANGLES; ++tIdx) {
                if (tIdx >= u_triangleCount) break;
                if (tIdx == i) continue; // allow hitting the light itself
                if (u_triangleMaterialTypes[tIdx] == EMISSIVE) continue;
                float t = intersectTriangle(shadowOrigin, L, u_triangleV0[tIdx], u_triangleE1[tIdx], u_triangleE2[tIdx]);
                if (t > EPSILON && t < maxT) { blocked = true; break; }
            }
        }

        if (blocked) continue;

        float attenuation = 1.0 / max(1.0, distSq);
        result += u_triangleEmissionColors[i] * ndotl * attenuation;
    }

    return result;
}

vec3 shade(HitRecord hit, vec3 rayOrigin, vec3 rayDir) {
    if (hit.material.materialType == EMISSIVE) {
        return hit.material.emissiveColor;
    }
    
    // For reflective, refractive, and metallic materials, no local shading
    if (hit.material.materialType == REFLECTIVE || 
        hit.material.materialType == REFRACTIVE || 
        hit.material.materialType == METALLIC_ROUGHNESS) {
        return vec3(0.0);
    }
    
    // Use a shading normal that faces the incoming ray to avoid black backfaces,
    // while keeping the geometric normal in hit.normal for refraction logic.
    vec3 N = dot(hit.normal, rayDir) > 0.0 ? -hit.normal : hit.normal;

    int sphereEnd = u_sphereCount;
    int quadEnd = sphereEnd + u_quadCount;
    int triEnd = quadEnd + u_triangleCount;
    bool isQuad = hit.objectID >= sphereEnd && hit.objectID < quadEnd;
    bool isTriangle = hit.objectID >= quadEnd && hit.objectID < triEnd;
    bool isPlane = hit.objectID == PLANE_ID;
    bool isSphere = hit.objectID < sphereEnd;

    vec3 ambientColor = vec3(AMBIENT_INTENSITY);
    if (isPlane) {
        ambientColor = mix(vec3(AMBIENT_INTENSITY * 0.5), SKY_HORIZON_COLOR * 0.7, 0.9);
    } 
    else if (isQuad || isTriangle) {
        // Polygonal surfaces get standard ambient
        ambientColor = hit.material.diffuseColor * AMBIENT_INTENSITY;
    }
    else if (isSphere) {
        // Spheres get standard ambient
        ambientColor = hit.material.diffuseColor * AMBIENT_INTENSITY;
    }

    // Give polygonal surfaces a tiny emissive lift to stay visible when nearly edge-on
    vec3 emissiveBoost = (isQuad || isTriangle) ? hit.material.diffuseColor * 0.05 : vec3(0.0);

    vec3 emissiveLighting = accumulateEmissiveLights(rayOrigin + rayDir * hit.t, N, hit.objectID);

    return hit.material.diffuseColor * ambientColor + emissiveLighting + emissiveBoost;
}
