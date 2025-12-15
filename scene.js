// Material Types
const LAMBERTIAN = 0;
const REFLECTIVE = 1;
const REFRACTIVE = 2;

class Material {
    constructor(diffuseColor, reflectivity, ior, materialType) {
        this.diffuseColor = diffuseColor;
        this.reflectivity = reflectivity;
        this.ior = ior;
        this.materialType = materialType;
    }
}

class Sphere {
    constructor(center, radius, material) {
        this.center = center;
        this.radius = radius;
        this.material = material;
        
        // Calculate AABB
        this.aabb_min = [center[0] - radius, center[1] - radius, center[2] - radius];
        this.aabb_max = [center[0] + radius, center[1] + radius, center[2] + radius];
    }
}

class Quad {
    constructor(corner, u, v, material) {
        this.corner = corner;
        this.u = u;
        this.v = v;
        this.material = material;

        // Normal vector for the plane of the quad
        this.normal = cross(u, v);
        normalize(this.normal, this.normal);

        // AABB for the quad
        const p1 = corner;
        const p2 = add(corner, u);
        const p3 = add(corner, v);
        const p4 = add(p2, v);

        this.aabb_min = [
            Math.min(p1[0], p2[0], p3[0], p4[0]),
            Math.min(p1[1], p2[1], p3[1], p4[1]),
            Math.min(p1[2], p2[2], p3[2], p4[2])
        ];
        this.aabb_max = [
            Math.max(p1[0], p2[0], p3[0], p4[0]),
            Math.max(p1[1], p2[1], p3[1], p4[1]),
            Math.max(p1[2], p2[2], p3[2], p4[2])
        ];
    }
}
