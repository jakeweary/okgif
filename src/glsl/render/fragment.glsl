// dependencies: kmeans, UCS

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
    vec3 ucs = texture(tMeans, vec2(x, 0.5)).xyz;
    fColor = vec4(UCS_to_sRGB(ucs), 1.0);
  }
  else {
    vec4 noise = texture(tNoise, fs / ns * vUV);
    vec3 dither = 0.05 * (noise.xyz - 0.5);
    vec3 ucs = uMeans[closest(texture(tFrame, vUV).xyz + dither)].xyz;
    fColor = vec4(UCS_to_sRGB(ucs), 1.0);
  }
}
