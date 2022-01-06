#version 460

uniform mat4 uMVP;
in vec3 aPosition;
out float vAlpha;

void main() {
  gl_Position = uMVP * vec4(aPosition, 1.0);

  float scale = 0.1 / gl_Position.w;
  gl_PointSize = max(1.0, scale);
  vAlpha = min(1.0, scale);
}
