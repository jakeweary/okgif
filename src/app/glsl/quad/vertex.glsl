out vec2 vUV;

void main() {
  vUV = vec2(2 & gl_VertexID, 2 & gl_VertexID << 1);
  gl_Position = vec4(2.0 * (vUV - 0.5), 0.0, 1.0);
}
