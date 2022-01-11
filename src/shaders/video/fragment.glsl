#version 460

uniform sampler2D uRGB;
in vec2 vUV;
out vec4 fColor;

void main() {
  fColor = texture(uRGB, vUV);
}
