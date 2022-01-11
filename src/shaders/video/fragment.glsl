// dependencies: Oklab

uniform sampler2D uRGB;
in vec2 vUV;
out vec4 fColor;

void main() {
  vec3 rgb = texture(uRGB, vUV).rgb;
  vec3 lab = sRGB_to_Lab(sRGB_EOTF(rgb));
  vec3 debug = (lab + vec3(0, 0.5, 0.5)).grb;
  fColor = vec4(debug, 1);
}
