precision highp float;

// Scene Uniforms
uniform vec2 u_resolution;
uniform vec3 u_lightSphereCenter;
uniform float u_lightSphereRadius;
uniform float u_planeY;
uniform vec3 u_planeColorA;
uniform vec3 u_planeColorB;

// Sphere Data Uniforms
uniform vec3 u_sphereCenters[3];
uniform float u_sphereRadii[3];
uniform vec3 u_sphereAABB_min[3];
uniform vec3 u_sphereAABB_max[3];

// Material Uniforms for Spheres
uniform vec3 u_sphereDiffuseColors[3];
uniform float u_sphereReflectivity[3];
uniform float u_sphereIOR[3];
uniform int u_sphereMaterialTypes[3]; // 0: Lambertian, 1: Reflective, 2: Refractive

// Quad Data Uniforms
const int MAX_QUADS = 10; // Set a max limit for quads
uniform int u_quadCount;
uniform vec3 u_quadCorners[MAX_QUADS];
uniform vec3 u_quadU[MAX_QUADS];
uniform vec3 u_quadV[MAX_QUADS];
uniform vec3 u_quadNormals[MAX_QUADS];
uniform vec3 u_quadAABB_min[MAX_QUADS];
uniform vec3 u_quadAABB_max[MAX_QUADS];

// Material Uniforms for Quads
uniform vec3 u_quadDiffuseColors[MAX_QUADS];
uniform float u_quadReflectivity[MAX_QUADS];
uniform float u_quadIOR[MAX_QUADS];
uniform int u_quadMaterialTypes[MAX_QUADS];

// CAMERA UNIFORMS
uniform vec3 u_cameraPos;
uniform vec2 u_cameraRotation;
uniform float u_aperture;
uniform float u_focalDistance;

// Constants
const vec3 SKY_HORIZON_COLOR = vec3(1.0, 1.0, 1.0);
const vec3 SKY_ZENITH_COLOR = vec3(0.1, 0.4, 0.7);
const vec3 LIGHT_EMISSION = vec3(5.0, 5.0, 4.0);
const float AMBIENT_INTENSITY = 0.15;
const float EPSILON = 0.001;
const int MAX_BOUNCES = 5;
const int SAMPLES_PER_PIXEL = 10;

// Material Types (as defined in JS)
const int LAMBERTIAN = 0;
const int REFLECTIVE = 1;
const int REFRACTIVE = 2;

// Object IDs
const int PLANE_ID = 3;



// --- Data Structures ---

struct Material {
    vec3 diffuseColor;
    float reflectivity;
    float ior;
    int materialType;
};

struct HitRecord {
    float t;
    vec3 normal;
    Material material;
    int objectID;
};


// --- Utility Functions ---

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

mat3 rotateX(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);
}

mat3 rotateY(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
}


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


// --- Scene Traversal ---

HitRecord findClosestHit(vec3 rayOrigin, vec3 rayDir) {
    HitRecord closestHit;
    closestHit.t = -1.0;

    // Check Scene Spheres
    for (int i = 0; i < 3; ++i) {
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


// --- Shading Functions ---

float calculateShadow(vec3 hitPoint, vec3 N) {
    vec3 lightVec = u_lightSphereCenter - hitPoint;
    vec3 shadowRayDir = normalize(lightVec);
    float distanceToLight = length(lightVec);
    vec3 shadowRayOrigin = hitPoint + N * EPSILON * 5.0;

    for (int i = 0; i < 3; ++i) {
        float t = intersectSphere(shadowRayOrigin, shadowRayDir, u_sphereCenters[i], u_sphereRadii[i]);
        if (t > EPSILON && t < distanceToLight) {
            return 0.2; // Shadowed
        }
    }

    for (int i = 0; i < MAX_QUADS; ++i) {
        if (i >= u_quadCount) break;
        float t = intersectQuad(shadowRayOrigin, shadowRayDir, u_quadCorners[i], u_quadU[i], u_quadV[i], u_quadNormals[i]);
        if (t > EPSILON && t < distanceToLight) {
            return 0.2; // Shadowed
        }
    }

    return 1.0; // Lit
}

vec3 shade(HitRecord hit, vec3 rayOrigin, vec3 rayDir) {
    vec3 hitPoint = rayOrigin + rayDir * hit.t;
    vec3 N = hit.normal;

    vec3 lightVec = u_lightSphereCenter - hitPoint;
    vec3 normalizedLightDir = normalize(lightVec);

    float distanceToLightSq = dot(lightVec, lightVec);
    float attenuation = 1.0 / (1.0 + 0.1 * distanceToLightSq);

    float lightFactor = calculateShadow(hitPoint, N);
    float diffuseIntensity = max(0.0, dot(N, normalizedLightDir));

    vec3 ambientColor = vec3(AMBIENT_INTENSITY);
    if (hit.objectID == PLANE_ID) {
        ambientColor = mix(vec3(AMBIENT_INTENSITY * 0.5), SKY_HORIZON_COLOR * 0.7, 0.9);
    }

    return hit.material.diffuseColor * (ambientColor + diffuseIntensity * lightFactor * attenuation * 3.0);
}


// --- Ray Tracing Logic ---

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

vec3 traceRay(vec3 rayOrigin, vec3 rayDir) {
    vec3 accumulatedColor = vec3(0.0);
    vec3 currentRayOrigin = rayOrigin;
    vec3 currentRayDir = rayDir;
    float totalWeight = 1.0;

    for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce) {
        float t_light = intersectSphere(currentRayOrigin, currentRayDir, u_lightSphereCenter, u_lightSphereRadius);
        if (t_light > EPSILON) {
            accumulatedColor += totalWeight * LIGHT_EMISSION;
            break;
        }

        HitRecord hit = findClosestHit(currentRayOrigin, currentRayDir);

        if (hit.t < 0.0) {
            accumulatedColor += totalWeight * getSkyColor(currentRayDir);
            break;
        }

        vec3 hitPoint = currentRayOrigin + currentRayDir * hit.t;
        vec3 localColor = shade(hit, currentRayOrigin, currentRayDir);
        accumulatedColor += totalWeight * localColor * (1.0 - hit.material.reflectivity);
        totalWeight *= hit.material.reflectivity;

        if (totalWeight < 0.01) break;

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
            // For a purely lambertian surface, we would ideally do diffuse reflection.
            // For this simplified model, we'll just stop bouncing for non-reflective/refractive surfaces.
            break;
        }
        
        currentRayDir = nextRayDir;
        currentRayOrigin = hitPoint + currentRayDir * EPSILON;
    }
    return accumulatedColor;
}


// --- Main Function ---

void main() {
    vec3 finalColor = vec3(0.0);
    vec2 pixelSize = 1.0 / u_resolution.xy;

    mat3 camRotation = rotateY(u_cameraRotation.x) * rotateX(u_cameraRotation.y);
    vec3 camRight = camRotation * vec3(1.0, 0.0, 0.0);
    vec3 camUp = camRotation * vec3(0.0, 1.0, 0.0);

    for (int i = 0; i < SAMPLES_PER_PIXEL; i++) {
        vec2 jitter = vec2(random(gl_FragCoord.xy + float(i)), random(gl_FragCoord.xy - float(i))) - 0.5;
        vec2 fragCoord = gl_FragCoord.xy + jitter;
        vec2 uv = (2.0 * fragCoord - u_resolution.xy) / u_resolution.y;

        vec3 rayDirCenter = normalize(vec3(uv.x, uv.y, -1.0));
        rayDirCenter = camRotation * rayDirCenter;

        vec3 focalPoint = u_cameraPos + rayDirCenter * u_focalDistance;

        vec2 randDisk = vec2(random(uv + float(i)), random(uv - float(i)));
        float r = u_aperture * sqrt(randDisk.x);
        float theta = 2.0 * 3.1415926535 * randDisk.y;
        vec3 lensOffset = camRight * r * cos(theta) + camUp * r * sin(theta);

        vec3 rayOrigin = u_cameraPos + lensOffset;
        vec3 rayDir = normalize(focalPoint - rayOrigin);

        finalColor += traceRay(rayOrigin, rayDir);
    }

    finalColor /= float(SAMPLES_PER_PIXEL);
    gl_FragColor = vec4(finalColor, 1.0);
}