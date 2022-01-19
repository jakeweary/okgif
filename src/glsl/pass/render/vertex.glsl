out vec2 vUV;

void main() {
  vUV = vec2(2 & gl_VertexID, 2 & gl_VertexID << 1);
  gl_Position = vec4(vec2(2, -2) * (vUV - 0.5), 0, 1);
}
