// --- Intersection Functions ---

bool intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return tNear < tFar && tFar > 0.0;
}

float intersectSphere(vec3 rayOrigin, vec3 rayDir, vec3 center, float radius) {
    vec3 oc = rayOrigin - center;
    float a = dot(rayDir, rayDir);
    float b = 2.0 * dot(oc, rayDir);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return -1.0;
    float t0 = (-b - sqrt(discriminant)) / (2.0 * a);
    float t1 = (-b + sqrt(discriminant)) / (2.0 * a);

    if (t0 > EPSILON) return t0;
    if (t1 > EPSILON) return t1;
    
    return -1.0;
}

float intersectQuad(vec3 rayOrigin, vec3 rayDir, vec3 Q, vec3 u, vec3 v, vec3 normal) {
    float denom = dot(normal, rayDir);

    // Ray is parallel to the quad plane
    if (abs(denom) < EPSILON) {
        return -1.0;
    }

    // Find intersection point t
    float t = dot(Q - rayOrigin, normal) / denom;
    if (t <= EPSILON) {
        return -1.0;
    }

    // Check if the hit point is within the quad boundaries
    vec3 hitPoint = rayOrigin + t * rayDir;
    vec3 d = hitPoint - Q;

    float dot_u = dot(d, u);
    float dot_v = dot(d, v);

    if (dot_u >= 0.0 && dot_u <= dot(u, u) && dot_v >= 0.0 && dot_v <= dot(v, v)) {
        return t;
    }

    return -1.0;
}

float intersectPlane(vec3 rayOrigin, vec3 rayDir, float planeY) {
    if (abs(rayDir.y) < EPSILON) return -1.0;
    float t = (planeY - rayOrigin.y) / rayDir.y;
    return t > EPSILON ? t : -1.0;
}
