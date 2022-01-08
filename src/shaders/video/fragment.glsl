#version 460

uniform sampler2D uChannelR;
uniform sampler2D uChannelG;
uniform sampler2D uChannelB;
in vec2 vUV;
out vec4 fColor;

void main() {
  float r = texture(uChannelR, vUV).r;
  float g = texture(uChannelG, vUV).r;
  float b = texture(uChannelB, vUV).r;
  fColor = vec4(r, g, b, 1.0);
}
