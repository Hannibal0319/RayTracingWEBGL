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
