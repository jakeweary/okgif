const float z_b = 1.15;
const float z_g = 0.66;
const float z_c1 = 3424.0 / exp2(12.0);
const float z_c2 = 2413.0 / exp2(7.0);
const float z_c3 = 2392.0 / exp2(7.0);
const float z_n = 2610.0 / exp2(14.0);
const float z_p = 1.7 * 2523.0 / exp2(5.0);
const float z_d = -0.56;
const float z_d0 = 1.6295499532821566e-11;

const mat3 XYZ_to_LMS = 1e2 / 1e4 * mat3(
  +0.41478972, -0.20151000, -0.01660080,
  +0.57999900, +1.12064900, +0.26480000,
  +0.01464800, +0.05310080, +0.66847990
) * mat3(z_b, 1.0 - z_g, 0.0, 0.0, z_g, 0.0, 1.0 - z_b, 0.0, 1.0);

const mat3 LMS_to_Iab = mat3(
  +0.5, +3.524000, +0.199076,
  +0.5, -4.066708, +1.096799,
  +0.0, +0.542708, -1.295875
);

vec3 XYZ_to_Jzazbz(vec3 XYZ) {
  vec3 LMS = XYZ_to_LMS * XYZ;
  vec3 LMSpp = pow(LMS, vec3(z_n));
  vec3 LMSp = pow((z_c1 + z_c2 * LMSpp) / (1.0 + z_c3 * LMSpp), vec3(z_p));
  vec3 Iab = LMS_to_Iab * LMSp;
  float J = (1.0 + z_d) * Iab.x / (1.0 + z_d * Iab.x) - z_d0;
  return vec3(J, Iab.yz);
}

vec3 Jzazbz_to_XYZ(vec3 Jab) {
  float I = (Jab.x + z_d0) / (1.0 + z_d - z_d * (Jab.x + z_d0));
  vec3 LMSp = inverse(LMS_to_Iab) * vec3(I, Jab.yz);
  vec3 LMSpp = pow(LMSp, vec3(1.0 / z_p));
  vec3 LMS = pow((z_c1 - LMSpp) / (z_c3 * LMSpp - z_c2), vec3(1.0 / z_n));
  return inverse(XYZ_to_LMS) * LMS;
}

vec3 JzCzhz_to_Jzazbz(vec3 JCh) {
  return vec3(JCh.x, JCh.y * vec2(cos(JCh.z), sin(JCh.z)));
}

vec3 Jzazbz_to_JzCzhz(vec3 Jab) {
  return vec3(Jab.x, length(Jab.yz), atan(Jab.z, Jab.y));
}
