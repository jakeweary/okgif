#version 330

in vec3 color;
out vec4 fragment;

vec3 sRGB_OETF(vec3 c) {
  vec3 a = 12.92*c;
  vec3 b = 1.055*pow(c, vec3(1.0/2.4)) - 0.055;
  return mix(a, b, greaterThan(c, vec3(0.00313066844250063)));
}

void main() {
  fragment = vec4(sRGB_OETF(color), 1.0);
}
