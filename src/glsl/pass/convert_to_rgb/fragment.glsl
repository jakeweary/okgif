// dependencies: sRGB

uniform sampler2D tY;
uniform sampler2D tCb;
uniform sampler2D tCr;
in vec2 vUV;
out vec4 fColor;

// https://www.silicondust.com/yuv-to-rgb-conversion-for-tv-video/
const vec3 offset = vec3(-0.972945075, 0.301482665, -1.133402218);
const mat3 convert = mat3(
  1.1643835616, 1.1643835616, 1.1643835616,
  0.0000000000, -0.2132486143, 2.1124017857,
  1.7927410714, -0.5329093286, 0.0000000000
);

void main() {
  float Y = texture(tY, vUV).r;
  float Cb = texture(tCb, vUV).r;
  float Cr = texture(tCr, vUV).r;
  vec3 sRGB = offset + convert * vec3(Y, Cb, Cr);
  fColor = vec4(clamp(sRGB, 0.0, 1.0), 1.0);
}
