#define xy_to_XYZ(x, y) vec3(x / y, 1.0, (1.0 - x - y) / y)
#define diag3(v) mat3((v).x, 0.0, 0.0, 0.0, (v).y, 0.0, 0.0, 0.0, (v).z)
#define primaries(rx, ry, gx, gy, bx, by) mat3(xy_to_XYZ(rx, ry), xy_to_XYZ(gx, gy), xy_to_XYZ(bx, by))
#define whitepoint(wx, wy) xy_to_XYZ(wx, wy)
#define colorspace(gamut, wp) gamut * diag3(inverse(gamut) * wp)

const vec3 D65 = whitepoint(0.31271, 0.32902);
const mat3 sRGB = primaries(0.64, 0.33, 0.30, 0.60, 0.15, 0.06);
const mat3 sRGB_to_XYZ = colorspace(sRGB, D65);
const mat3 XYZ_to_sRGB = inverse(sRGB_to_XYZ);

vec3 sRGB_OETF(vec3 c) {
  vec3 a = 12.92 * c;
  vec3 b = 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055;
  return mix(a, b, greaterThan(c, vec3(0.00313066844250063)));
}

vec3 sRGB_EOTF(vec3 c) {
  vec3 a = c / 12.92;
  vec3 b = pow((c + 0.055) / 1.055, vec3(2.4));
  return mix(a, b, greaterThan(c, vec3(0.0404482362771082)));
}
