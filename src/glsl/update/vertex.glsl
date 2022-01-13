// dependencies: kmeans

uniform sampler2D tFrame;
out vec3 vColor;

void main() {
  ivec2 ts = textureSize(tFrame, 0);
  ivec2 xy = ivec2(gl_VertexID % ts.x, gl_VertexID / ts.x);
  vec2 uv = (0.5 + vec2(xy)) / vec2(ts);
  vec3 lab = texture(tFrame, uv).xyz;
  float x = (0.5 + float(closest(lab))) / float(K);
  gl_Position = vec4(2.0 * x - 1.0, 0.0, 0.0, 1.0);
  vColor = lab;
}
