vec3 hsl_to_rgb(vec3 hsl) {
  const vec3 offset = vec3(0.0, 2.0, 1.0) / 3.0;
  float limit = 0.5 - abs(0.5 - hsl.z);
  vec3 rgb = 12.0 * abs(fract(offset + hsl.x) - 0.5) - 3.0;
  return hsl.z + hsl.y * limit * clamp(rgb, -1.0, 1.0);
}

vec3 smooth_hsl_to_rgb(vec3 hsl) {
  const float tau = radians(360.0);
  const vec3 offset = vec3(0.0, 1.0, 2.0) / 3.0;
  float limit = (1.0 - hsl.z) * hsl.z;
  return hsl.z + hsl.y * limit * cos(tau * (offset - hsl.x));
}
