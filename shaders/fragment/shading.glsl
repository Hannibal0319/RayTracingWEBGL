// --- Shading Functions ---

void getTriangleData(int idx, out vec3 v0, out vec3 e1, out vec3 e2, out vec3 diffuse, out vec3 emission, out int matType) {
    v0 = triTexFetch(idx, 0);
    e1 = triTexFetch(idx, 1);
    e2 = triTexFetch(idx, 2);
    diffuse = triTexFetch(idx, 3);
    vec3 info = triTexFetch(idx, 4);
    matType = int(info.b + 0.5);
    emission = triTexFetch(idx, 5);
}

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
            blocked = bvhAnyHit(shadowOrigin, L, maxT, true, -1);
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
                blocked = bvhAnyHit(shadowOrigin, L, maxT, true, -1);
            }

            if (blocked) continue;

            float attenuation = 1.0 / max(1.0, distSq);
            result += u_quadEmissionColors[i] * ndotl * attenuation;
    }

    // Triangle emitters (sample at triangle centroid, two-sided)
    for (int i = 0; i < MAX_TRIANGLES; ++i) {
        if (i >= u_triangleCount) break;
        vec3 v0, e1, e2, diff, emit; int mType;
        getTriangleData(i, v0, e1, e2, diff, emit, mType);
        if (mType != EMISSIVE) continue;
        int triObjectID = i + u_sphereCount + u_quadCount;
        if (triObjectID == hitObjectID) continue;

        vec3 triCenter = v0 + 0.5 * e1 + 0.5 * e2;
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
            blocked = bvhAnyHit(shadowOrigin, L, maxT, true, i);
        }

        if (blocked) continue;

        float attenuation = 1.0 / max(1.0, distSq);
        result += emit * ndotl * attenuation;
    }

    return result;
}

vec3 shade(HitRecord hit, vec3 rayOrigin, vec3 rayDir) {
    if (hit.material.materialType == EMISSIVE) {
        return hit.material.emissiveColor;
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

    // Simple ambient only (direct lighting disabled). Keep ambient independent of albedo so we don't double-multiply and darken objects.
    vec3 ambientColor = vec3(AMBIENT_INTENSITY);
    if (isPlane) {
        ambientColor = mix(vec3(AMBIENT_INTENSITY * 0.5), SKY_HORIZON_COLOR * 0.7, 0.9);
    }

    // Give polygonal surfaces a tiny emissive lift to stay visible when nearly edge-on
    vec3 emissiveBoost = (isQuad || isTriangle) ? hit.material.diffuseColor * 0.05 : vec3(0.0);

    vec3 hitPoint = rayOrigin + rayDir * hit.t;
    vec3 emissiveLighting = vec3(0.0); //accumulateEmissiveLights(hitPoint, N, hit.objectID);

    // Sky point light (shadowed)
    vec3 Lp = u_pointLightPos - hitPoint;
    float distSq = dot(Lp, Lp);
    float dist = sqrt(distSq);
    vec3 Ldir = Lp / dist;
    float ndotl = max(0.0, dot(N, Ldir));
    vec3 pointLight = vec3(0.0);
    if (ndotl > 0.0) {
        vec3 shadowOrigin = hitPoint + N * EPSILON * 4.0;
        bool blocked = bvhAnyHit(shadowOrigin, Ldir, dist, true, -1);
        if (!blocked) {
            float attenuation = 1.0 / max(1.0, distSq);
            pointLight = u_pointLightColor * ndotl * attenuation;
        }
    }

    // View-facing fill to keep silhouettes from going black; modulated by albedo
    float viewNdotL = max(0.0, dot(N, -rayDir));
    vec3 viewFill = hit.material.diffuseColor * viewNdotL * 0.35;

    // Apply albedo to direct light
    vec3 lit = hit.material.diffuseColor * (ambientColor + pointLight) + emissiveBoost + emissiveLighting + viewFill;
    return lit;
}
