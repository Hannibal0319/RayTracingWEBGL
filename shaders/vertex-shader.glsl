attribute vec2 a_position;

void main() {
    // Since we're drawing a fullscreen quad, we can pass the clip-space coordinates directly.
    gl_Position = vec4(a_position, 0.0, 1.0);
}