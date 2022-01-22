// dependencies: kmeans

uniform sampler2D tFrame;
uniform sampler2D tNoise;
in vec2 vUV;
out uint fColor;

// vec3 dither(vec3 color, vec3 noise) {
//   // float t = color.x * (1.0 - color.x);
//   color.x += 1.0 / 10.0 * noise.x;
//   color.yz += 1.0 / 20.0 * noise.y * normalize(color.yz);
//   return color;
// }

void main() {
  vec2 fs = vec2(textureSize(tFrame, 0));
  vec2 ns = vec2(textureSize(tNoise, 0));
  vec3 noise = texture(tNoise, fs / ns * vUV).xyz - 0.5;
  vec3 color = texture(tFrame, vUV).xyz;
  fColor = closest(color + noise / 15.0);
}
