// --- Scene Traversal ---

HitRecord findClosestHit(vec3 rayOrigin, vec3 rayDir) {
    HitRecord closestHit;
    closestHit.t = -1.0;

    // Check Scene Spheres
    for (int i = 0; i < MAX_SPHERES; ++i) {
        if (i >= u_sphereCount) break; // Safety break
        float t = intersectSphere(rayOrigin, rayDir, u_sphereCenters[i], u_sphereRadii[i]);
        if (t > EPSILON && (closestHit.t < 0.0 || t < closestHit.t)) {
            closestHit.t = t;
            closestHit.objectID = i;
            vec3 hitPoint = rayOrigin + rayDir * t;
                closestHit.normal = normalize(hitPoint - u_sphereCenters[i]);
            closestHit.material.diffuseColor = u_sphereDiffuseColors[i];
            closestHit.material.reflectivity = u_sphereReflectivity[i];
            closestHit.material.ior = u_sphereIOR[i];
            closestHit.material.materialType = u_sphereMaterialTypes[i];
        }
    }

    // Check Quads
    for (int i = 0; i < MAX_QUADS; ++i) {
        if (i >= u_quadCount) break;
        float t = intersectQuad(rayOrigin, rayDir, u_quadCorners[i], u_quadU[i], u_quadV[i], u_quadNormals[i]);
        if (t > EPSILON && (closestHit.t < 0.0 || t < closestHit.t)) {
            closestHit.t = t;
            closestHit.objectID = i + u_sphereCount; // Offset by sphere count

            vec3 n = u_quadNormals[i];
            if (dot(n, rayDir) > 0.0) {
                n = -n;
            }    
            closestHit.normal = n;
            closestHit.material.diffuseColor = u_quadDiffuseColors[i];
            closestHit.material.reflectivity = u_quadReflectivity[i];
            closestHit.material.ior = u_quadIOR[i];
            closestHit.material.materialType = u_quadMaterialTypes[i];
        }
    }

    // Check Triangles
    for (int i = 0; i < MAX_TRIANGLES; ++i) {
        if (i >= u_triangleCount) break;
        float t = intersectTriangle(rayOrigin, rayDir, u_triangleV0[i], u_triangleE1[i], u_triangleE2[i]);
        if (t > EPSILON && (closestHit.t < 0.0 || t < closestHit.t)) {
            closestHit.t = t;
            closestHit.objectID = i + u_sphereCount + u_quadCount; // Offset by spheres and quads

            vec3 n = u_triangleNormals[i];
            if (dot(n, rayDir) > 0.0) {
                n = -n;
            }
            closestHit.normal = n;
            closestHit.material.diffuseColor = u_triangleDiffuseColors[i];
            closestHit.material.reflectivity = u_triangleReflectivity[i];
            closestHit.material.ior = u_triangleIOR[i];
            closestHit.material.materialType = u_triangleMaterialTypes[i];
        }
    }

    // Check Plane
    float t_plane = intersectPlane(rayOrigin, rayDir, u_planeY);
    if (t_plane > EPSILON && (closestHit.t < 0.0 || t_plane < closestHit.t)) {
        closestHit.t = t_plane;
        closestHit.objectID = PLANE_ID;
        vec3 hitPoint = rayOrigin + rayDir * t_plane;
        closestHit.normal = vec3(0.0, 1.0, 0.0);
        closestHit.material.reflectivity = 0.0;
        closestHit.material.ior = 1.0;
        closestHit.material.materialType = LAMBERTIAN;

        float checkSize = 1.0;
        vec2 coords = hitPoint.xz / checkSize;
        float checker = mod(floor(coords.x) + floor(coords.y), 2.0);
        closestHit.material.diffuseColor = mix(u_planeColorA, u_planeColorB, checker);
    }

    return closestHit;
}

vec3 getSkyColor(vec3 rayDir) {
    float skyFactor = max(0.0, rayDir.y);
    vec3 missedColor = mix(SKY_HORIZON_COLOR, SKY_ZENITH_COLOR, skyFactor);

    vec3 lightPosNormalized = normalize(u_lightSphereCenter);
    float illuminationFactor = max(0.0, dot(-rayDir, lightPosNormalized));
    float scatter = pow(illuminationFactor, 5.0) * 0.5;
    float glow = pow(illuminationFactor, 25.0) * 1.0;

    missedColor = mix(missedColor, LIGHT_EMISSION * 0.3, scatter);
    missedColor = mix(missedColor, LIGHT_EMISSION * 1.0, glow);
    return missedColor;
}
