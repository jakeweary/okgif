// https://www.shadertoy.com/view/XsX3zB

// discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3
vec3 simplex3d_random3(vec3 c) {
  float j = 4096.0 * sin(dot(c, vec3(17.0, 59.4, 15.0)));
  return fract(j * vec3(64.0, 8.0, 512.0)) - 0.5;
}

// 3d simplex noise
float simplex3d(vec3 p) {
  // skew constants
  const float F3 = 1.0 / 3.0;
  const float G3 = 1.0 / 6.0;

  // 1. find current tetrahedron T and it's four vertices
  // s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices
  // x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices

  // calculate s and x
  vec3 s = floor(p + dot(p, vec3(F3)));
  vec3 x = p - s + dot(s, vec3(G3));

  // calculate i1 and i2
  vec3 e = step(vec3(0.0), x - x.yzx);
  vec3 i1 = e * (1.0 - e.zxy);
  vec3 i2 = 1.0 - e.zxy * (1.0 - e);

  // x1, x2, x3
  vec3 x1 = x - i1 + G3;
  vec3 x2 = x - i2 + 2.0 * G3;
  vec3 x3 = x - 1.0 + 3.0 * G3;

  // 2. find four surflets and store them in d

  // calculate surflet weights
  vec4 w = vec4(
    dot(x, x),
    dot(x1, x1),
    dot(x2, x2),
    dot(x3, x3)
  );

  // w fades from 0.6 at the center of the surflet to 0.0 at the margin
  w = max(0.6 - w, 0.0);

  // calculate surflet components
  vec4 d = vec4(
    dot(simplex3d_random3(s), x),
    dot(simplex3d_random3(s + i1), x1),
    dot(simplex3d_random3(s + i2), x2),
    dot(simplex3d_random3(s + 1.0), x3)
  );

  // multiply d by w^4
  w *= w;
  w *= w;
  d *= w;

  // 3. return the sum of the four surflets
  return dot(d, vec4(52.0));
}

// directional artifacts can be reduced by rotating each octave
float simplex3d_fractal(vec3 m) {
  // const matrices for 3d rotation
  const mat3 rot1 = mat3(-0.37, +0.36, +0.85, -0.14, -0.93, +0.34, +0.92, +0.01, +0.40);
  const mat3 rot2 = mat3(-0.55, -0.39, +0.74, +0.33, -0.91, -0.24, +0.77, +0.12, +0.63);
  const mat3 rot3 = mat3(-0.71, +0.52, -0.47, -0.08, -0.72, -0.68, -0.70, -0.45, +0.56);

  return dot(vec4(8.0, 4.0, 2.0, 1.0) / 15.0, vec4(
    simplex3d(1.0 * m * rot1),
    simplex3d(2.0 * m * rot2),
    simplex3d(4.0 * m * rot3),
    simplex3d(8.0 * m)
  ));
}
