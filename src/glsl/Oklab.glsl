// dependencies: sRGB

const mat3 M1 = mat3(
  +0.8189330101, +0.0329845436, +0.0482003018,
  +0.3618667424, +0.9293118715, +0.2643662691,
  -0.1288597137, +0.0361456387, +0.6338517070
);

const mat3 M2 = mat3(
  +0.2104542553, +1.9779984951, +0.0259040371,
  +0.7936177850, -2.4285922050, +0.7827717662,
  -0.0040720468, +0.4505937099, -0.8086757660
);

vec3 XYZ_to_Lab(vec3 XYZ) {
  vec3 lms = M1 * XYZ;
  vec3 lms_p = sign(lms) * pow(abs(lms), vec3(1.0 / 3.0));
  return M2 * lms_p;
}

vec3 Lab_to_XYZ(vec3 Lab) {
  vec3 lms_p = inverse(M2) * Lab;
  vec3 lms = lms_p * lms_p * lms_p;
  return inverse(M1) * lms;
}

vec3 LCh_to_Lab(vec3 LCh) {
  return vec3(LCh.x, LCh.y * vec2(cos(LCh.z), sin(LCh.z)));
}

vec3 Lab_to_LCh(vec3 Lab) {
  return vec3(Lab.x, length(Lab.yz), atan(Lab.z, Lab.y));
}

vec3 sRGB_to_Lab(vec3 sRGB) {
  return XYZ_to_Lab(sRGB_to_XYZ * sRGB);
}

vec3 Lab_to_sRGB(vec3 Lab) {
  return XYZ_to_sRGB * Lab_to_XYZ(Lab);
}

vec3 sRGB_to_LCh(vec3 sRGB) {
  return Lab_to_LCh(sRGB_to_Lab(sRGB));
}

vec3 LCh_to_sRGB(vec3 LCh) {
  return Lab_to_sRGB(LCh_to_Lab(LCh));
}

float L_to_Lr(float L) {
  const vec3 k = vec3(0.206, 0.03, 1.206 / 1.03);
  float x = k.z * L - k.x;
  return 0.5 * (x + sqrt(x * x + 4.0 * k.y * k.z * L));
}

float Lr_to_L(float Lr) {
  const vec3 k = vec3(0.206, 0.03, 1.206 / 1.03);
  return (Lr * (Lr + k.x)) / (k.z * (Lr + k.y));
}
