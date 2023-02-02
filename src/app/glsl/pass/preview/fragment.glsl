uniform usampler2D tFrame;
uniform sampler2D tMeans;
in vec2 vUV;
out vec4 fColor;

void main() {
  const vec2 grid = vec2(16.0, 16.0);
  vec2 ms = vec2(textureSize(tMeans, 0));
  vec2 fs = vec2(textureSize(tFrame, 0));
  vec2 uv = (fs * (1.0 - vUV) - 16.0) / 4.0 / grid;

  float x = 0.0 <= min(uv.x, uv.y) && max(uv.x, uv.y) <= 1.0
    ? (floor(grid.y * uv.y) + uv.x) / grid.y
    : texture(tFrame, vUV).x / ms.x;

  vec3 ucs = texture(tMeans, vec2(x, 0.5)).xyz;
  fColor = vec4(UCS_to_sRGB(ucs), 1.0);
}
