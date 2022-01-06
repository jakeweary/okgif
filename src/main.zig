const c = @import("c.zig");
const std = @import("std");
const gl = @import("gl/gl.zig");

const Vertex = struct {
  position: c.vec2,
  color: c.vec3
};

fn triangle() [3]Vertex {
  const third = @as(f32, std.math.tau) / 3;
  const x = @sin(third);
  const y = @cos(third);
  return .{
    .{ .position = .{  0, 1 }, .color = .{ 1, 0, 0 } },
    .{ .position = .{ -x, y }, .color = .{ 0, 1, 0 } },
    .{ .position = .{  x, y }, .color = .{ 0, 0, 1 } }
  };
}

pub fn main() !void {
  _ = c.glfwSetErrorCallback(gl.errorCallback);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFWInitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  c.glfwWindowHint(c.GLFW_SAMPLES, 4);
  const window = c.glfwCreateWindow(720, 720, "", null, null)
    orelse return error.GLFWCreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetKeyCallback(window, gl.keyCallback);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(1);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.enableDebugMessages();
  c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  // c.glEnable(c.GL_BLEND);
  // c.glBlendFunc(c.GL_ONE, c.GL_ONE);

  //

  const vs = @embedFile("shaders/base.vert");
  const fs = @embedFile("shaders/base.frag");
  const program = try gl.Program.init(vs, fs);
  defer program.deinit();

  const aPosition = program.attribute("aPosition");
  const aColor = program.attribute("aColor");
  const uMVP = program.uniform("uMVP");

  var vbo: c.GLuint = undefined;
  c.glGenBuffers(1, &vbo);
  defer c.glDeleteBuffers(1, &vbo);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    defer c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    const vertices = triangle();
    const size = @sizeOf(@TypeOf(vertices));
    c.glBufferData(c.GL_ARRAY_BUFFER, size, vertices[0..], c.GL_STATIC_DRAW);

    c.glBindVertexArray(vao);
    defer c.glBindVertexArray(0);

    c.glEnableVertexAttribArray(aPosition);
    c.glVertexAttribPointer(aPosition, 2, c.GL_FLOAT, c.GL_FALSE,
      @sizeOf(Vertex), @intToPtr(?*c.GLvoid, @offsetOf(Vertex, "position")));

    c.glEnableVertexAttribArray(aColor);
    c.glVertexAttribPointer(aColor, 3, c.GL_FLOAT, c.GL_FALSE,
      @sizeOf(Vertex), @intToPtr(?*c.GLvoid, @offsetOf(Vertex, "color")));
  }

  while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetFramebufferSize(window, &width, &height);
    const ratio = @intToFloat(f32, width) / @intToFloat(f32, height);

    c.glViewport(0, 0, width, height);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    var m: c.mat4x4 = undefined;
    var p: c.mat4x4 = undefined;
    var mvp: c.mat4x4 = undefined;
    c.mat4x4_identity(&m);
    c.mat4x4_rotate_Z(&m, &m, @floatCast(f32, c.glfwGetTime()));
    c.mat4x4_scale_aniso(&m, &m, 0.8, 0.8, 0.8);
    c.mat4x4_ortho(&p, -ratio, ratio, -1, 1, 1, -1);
    c.mat4x4_mul(&mvp, &p, &m);

    c.glUseProgram(program.id);
    defer c.glUseProgram(0);
    c.glUniformMatrix4fv(uMVP, 1, c.GL_FALSE, @ptrCast([*c]const f32, &mvp));
    c.glBindVertexArray(vao);
    defer c.glBindVertexArray(0);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

    c.glfwSwapBuffers(window);
    c.glfwPollEvents();
  }
}
