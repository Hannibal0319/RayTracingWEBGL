precision highp float;

// Scene Uniforms
uniform vec2 u_resolution;
uniform vec3 u_lightDir;
uniform float u_planeY;
uniform vec3 u_planeColorA;
uniform vec3 u_planeColorB;

// Sphere Data Uniforms (Array of structs would be ideal, but we use flat arrays for WebGL 1.0 compatibility)
uniform vec3 u_sphereCenters[3];
uniform float u_sphereRadii[3];
uniform vec3 u_sphereDiffuseColors[3];
uniform float u_sphereReflectivity[3]; // 0.0=Diffuse, 1.0=Mirror
uniform float u_sphereIOR[3];          // Index of Refraction (1.0=Air, 1.5=Glass)

// CAMERA UNIFORMS
uniform vec3 u_cameraPos;
uniform vec2 u_cameraRotation;

// Constants
const vec3 BACKGROUND_COLOR = vec3(0.05, 0.05, 0.15); 
const float AMBIENT_INTENSITY = 0.1;
const float EPSILON = 0.001;
const int MAX_BOUNCES = 3; // Maximum number of secondary rays (bounces)

// Material IDs (Indices for the uniform arrays)
const int REFLECTIVE_SPHERE_ID = 0;
const int REFRACTIVE_SPHERE_ID = 1;
const int SHADOW_SPHERE_ID = 2;
const int PLANE_ID = 3;

// --- Data Structure for a Ray Hit ---
struct HitRecord {
    float t;             // Distance to hit
    vec3 normal;         // Surface normal
    vec3 color;          // Diffuse color
    float reflectivity;  // Reflection coefficient
    float ior;           // Index of Refraction (IOR)
    int materialID;      // Identifies the hit object (Sphere index or Plane)
};

// --- Utility Functions ---

// Rotation matrix around the X axis (Pitch)
mat3 rotateX(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

// Rotation matrix around the Y axis (Yaw)
mat3 rotateY(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}


// --- Intersection Functions ---

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

float intersectPlane(vec3 rayOrigin, vec3 rayDir, float planeY) {
    float denom = rayDir.y;
    if (abs(denom) < EPSILON) return -1.0;
    
    float t = (planeY - rayOrigin.y) / denom;
    
    return t > EPSILON ? t : -1.0;
}


// --- Scene Traversal ---

/**
    * Finds the closest intersection with any object in the scene.
    */
HitRecord findClosestHit(vec3 rayOrigin, vec3 rayDir) {
    HitRecord closestHit;
    closestHit.t = -1.0;
    
    // --- 1. Check Spheres ---
    for (int i = 0; i < 3; ++i) {
        float t = intersectSphere(rayOrigin, rayDir, u_sphereCenters[i], u_sphereRadii[i]);
        
        if (t > EPSILON && (closestHit.t < 0.0 || t < closestHit.t)) {
            closestHit.t = t;
            closestHit.materialID = i;
            
            vec3 hitPoint = rayOrigin + rayDir * t;
            closestHit.normal = normalize(hitPoint - u_sphereCenters[i]);
            closestHit.color = u_sphereDiffuseColors[i];
            closestHit.reflectivity = u_sphereReflectivity[i];
            closestHit.ior = u_sphereIOR[i];
        }
    }

    // --- 2. Check Plane ---
    float t_plane = intersectPlane(rayOrigin, rayDir, u_planeY);

    if (t_plane > EPSILON && (closestHit.t < 0.0 || t_plane < closestHit.t)) {
        closestHit.t = t_plane;
        closestHit.materialID = PLANE_ID;

        vec3 hitPoint = rayOrigin + rayDir * t_plane;
        closestHit.normal = vec3(0.0, 1.0, 0.0);
        closestHit.reflectivity = 0.0;
        closestHit.ior = 1.0; // Air IOR

        // Checkerboard Pattern on the Floor
        float checkSize = 1.0;
        vec2 coords = hitPoint.xz / checkSize;
        float checker = mod(floor(coords.x) + floor(coords.y), 2.0);
        closestHit.color = mix(u_planeColorA, u_planeColorB, checker);
    }
    
    return closestHit;
}


// --- Shading Functions ---

/**
    * Checks if the hit point is shadowed from the light source.
    * Returns 1.0 if lit, 0.0 if shadowed.
    */
float calculateShadow(vec3 hitPoint, vec3 N) {
    vec3 shadowRayDir = normalize(u_lightDir);
    
    // Push shadow ray origin slightly outward to prevent self-shadowing
    vec3 shadowRayOrigin = hitPoint + N * EPSILON * 5.0; 

    // Check if shadow ray hits any object (only spheres for simplicity)
    for (int i = 0; i < 3; ++i) {
        float t = intersectSphere(shadowRayOrigin, shadowRayDir, u_sphereCenters[i], u_sphereRadii[i]);
        if (t > 0.0) {
            return 0.2; // Return dark shadow factor (ambient is still present)
        }
    }
    return 1.0; // Fully lit
}


/**
    * Calculates the color contribution of a single bounce.
    */
vec3 shade(HitRecord hit, vec3 rayOrigin, vec3 rayDir) { // FIX: Added rayOrigin argument
    vec3 finalColor = vec3(0.0);
    
    vec3 hitPoint = rayOrigin + rayDir * hit.t;
    vec3 N = hit.normal;
    
    // --- 1. Lighting (Diffuse + Ambient) ---
    float lightFactor = calculateShadow(hitPoint, N);
    
    vec3 normalizedLightDir = normalize(u_lightDir);
    float diffuseIntensity = max(0.0, dot(N, normalizedLightDir));
    
    // Local color calculation (Includes ambient and shadow)
    finalColor = hit.color * (AMBIENT_INTENSITY + diffuseIntensity * lightFactor);
    
    return finalColor;
}


// --- Main Function (Ray Tracing Loop) ---
void main() {
    // --- Primary Ray Setup ---
    vec2 fragCoord = gl_FragCoord.xy;
    float aspect = u_resolution.x / u_resolution.y;
    vec2 uv = (2.0 * fragCoord.xy - u_resolution.xy) / u_resolution.y; 
    
    vec3 rayOrigin = u_cameraPos;
    vec3 rayDirUnrotated = normalize(vec3(uv.x, uv.y, -1.0));
    
    // Apply camera rotation
    vec3 rayDir = rayDirUnrotated;
    rayDir = rotateX(u_cameraRotation.y) * rayDir;
    rayDir = rotateY(u_cameraRotation.x) * rayDir;
    rayDir = normalize(rayDir); 

    
    // --- Tracing Loop (Iterative Multi-Bounce) ---
    vec3 accumulatedColor = vec3(0.0);
    vec3 currentRayOrigin = rayOrigin;
    vec3 currentRayDir = rayDir;
    float totalWeight = 1.0;
    
    for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce) {
        
        HitRecord hit = findClosestHit(currentRayOrigin, currentRayDir);
        
        if (hit.t < 0.0) {
            // Missed everything, add background weighted by remaining energy
            accumulatedColor += totalWeight * BACKGROUND_COLOR;
            break;
        }
        
        vec3 hitPoint = currentRayOrigin + currentRayDir * hit.t;
        
        // --- 1. Calculate Local Shading ---
        vec3 localColor = shade(hit, currentRayOrigin, currentRayDir); // FIX: Passed currentRayOrigin
        
        // --- 2. Accumulate Color ---
        accumulatedColor += totalWeight * localColor * (1.0 - hit.reflectivity);
        totalWeight *= hit.reflectivity;
        
        if (totalWeight < 0.01) break; // Energy threshold
        
        // --- 3. Determine Next Ray Direction (Reflection/Refraction) ---
        if (hit.materialID == REFRACTIVE_SPHERE_ID) {
            // Refraction (Glass sphere)
            
            // Determine if the ray is entering or exiting the sphere
            float n1 = 1.0; // Air IOR
            float n2 = hit.ior; // Glass IOR
            vec3 N = hit.normal;
            
            if (dot(hit.normal, currentRayDir) > 0.0) {
                // Exiting the sphere
                n1 = hit.ior;
                n2 = 1.0; 
                N = -N; // Flip normal to point outwards
            }
            
            vec3 refractedDir = refract(currentRayDir, N, n1 / n2);

            if (length(refractedDir) < EPSILON) {
                // Total Internal Reflection (TIR) - treat as a perfect reflection
                currentRayDir = reflect(currentRayDir, N);
            } else {
                // Refraction occurred
                currentRayDir = refractedDir;
            }
            // Reset reflectivity for the next bounce (it's handled by the IOR)
            totalWeight = 1.0; 

        } else {
            // Reflection
            currentRayDir = reflect(currentRayDir, hit.normal);
        }
        
        // --- 4. Prepare for Next Bounce ---
        // Push ray origin away from the surface to prevent self-intersection
        currentRayOrigin = hitPoint + hit.normal * EPSILON * 5.0; 
    }
    
    gl_FragColor = vec4(accumulatedColor, 1.0);
}