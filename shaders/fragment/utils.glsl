// --- Utility Functions ---

float random(vec2 st, float time) {
    return fract(sin(dot(st.xy + time, vec2(12.9898, 78.233))) * 43758.5453123);
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

vec3 cosineSampleHemisphere(vec3 normal, float time) {
    float u1 = random(gl_FragCoord.xy + vec2(0.1, 0.2), time);
    float u2 = random(gl_FragCoord.xy + vec2(0.3, 0.4), time + 17.0);

    float r = sqrt(u1);
    float theta = 2.0 * PI * u2;

    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(1.0 - u1);

    vec3 tangent = normalize(cross(normal, abs(normal.x) < 0.5 ? vec3(1, 0, 0) : vec3(0, 1, 0)));
    vec3 bitangent = cross(normal, tangent);

    return normalize(x * tangent + y * bitangent + z * normal);
}