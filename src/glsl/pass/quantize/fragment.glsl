// dependencies: kmeans

uniform sampler2D tFrame;
uniform sampler2D tNoise;
in vec2 vUV;
out uint fColor;

void main() {
  vec2 fs = vec2(textureSize(tFrame, 0));
  vec2 ns = vec2(textureSize(tNoise, 0));

  vec4 noise = texture(tNoise, fs / ns * vUV);
  vec3 dither = 0.1 * (noise.xyz - 0.5);
  fColor = closest(texture(tFrame, vUV).xyz + dither);
}
