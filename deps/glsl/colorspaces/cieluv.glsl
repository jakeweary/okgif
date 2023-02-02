#define XYZ_to_uv(XYZ) vec2(4.0, 9.0) * XYZ.xy / (XYZ.x + 15.0 * XYZ.y + 3.0 * XYZ.z)
#define xy_to_uv(xy) vec2(4.0, 9.0) * xy / (-2.0 * xy.x + 12.0 * xy.y + 3.0)
#define uv_to_xy(uv) vec2(9.0, 4.0) * uv / (6.0 * uv.x - 16.0 * uv.y + 12.0)

vec3 XYZ_to_Luv(vec3 XYZ, vec3 XYZw) {
  float Y = XYZ.y / XYZw.y;
  float L = Y > 216.0 / 24389.0 ? 1.16 * pow(Y, 1.0 / 3.0) - 0.16 : 24389.0 / 2700.0 * Y;
  return vec3(L, 13.0 * L * (XYZ_to_uv(XYZ) - XYZ_to_uv(XYZw)));
}

vec3 Luv_to_XYZ(vec3 Luv, vec3 XYZw) {
  vec2 uv = Luv.yz / (13.0 * Luv.x) + XYZ_to_uv(XYZw);
  float Y = Luv.x > 0.08 ? pow((Luv.x + 0.16) / 1.16, 3.0) : 2700.0 / 24389.0 * Luv.x;
  float X = (9.0 * uv.x) / (4.0 * uv.y);
  float Z = (12.0 - 3.0 * uv.x - 20.0 * uv.y) / (4.0 * uv.y);
  return XYZw.y * vec3(Y * X, Y, Y * Z);
}

vec3 LCh_to_Luv(vec3 LCh) {
  return vec3(LCh.x, LCh.y * vec2(cos(LCh.z), sin(LCh.z)));
}

vec3 Luv_to_LCh(vec3 Luv) {
  return vec3(Luv.x, length(Luv.yz), atan(Luv.z, Luv.y));
}

vec3 sRGB_to_Luv(vec3 sRGB) {
  return XYZ_to_Luv(sRGB_to_XYZ * sRGB, D65);
}

vec3 Luv_to_sRGB(vec3 Luv) {
  return XYZ_to_sRGB * Luv_to_XYZ(Luv, D65);
}
