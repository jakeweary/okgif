uniform sampler2D tFrame;
uniform sampler3D tNoise;
uniform int uFrame;
in vec2 vUV;
out uint fColor;

void main() {
  vec2 fs = vec2(textureSize(tFrame, 0));
  vec3 ns = vec3(textureSize(tNoise, 0));

  vec3 noise_uvw = vec3(fs / ns.xy * vUV, 0.0); // float(uFrame) / ns.z);
  vec3 noise = texture(tNoise, noise_uvw).xyz - 0.5;
  vec3 color = texture(tFrame, vUV).xyz;
  fColor = kmeans_closest(color + noise * 0.02);
}
