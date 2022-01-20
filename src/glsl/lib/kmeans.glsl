#define K 256

uniform vec4 uMeans[K];

uint closest(vec3 point) {
  struct Pair { uint i; float d; };
  Pair min = Pair(0, 1e10);
  for (uint i = 0; i < K; i++) {
    vec3 v = uMeans[i].xyz - point;
    float d = dot(v, v);
    if (d < min.d) min = Pair(i, d);
  }
  return min.i;
}
