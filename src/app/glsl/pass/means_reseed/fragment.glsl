uniform sampler2D tFrame;
uniform sampler2D tMeans;
uniform float uTime;
in vec2 vUV;
out vec4 fColor;

void main() {
  vec4 seed = texture(tFrame, hash22(1e3 * vec2(vUV.x, fract(uTime))));
  vec4 mean = texture(tMeans, vUV);
  fColor = mean.w > 0.0 ? vec4(mean.xyz / mean.w, 1.0) : seed;
}
