// --- Utility Functions ---

// Fast integer hash-based RNG to avoid trig in the fragment path
uint hash2(uvec2 v) {
    v = v * 1664525u + 1013904223u;
    v ^= v.yx << 5;
    v ^= v.yx >> 3;
    v *= 0x27d4eb2du;
    return v.x ^ v.y;
}

float random(vec2 st) {
    // Use tiled blue-noise texture for stable RNG in fragment path
    vec2 uv = fract(st * (1.0 / u_noiseTexSize));
    return texture(u_noiseTex, uv).r;
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

vec3 cosineSampleHemisphere(vec3 normal) {
    float u1 = random(gl_FragCoord.xy + vec2(0.1, 0.2));
    float u2 = random(gl_FragCoord.xy + vec2(0.3, 0.4));

    float r = sqrt(u1);
    float theta = 2.0 * PI * u2;

    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(1.0 - u1);

    vec3 tangent = normalize(cross(normal, abs(normal.x) < 0.5 ? vec3(1, 0, 0) : vec3(0, 1, 0)));
    vec3 bitangent = cross(normal, tangent);

    return normalize(x * tangent + y * bitangent + z * normal);
}