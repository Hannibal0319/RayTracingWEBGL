// --- Scene Traversal ---

const float TRI_ROWS = 6.0; // rows per triangle in texture
const int BVH_STACK_SIZE = 64; // explicit stack for non-recursive traversal

vec3 triTexFetch(int triIndex, int row) {
    int width = int(u_triTexSize.x + 0.5);
    int block = triIndex / width;
    int col = triIndex - block * width;
    int texRow = block * int(TRI_ROWS) + row;
    vec2 uv = vec2((float(col) + 0.5) / u_triTexSize.x, (float(texRow) + 0.5) / u_triTexSize.y);
    vec4 texel = texture2D(u_triTex, uv);
    return texel.xyz;
}

// Local AABB intersection helper using precomputed inverse direction
bool bvhIntersectAABB(vec3 rayOrigin, vec3 invRayDir, vec3 boxMin, vec3 boxMax, out float tNear, out float tFar) {
    vec3 tMin = (boxMin - rayOrigin) * invRayDir;
    vec3 tMax = (boxMax - rayOrigin) * invRayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    tNear = max(max(t1.x, t1.y), t1.z);
    tFar = min(min(t2.x, t2.y), t2.z);
    return tNear < tFar && tFar > 0.0;
}

struct BVHNodeData {
    vec3 bmin;
    vec3 bmax;
    int childOrFirst;
    int childOrCount;
    bool leaf;
};

BVHNodeData fetchNode(int idx) {
    int width = int(u_bvhTexSize.x + 0.5);
    int row = idx / width;
    int col = idx - row * width;
    vec2 uv = vec2((float(col) + 0.5) / u_bvhTexSize.x, (float(row) + 0.5) / u_bvhTexSize.y);
    vec4 t0 = texture2D(u_bvhTex0, uv);
    vec4 t1 = texture2D(u_bvhTex1, uv);
    vec4 t2 = texture2D(u_bvhTex2, uv);
    BVHNodeData n;
    n.bmin = t0.xyz;
    n.bmax = t1.xyz;
    n.childOrFirst = int(t0.w + 0.5);
    n.childOrCount = int(t1.w + 0.5);
    n.leaf = t2.x > 0.5;
    return n;
}

void fetchTriangleData(int triIndex, out vec3 v0, out vec3 e1, out vec3 e2, out vec3 diffuse, out vec3 info, out vec3 emission) {
    v0 = triTexFetch(triIndex, 0);
    e1 = triTexFetch(triIndex, 1);
    e2 = triTexFetch(triIndex, 2);
    diffuse = triTexFetch(triIndex, 3);
    info = triTexFetch(triIndex, 4);
    emission = triTexFetch(triIndex, 5);
}

struct TriHitData {
    float t;
    vec3 normal;
    vec3 diffuse;
    vec3 info;
    vec3 emission;
    int triIndex;
};

vec3 makeSafeDir(vec3 d) {
    return vec3(
        (d.x > 0.0) ? max(d.x, 1e-6) : min(d.x, -1e-6),
        (d.y > 0.0) ? max(d.y, 1e-6) : min(d.y, -1e-6),
        (d.z > 0.0) ? max(d.z, 1e-6) : min(d.z, -1e-6)
    );
}

TriHitData traverseBVHClosest(vec3 rayOrigin, vec3 rayDir, float maxDist) {
    TriHitData hit;
    hit.t = -1.0;
    if (u_bvhNodeCount <= 0) return hit;

    vec3 invRayDir = 1.0 / makeSafeDir(rayDir);

    int stack[BVH_STACK_SIZE];
    int sp = 0;
    int nodeIdx = u_bvhNodeCount - 1; // root is appended last on CPU

    for (int iter = 0; iter < MAX_BVH_NODES; ++iter) {
        if (nodeIdx < 0) {
            if (sp == 0) break;
            nodeIdx = stack[--sp];
            continue;
        }

        BVHNodeData node = fetchNode(nodeIdx);
        float tNear; float tFar;
        bool hitAABB = bvhIntersectAABB(rayOrigin, invRayDir, node.bmin, node.bmax, tNear, tFar);

        if (!hitAABB || tNear > maxDist || (hit.t > 0.0 && tNear > hit.t)) {
            nodeIdx = (sp > 0) ? stack[--sp] : -1;
            continue;
        }

        if (node.leaf) {
            for (int j = 0; j < 32; ++j) {
                if (j >= node.childOrCount) break;
                int triIndex = node.childOrFirst + j;
                vec3 v0, e1, e2, diff, info, emit;
                fetchTriangleData(triIndex, v0, e1, e2, diff, info, emit);
                float t = intersectTriangle(rayOrigin, rayDir, v0, e1, e2);
                if (t > EPSILON && t < maxDist && (hit.t < 0.0 || t < hit.t)) {
                    hit.t = t;
                    hit.triIndex = triIndex;
                    hit.diffuse = diff;
                    hit.info = info;
                    hit.emission = emit;
                    vec3 n = normalize(cross(e1, e2));
                    if (dot(n, rayDir) > 0.0) n = -n;
                    hit.normal = n;
                    maxDist = t;
                }
            }
            nodeIdx = (sp > 0) ? stack[--sp] : -1;
        } else {
            if (sp <= BVH_STACK_SIZE - 2) {
                stack[sp++] = node.childOrCount; // right
                stack[sp++] = node.childOrFirst; // left
            }
            nodeIdx = (sp > 0) ? stack[--sp] : -1;
        }
    }

    return hit;
}

bool bvhAnyHit(vec3 rayOrigin, vec3 rayDir, float maxDist, bool ignoreEmissive, int skipTriIndex) {
    if (u_bvhNodeCount <= 0) return false;

    vec3 invRayDir = 1.0 / makeSafeDir(rayDir);

    int stack[BVH_STACK_SIZE];
    int sp = 0;
    int nodeIdx = u_bvhNodeCount - 1;

    for (int iter = 0; iter < MAX_BVH_NODES; ++iter) {
        if (nodeIdx < 0) {
            if (sp == 0) break;
            nodeIdx = stack[--sp];
            continue;
        }

        BVHNodeData node = fetchNode(nodeIdx);
        float tNear; float tFar;
        bool hitAABB = bvhIntersectAABB(rayOrigin, invRayDir, node.bmin, node.bmax, tNear, tFar);
        if (!hitAABB || tNear > maxDist) {
            nodeIdx = (sp > 0) ? stack[--sp] : -1;
            continue;
        }

        if (node.leaf) {
            for (int j = 0; j < 32; ++j) {
                if (j >= node.childOrCount) break;
                int triIndex = node.childOrFirst + j;
                if (triIndex == skipTriIndex) continue;
                vec3 v0, e1, e2, diff, info, emit;
                fetchTriangleData(triIndex, v0, e1, e2, diff, info, emit);
                int matType = int(info.b + 0.5);
                if (ignoreEmissive && matType == EMISSIVE) continue;
                float t = intersectTriangle(rayOrigin, rayDir, v0, e1, e2);
                if (t > EPSILON && t < maxDist) {
                    return true;
                }
            }
            nodeIdx = (sp > 0) ? stack[--sp] : -1;
        } else {
            if (sp <= BVH_STACK_SIZE - 2) {
                stack[sp++] = node.childOrCount;
                stack[sp++] = node.childOrFirst;
            }
            nodeIdx = (sp > 0) ? stack[--sp] : -1;
        }
    }

    return false;
}

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
            closestHit.material.emissiveColor = u_sphereEmissionColors[i];
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
            closestHit.material.emissiveColor = u_quadEmissionColors[i];
        }
    }

    // Check Triangles via BVH
    if (u_triangleCount > 0) {
        float triMax = (closestHit.t > 0.0) ? closestHit.t : 1e9;
        TriHitData triHit = traverseBVHClosest(rayOrigin, rayDir, triMax);
        if (triHit.t > EPSILON && (closestHit.t < 0.0 || triHit.t < closestHit.t)) {
            closestHit.t = triHit.t;
            closestHit.objectID = triHit.triIndex + u_sphereCount + u_quadCount;
            closestHit.normal = triHit.normal;
            closestHit.material.diffuseColor = triHit.diffuse;
            closestHit.material.reflectivity = triHit.info.r;
            closestHit.material.ior = triHit.info.g;
            closestHit.material.materialType = int(triHit.info.b + 0.5);
            closestHit.material.emissiveColor = triHit.emission;
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
        closestHit.material.emissiveColor = vec3(0.0);

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

    // No directional sun; simple sky gradient
    return missedColor;
}
