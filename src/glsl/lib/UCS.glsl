// dependencies: Oklab

vec3 sRGB_to_UCS(vec3 sRGB) {
  vec3 Lab = sRGB_to_Lab(sRGB);
  return vec3(L_to_Lr(Lab.x), Lab.yz);
}

vec3 UCS_to_sRGB(vec3 Lrab) {
  vec3 Lab = vec3(Lr_to_L(Lrab.x), Lrab.yz);
  return Lab_to_sRGB(Lab);
}

// ---

// dependencies: CAM16

// vec3 sRGB_to_UCS(vec3 sRGB) {
//   vec3 v = XYZ_to_CAM16_UCS(sRGB_to_XYZ * sRGB);
//   return vec3(v.x, v.y * vec2(cos(v.z), sin(v.z)));
// }

// vec3 UCS_to_sRGB(vec3 JMh) {
//   vec3 v = vec3(JMh.x, length(JMh.yz), atan(JMh.z, JMh.y));
//   return XYZ_to_sRGB * CAM16_UCS_to_XYZ(v);
// }

// ---

// const mat3 rgb_to_yab = 1.0/6.0*mat3(
//   2.0, 2.0*sqrt(2.0), 0.0,
//   2.0, -sqrt(2.0), sqrt(6.0),
//   2.0, -sqrt(2.0), -sqrt(6.0)
// );

// const mat3 yab_to_rgb = 1.0/2.0*mat3(
//   2.0, 2.0, 2.0,
//   2.0*sqrt(2.0), -sqrt(2.0), -sqrt(2.0),
//   0.0, sqrt(6.0), -sqrt(6.0)
// );

// vec3 sRGB_to_UCS(vec3 sRGB) {
//   return rgb_to_yab * sRGB;
// }

// vec3 UCS_to_sRGB(vec3 yab) {
//   return yab_to_rgb * yab;
// }
