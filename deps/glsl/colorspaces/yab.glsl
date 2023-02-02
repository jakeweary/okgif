// ScalingMatrix[{1, 1, 1}/Sqrt[3]] .
// RotationMatrix[1/2 Pi - ArcTan[1/Sqrt[2]], {0, 0, 1}] .
// RotationMatrix[3/4 Pi, {1, 0, 0}]
const mat3 rgb_to_yab = 1.0 / 6.0 * mat3(
  2.0, 2.0 * sqrt(2.0), 0.0,
  2.0, -sqrt(2.0), sqrt(6.0),
  2.0, -sqrt(2.0), -sqrt(6.0)
);

// = inverse(rgb_to_yab)
// = 3.0*transpose(rgb_to_yab)
const mat3 yab_to_rgb = 1.0 / 2.0 * mat3(
  2.0, 2.0, 2.0,
  2.0 * sqrt(2.0), -sqrt(2.0), -sqrt(2.0),
  0.0, sqrt(6.0), -sqrt(6.0)
);

vec3 ych_to_yab(vec3 ych) {
  return vec3(ych.x, ych.y * vec2(cos(ych.z), sin(ych.z)));
}

vec3 yab_to_ych(vec3 yab) {
  return vec3(yab.x, length(yab.yz), atan(yab.z, yab.y));
}
