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

struct TriHitData {
    float t;
    vec3 normal;
    vec3 diffuse;
    vec3 info;
    vec3 emission;
    int triIndex;
};

struct BVHNodeData {
    vec3 bmin;
    vec3 bmax;
    int childOrFirst;
    int childOrCount;
    bool leaf;
};