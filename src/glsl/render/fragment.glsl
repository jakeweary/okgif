// dependencies: hashes, kmeans, Oklab

uniform sampler2D tFrame;
uniform sampler2D tMeans;
uniform float uTime;
in vec2 vUV;
out vec4 fColor;

void main() {
  const vec2 ps = vec2(8.0, 8.0);
  vec2 fs = vec2(textureSize(tFrame, 0));
  vec2 uv = (fs * (1.0 - vUV) - 16.0) / 8.0 / ps;

  if (0.0 <= min(uv.x, uv.y) && max(uv.x, uv.y) <= 1.0) {
    float x = (floor(ps.y * uv.y) + uv.x) / ps.y;
    vec4 lab = texture(tMeans, vec2(x, 0.5));
    vec3 rgb = Lab_to_sRGB(lab.xyz);
    fColor = vec4(rgb, 1.0);
  }
  else {
    vec3 dither = hash33(1e3 * vec3(vUV, fract(uTime))) - 0.5;
    vec3 lab = texture(tFrame, vUV).xyz;
    vec3 lab_d = lab + 0.05 * dither;
    vec3 lab_p = uMeans[closest(lab_d)].xyz;
    vec3 rgb = Lab_to_sRGB(lab_p);
    fColor = vec4(rgb, 1.0);
  }
}
