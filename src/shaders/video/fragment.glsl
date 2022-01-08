#version 460

uniform sampler2D uChannelY;
uniform sampler2D uChannelCb;
uniform sampler2D uChannelCr;
in vec2 vUV;
out vec4 fColor;

const mat4 YCbCr_sRGB = mat4(
  +1.0000, +1.0000, +1.0000, +0.0000,
  +0.0000, -0.3441, +1.7720, +0.0000,
  +1.4020, -0.7141, +0.0000, +0.0000,
  -0.7010, +0.5291, -0.8860, +1.0000
);

void main() {
  float Y = texture(uChannelY, vUV).r;
  float Cb = texture(uChannelCb, vUV).r;
  float Cr = texture(uChannelCr, vUV).r;
  fColor = YCbCr_sRGB * vec4(Y, Cb, Cr, 1.0);
}
