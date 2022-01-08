#version 460

in vec2 aPosition;
out vec2 vUV;

void main() {
  vUV = 0.5 + vec2(0.5, -0.5) * aPosition;
  gl_Position = vec4(aPosition, 0.0, 1.0);
}
