// dependencies: Oklab

uniform sampler2D tFrame;
in vec2 vUV;
out vec4 fColor;

void main() {
  vec3 rgb = texture(tFrame, vUV).rgb;
  vec3 lab = sRGB_to_Lab(rgb);
  fColor = vec4(lab, 1.0);
}
