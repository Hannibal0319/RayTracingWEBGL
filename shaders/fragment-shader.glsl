precision highp float;

// Scene Uniforms
uniform vec2 u_resolution;
uniform vec3 u_lightSphereCenter; // Center of the sphere light
uniform float u_lightSphereRadius; // Radius of the sphere light
uniform float u_planeY;
uniform vec3 u_planeColorA;
uniform vec3 u_planeColorB;

// Sphere Data Uniforms (Indices 1, 2, and 3 for the scene objects)
uniform vec3 u_sphereCenters[3]; 
uniform float u_sphereRadii[3];  
uniform vec3 u_sphereAABB_min[3]; // AABB min corners
uniform vec3 u_sphereAABB_max[3]; // AABB max corners
uniform vec3 u_sphereDiffuseColors[3]; 
uniform float u_sphereReflectivity[3]; 
uniform float u_sphereIOR[3];          

// CAMERA UNIFORMS
uniform vec3 u_cameraPos;
uniform vec2 u_cameraRotation;

// Constants
const vec3 SKY_HORIZON_COLOR = vec3(1.0, 1.0, 1.0);     // White at the horizon (y=0)
const vec3 SKY_ZENITH_COLOR = vec3(0.1, 0.4, 0.7);      // Deeper blue at zenith
const vec3 LIGHT_EMISSION = vec3(5.0, 5.0, 4.0); // Bright yellowish light
const float AMBIENT_INTENSITY = 0.15; // Increased ambient light to simulate scattered illumination
const float EPSILON = 0.001;
const int MAX_BOUNCES = 3; 

// Material IDs (Indices for the uniform arrays)
const int REFRACTIVE_SPHERE_ID = 0; // SphereCenters[0] in GLSL maps to sphereCenter1 in JS
const int REFLECTIVE_SPHERE_ID = 1; // SphereCenters[1] in GLSL maps to sphereCenter2 in JS
const int SHADOW_SPHERE_ID = 2;     // SphereCenters[2] in GLSL maps to sphereCenter3 in JS
const int PLANE_ID = 3;

// --- Data Structure for a Ray Hit ---
struct HitRecord {
    float t;             
    vec3 normal;         
    vec3 color;          
    float reflectivity;  
    float ior;           
    int materialID;      
};

// --- Utility Functions ---

mat3 rotateX(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

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

/**
 * Ray-AABB intersection test using the slab method.
 * Returns true if the ray intersects the box, false otherwise.
 */
bool intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    
    // A hit occurs if the last entry point (tNear) is before the first exit point (tFar),
    // and the intersection is not behind the ray's origin (tFar > 0.0).
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
    
    // --- 1. Check Scene Spheres (now 3) ---
    for (int i = 0; i < 3; ++i) { // Loop changed back to 3
        // AABB check: Only test for sphere intersection if the ray hits its bounding box
        if (intersectAABB(rayOrigin, rayDir, u_sphereAABB_min[i], u_sphereAABB_max[i])) {
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
    * Returns 1.0 if lit, 0.2 if shadowed (0.2 is the ambient contribution).
    */
float calculateShadow(vec3 hitPoint, vec3 N) {
    vec3 lightVec = u_lightSphereCenter - hitPoint; // Vector from hit point to light center
    vec3 shadowRayDir = normalize(lightVec);
    float distanceToLight = length(lightVec); 

    // Push shadow ray origin slightly outward
    vec3 shadowRayOrigin = hitPoint + N * EPSILON * 5.0; 

    // Check if shadow ray hits any object before reaching the light
    for (int i = 0; i < 3; ++i) { // Loop changed back to 3
        float t = intersectSphere(shadowRayOrigin, shadowRayDir, u_sphereCenters[i], u_sphereRadii[i]);
        // Intersection must be positive AND closer than the light source distance
        if (t > EPSILON && t < distanceToLight) { 
            return 0.2; // Shadowed
        }
    }
    return 1.0; // Fully lit
}


/**
* Calculates the color contribution of a single bounce.
*/
vec3 shade(HitRecord hit, vec3 rayOrigin, vec3 rayDir) {
    vec3 finalColor = vec3(0.0);
    
    vec3 hitPoint = rayOrigin + rayDir * hit.t;
    vec3 N = hit.normal;
    
    // --- Sphere Light Calculation ---
    vec3 lightVec = u_lightSphereCenter - hitPoint;
    vec3 normalizedLightDir = normalize(lightVec);
    
    // Attenuation (Light Intensity Falloff)
    float distanceToLightSq = dot(lightVec, lightVec);
    float attenuation = 1.0 / (1.0 + 0.1 * distanceToLightSq);
    
    // --- Lighting (Diffuse + Ambient) ---
    float lightFactor = calculateShadow(hitPoint, N);
    
    float diffuseIntensity = max(0.0, dot(N, normalizedLightDir));
    
    // NEW: Define ambient term based on material
    vec3 ambientColor = vec3(AMBIENT_INTENSITY);
    
    if (hit.materialID == PLANE_ID) {
        // Simulate soft sky ambient lighting for the ground plane
        // Use the horizon color to ensure the fade to white is smooth
        ambientColor = mix(vec3(AMBIENT_INTENSITY * 0.5), SKY_HORIZON_COLOR * 0.7, 0.9);
    }

    // Local color calculation: Ambient + Diffuse * Shadow Factor * Attenuation (x3.0 for balance)
    finalColor = hit.color * (ambientColor + diffuseIntensity * lightFactor * attenuation * 3.0);
    
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
        
        // 1. Check for Light Source Hit (Highest priority)
        float t_light = intersectSphere(currentRayOrigin, currentRayDir, u_lightSphereCenter, u_lightSphereRadius);
        if (t_light > EPSILON) {
            accumulatedColor += totalWeight * LIGHT_EMISSION;
            break;
        }
        
        // 2. Check for Scene Object Hit
        HitRecord hit = findClosestHit(currentRayOrigin, currentRayDir);
        
        if (hit.t < 0.0) {
            // Missed everything, fallback to gradient sky color
            
            // Normalize the Y direction (clamped from 0 to 1 for smooth mixing)
            // currentRayDir.y ranges from -1 (down) to 1 (up), we want to map 0 to 1
            float skyFactor = max(0.0, currentRayDir.y);
            
            vec3 missedColor = mix(SKY_HORIZON_COLOR, SKY_ZENITH_COLOR, skyFactor); // Gradient mix

            // New: Use a broader, softer term to simulate light scattering across the hemisphere
            vec3 lightPosNormalized = normalize(u_lightSphereCenter); 
            
            // Cosine of angle between ray and light direction (max when looking AT light)
            float illuminationFactor = max(0.0, dot(-currentRayDir, lightPosNormalized)); 
            
            // Scatter: Wider soft illumination (Power 5.0)
            float scatter = pow(illuminationFactor, 5.0) * 0.5; 
            // Glow: Sharp sun disk glow (Power 25.0)
            float glow = pow(illuminationFactor, 25.0) * 1.0; 
            
            // Blend soft scatter with the sky
            missedColor = mix(missedColor, LIGHT_EMISSION * 0.3, scatter);
            
            // Blend sharp glow (sun disk) with the result
            missedColor = mix(missedColor, LIGHT_EMISSION * 1.0, glow); 
            
            accumulatedColor += totalWeight * missedColor;
            break;
        }
        
        vec3 hitPoint = currentRayOrigin + currentRayDir * hit.t;
        
        // --- 1. Calculate Local Shading ---
        vec3 localColor = shade(hit, currentRayOrigin, currentRayDir); 
        
        // --- 2. Accumulate Color ---
        accumulatedColor += totalWeight * localColor * (1.0 - hit.reflectivity);
        totalWeight *= hit.reflectivity;
        
        if (totalWeight < 0.01) break; // Energy threshold
        
        // --- 3. Determine Next Ray Direction (Reflection/Refraction) ---
        if (hit.materialID == REFRACTIVE_SPHERE_ID) {
            // Refraction (Glass sphere)
            
            float n1 = 1.0; 
            float n2 = hit.ior; 
            vec3 N = hit.normal;
            
            if (dot(hit.normal, currentRayDir) > 0.0) {
                n1 = hit.ior;
                n2 = 1.0; 
                N = -N; 
            }
            
            vec3 refractedDir = refract(currentRayDir, N, n1 / n2);

            if (length(refractedDir) < EPSILON) {
                currentRayDir = reflect(currentRayDir, N);
            } else {
                currentRayDir = refractedDir;
            }
            totalWeight = 1.0; 

        } else {
            // Reflection
            currentRayDir = reflect(currentRayDir, hit.normal);
        }
        
        // --- 4. Prepare for Next Bounce ---
        currentRayOrigin = hitPoint + hit.normal * EPSILON * 5.0; 
    }
    
    gl_FragColor = vec4(accumulatedColor, 1.0);
}