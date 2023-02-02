vec3 XYZ_to_Lab(vec3 XYZ, vec3 XYZw) {
  vec3 t = XYZ / XYZw;
  vec3 a = pow(t, vec3(1.0 / 3.0));
  vec3 b = 841.0 / 108.0 * t + 4.0 / 29.0;
  vec3 c = mix(b, a, greaterThan(t, vec3(216.0 / 24389.0)));
  return vec3(1.16 * c.y - 0.16, vec2(5.0, 2.0) * (c.xy - c.yz));
}

vec3 Lab_to_XYZ(vec3 Lab, vec3 XYZw) {
  float L = (Lab.x + 0.16) / 1.16;
  vec3 t = vec3(L + Lab.y / 5.0, L, L - Lab.z / 2.0);
  vec3 a = pow(t, vec3(3.0));
  vec3 b = 108.0 / 841.0 * (t - 4.0 / 29.0);
  return XYZw * mix(b, a, greaterThan(t, vec3(6.0 / 29.0)));
}

vec3 LCh_to_Lab(vec3 LCh) {
  return vec3(LCh.x, LCh.y * vec2(cos(LCh.z), sin(LCh.z)));
}

vec3 Lab_to_LCh(vec3 Lab) {
  return vec3(Lab.x, length(Lab.yz), atan(Lab.z, Lab.y));
}

vec3 sRGB_to_Lab(vec3 sRGB) {
  return XYZ_to_Lab(sRGB_to_XYZ_D50 * sRGB, D50);
}

vec3 Lab_to_sRGB(vec3 Lab) {
  return XYZ_D50_to_sRGB * Lab_to_XYZ(Lab, D50);
}
