// https://github.com/selfshadow/ltc_code/blob/master/webgl/shaders/ltc/ltc_blit.fs
// https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
vec3 aces(vec3 color) {
  // sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
  const mat3 m1 = mat3(+0.59719, +0.07600, +0.02840, +0.35458, +0.90834, +0.13383, +0.04823, +0.01566, +0.83777);
  // ODT_SAT => XYZ => D60_2_D65 => sRGB
  const mat3 m2 = mat3(+1.60475, -0.10208, -0.00327, -0.53108, +1.10813, -0.07276, -0.07367, -0.00605, +1.07602);
  // RRT and ODT fit
  vec3 v = m1 * color;
  vec3 a = v * (v + 0.0245786) - 0.000090537;
  vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
  return m2 * (a / b);
}

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float aces(float x) {
  return (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
}
