// --- Scene Traversal ---

HitRecord findClosestHit(vec3 rayOrigin, vec3 rayDir) {
    HitRecord closestHit;
    closestHit.t = -1.0;

    // Check Scene Spheres
    for (int i = 0; i < MAX_SPHERES; ++i) {
        if (i >= u_sphereCount) break; // Safety break
        if (intersectAABB(rayOrigin, rayDir, u_sphereAABB_min[i], u_sphereAABB_max[i])) {
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
