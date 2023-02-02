uniform sampler2D tFrame;
in vec2 vUV;
out vec4 fColor;

void main() {
  vec3 rgb = texture(tFrame, vUV).rgb;
  fColor = vec4(sRGB_to_UCS(rgb), 1.0);
}
