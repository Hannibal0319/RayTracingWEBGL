// --- Data Structures ---

struct Material {
    vec3 diffuseColor;
    float reflectivity;
    float ior;
    int materialType;
    vec3 emissiveColor;
};

struct HitRecord {
    float t;
    vec3 normal;
    Material material;
    int objectID;
};
