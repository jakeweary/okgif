#define K 64

uniform vec4 uMeans[K];

int closest(vec3 point) {
  struct Pair { int i; float d; };
  Pair min = Pair(0, 1e10);
  for (int i = 0; i < K; i++) {
    vec3 v = uMeans[i].xyz - point;
    float d = dot(v, v);
    if (d < min.d) min = Pair(i, d);
  }
  return min.i;
}
