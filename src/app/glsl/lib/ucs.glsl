vec3 sRGB_to_UCS(vec3 sRGB) {
  vec3 Lab = XYZ_to_Oklab(sRGB_to_XYZ * sRGB);
  return vec3(L_to_Lr(Lab.x), Lab.yz);
}

vec3 UCS_to_sRGB(vec3 Lrab) {
  vec3 Lab = vec3(Lr_to_L(Lrab.x), Lrab.yz);
  return XYZ_to_sRGB * Oklab_to_XYZ(Lab);
}
