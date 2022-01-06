#version 330

uniform mat4 uMVP;
in vec2 aPosition;
in vec3 aColor;
out vec3 vColor;

void main() {
  vColor = aColor;
  gl_Position = uMVP * vec4(aPosition, 0.0, 1.0);
}
