#define K 256

uniform vec4 uMeans[K];

uint kmeans_closest(vec3 point) {
  struct Mean { uint idx; float dist; };
  Mean closest = Mean(0, 1e10);
  for (uint i = 0; i < K; i++) {
    vec3 diff = uMeans[i].xyz - point;
    float dist = dot(diff, diff);
    if (dist < closest.dist)
      closest = Mean(i, dist);
  }
  return closest.idx;
}
