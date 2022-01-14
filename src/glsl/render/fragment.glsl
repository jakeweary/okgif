// dependencies: kmeans, Oklab

uniform sampler2D tFrame;
uniform sampler2D tMeans;
uniform sampler2D tNoise;
in vec2 vUV;
out vec4 fColor;

void main() {
  const vec2 grid = vec2(8.0, 8.0);
  vec2 fs = vec2(textureSize(tFrame, 0));
  vec2 ns = vec2(textureSize(tNoise, 0));
  vec2 uv = (fs * (1.0 - vUV) - 16.0) / 8.0 / grid;

  if (0.0 <= min(uv.x, uv.y) && max(uv.x, uv.y) <= 1.0) {
    float x = (floor(grid.y * uv.y) + uv.x) / grid.y;
    vec4 lab = texture(tMeans, vec2(x, 0.5));
    vec3 rgb = Lab_to_sRGB(lab.xyz);
    fColor = vec4(rgb, 1.0);
  }
  else {
    vec4 noise = texture(tNoise, fs / ns * vUV);
    vec3 dither = 0.1 * (noise.xyz - 0.5);
    vec3 lab = uMeans[closest(texture(tFrame, vUV).xyz + dither)].xyz;
    vec3 rgb = Lab_to_sRGB(lab);
    fColor = vec4(rgb, 1.0);
  }
}
