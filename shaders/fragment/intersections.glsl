// --- Intersection Functions ---

vec3 makeSafeDir(vec3 d) {
    return vec3(
        (d.x > 0.0) ? max(d.x, 1e-6) : min(d.x, -1e-6),
        (d.y > 0.0) ? max(d.y, 1e-6) : min(d.y, -1e-6),
        (d.z > 0.0) ? max(d.z, 1e-6) : min(d.z, -1e-6)
    );
}
/*
bool intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 invRayDir = 1.0 / makeSafeDir(rayDir);
    vec3 tMin = (boxMin - rayOrigin) * invRayDir;
    vec3 tMax = (boxMax - rayOrigin) * invRayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return tNear < tFar && tFar > 0.0;
}

bool intersectAABBWithT(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax, out float tNear, out float tFar) {
    vec3 invRayDir = 1.0 / makeSafeDir(rayDir);
    vec3 tMin = (boxMin - rayOrigin) * invRayDir;
    vec3 tMax = (boxMax - rayOrigin) * invRayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    tNear = max(max(t1.x, t1.y), t1.z);
    tFar = min(min(t2.x, t2.y), t2.z);
    return tNear < tFar && tFar > 0.0;
}
*/
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
    vec3 N = normal; // Use a local copy of the normal
    float denom = dot(N, rayDir);

    // If the ray is hitting from behind, flip the normal
    if (denom > 0.0) {
        N = -N;
        denom = -denom;
    }

    // Ray is parallel to the quad plane
    if (abs(denom) < EPSILON) {
        return -1.0;
    }

    // Find intersection point t
    float t = dot(Q - rayOrigin, N) / denom;
    if (t <= EPSILON) {
        return -1.0;
    }

    // Check if the hit point is within the quad boundaries
    vec3 hitPoint = rayOrigin + t * rayDir;
    vec3 d = hitPoint - Q;

    float dot_u = dot(d, u);
    float dot_v = dot(d, v);
    float uu = dot(u, u);
    float vv = dot(v, v);

    // Allow a small tolerance so nearly parallel rays still register hits on edges
    if (dot_u >= -EPSILON && dot_u <= uu + EPSILON && dot_v >= -EPSILON && dot_v <= vv + EPSILON) {
        return t;
    }

    return -1.0;
}

float intersectTriangle(vec3 rayOrigin, vec3 rayDir, vec3 v0, vec3 e1, vec3 e2) {
    vec3 pvec = cross(rayDir, e2);
    float det = dot(e1, pvec);

    if (abs(det) < EPSILON) return -1.0; // Ray parallel to triangle

    float invDet = 1.0 / det;
    vec3 tvec = rayOrigin - v0;
    float u = dot(tvec, pvec) * invDet;
    if (u < -EPSILON || u > 1.0 + EPSILON) return -1.0;

    vec3 qvec = cross(tvec, e1);
    float v = dot(rayDir, qvec) * invDet;
    if (v < -EPSILON || (u + v) > 1.0 + EPSILON) return -1.0;

    float t = dot(e2, qvec) * invDet;
    return t > EPSILON ? t : -1.0;
}

float intersectPlane(vec3 rayOrigin, vec3 rayDir, float planeY) {
    if (abs(rayDir.y) < EPSILON) return -1.0;
    float t = (planeY - rayOrigin.y) / rayDir.y;
    return t > EPSILON ? t : -1.0;
}
