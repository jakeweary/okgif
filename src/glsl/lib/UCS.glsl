// dependencies: Oklab

vec3 sRGB_to_UCS(vec3 sRGB) {
  return sRGB_to_Lab(sRGB);
}

vec3 UCS_to_sRGB(vec3 UCS) {
  return Lab_to_sRGB(UCS);
}

// vec3 sRGB_to_UCS(vec3 sRGB) {
//   vec3 v = XYZ_to_CAM16_UCS(sRGB_to_XYZ * sRGB);
//   return vec3(v.x, v.y * vec2(cos(v.z), sin(v.z)));
// }

// vec3 UCS_to_sRGB(vec3 UCS) {
//   vec3 v = vec3(UCS.x, length(UCS.yz), atan(UCS.z, UCS.y));
//   return XYZ_to_sRGB * CAM16_UCS_to_XYZ(v);
// }
