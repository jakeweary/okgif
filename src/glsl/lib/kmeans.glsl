#define K 256

uniform vec4 uMeans[K];

float redmean(vec3 a, vec3 b) {
  float r = (a.r + b.r) / 2.0;
  vec3 d = a - b;
  return sqrt(dot(vec3(2.0 + r / 256.0, 4.0, 2.0 + (255.0 - r) / 256.0), d * d));
}

uint closest(vec3 point) {
  struct Pair { uint i; float d; };
  Pair min = Pair(0, 1e10);
  for (uint i = 0; i < K; i++) {
    // float d = redmean(uMeans[i].xyz, point);
    vec3 v = uMeans[i].xyz - point;
    float d = dot(v, v);
    if (d < min.d) min = Pair(i, d);
  }
  return min.i;
}
