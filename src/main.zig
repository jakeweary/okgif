const c = @import("c.zig");
const std = @import("std");
const gl = @import("gl/gl.zig");

const Vertex = struct { pos: c.vec2, col: c.vec3 };

const vertices = [_]Vertex{
  .{ .pos = .{ -0.6, -0.4 }, .col = .{ 1, 0, 0 } },
  .{ .pos = .{  0.6, -0.4 }, .col = .{ 0, 1, 0 } },
  .{ .pos = .{  0.0,  0.6 }, .col = .{ 0, 0, 1 } }
};

pub fn main() !void {
  _ = c.glfwSetErrorCallback(gl.errorCallback);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFWInitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  c.glfwWindowHint(c.GLFW_SAMPLES, 4);
  const window = c.glfwCreateWindow(960, 540, "", null, null)
    orelse return error.GLFWCreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetKeyCallback(window, gl.keyCallback);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(1);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  var flags: c_int = undefined;
  c.glGetIntegerv(c.GL_CONTEXT_FLAGS, &flags);
  if (flags & c.GL_CONTEXT_FLAG_DEBUG_BIT != 0) {
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glEnable(c.GL_DEBUG_OUTPUT_SYNCHRONOUS);
    c.glDebugMessageCallback(gl.debugMessageCallback, null);
    c.glDebugMessageControl(c.GL_DONT_CARE, c.GL_DONT_CARE, c.GL_DONT_CARE, 0, null, c.GL_TRUE);
  }

  std.log.info("{s}", .{ c.glGetString(c.GL_VENDOR) });
  std.log.info("{s}", .{ c.glGetString(c.GL_RENDERER) });
  std.log.info("OpenGL {s}", .{ c.glGetString(c.GL_VERSION) });
  std.log.info("GLSL {s}", .{ c.glGetString(c.GL_SHADING_LANGUAGE_VERSION) });

  //

  const vs = @embedFile("shaders/base.vert");
  const fs = @embedFile("shaders/base.frag");
  const program = try gl.Program.init(vs, fs);
  defer program.deinit();

  const loc_mvp = c.glGetUniformLocation(program.id, "MVP");
  const loc_vpos = @intCast(c.GLuint, c.glGetAttribLocation(program.id, "vPos"));
  const loc_vcol = @intCast(c.GLuint, c.glGetAttribLocation(program.id, "vCol"));

  var vertex_buffer: c.GLuint = undefined;
  c.glGenBuffers(1, &vertex_buffer);
  defer c.glDeleteBuffers(1, &vertex_buffer);

  var vertex_array: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vertex_array);
  defer c.glDeleteVertexArrays(1, &vertex_array);

  {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vertex_buffer);
    defer c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), vertices[0..], c.GL_STATIC_DRAW);

    c.glBindVertexArray(vertex_array);
    defer c.glBindVertexArray(0);

    c.glEnableVertexAttribArray(loc_vpos);
    c.glVertexAttribPointer(loc_vpos, 2, c.GL_FLOAT, c.GL_FALSE,
      @sizeOf(Vertex), @intToPtr(?*c.GLvoid, @offsetOf(Vertex, "pos")));

    c.glEnableVertexAttribArray(loc_vcol);
    c.glVertexAttribPointer(loc_vcol, 3, c.GL_FLOAT, c.GL_FALSE,
      @sizeOf(Vertex), @intToPtr(?*c.GLvoid, @offsetOf(Vertex, "col")));
  }

  while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
    var width: c.GLint = undefined;
    var height: c.GLint = undefined;
    c.glfwGetFramebufferSize(window, &width, &height);
    const ratio = @intToFloat(f32, width) / @intToFloat(f32, height);

    c.glViewport(0, 0, width, height);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    var m: c.mat4x4 = undefined;
    var p: c.mat4x4 = undefined;
    var mvp: c.mat4x4 = undefined;
    c.mat4x4_identity(&m);
    c.mat4x4_rotate_Z(&m, &m, @floatCast(f32, c.glfwGetTime()));
    c.mat4x4_ortho(&p, -ratio, ratio, -1, 1, 1, -1);
    c.mat4x4_mul(&mvp, &p, &m);

    c.glUseProgram(program.id);
    defer c.glUseProgram(0);

    c.glUniformMatrix4fv(loc_mvp, 1, c.GL_FALSE, @ptrCast([*c]const f32, &mvp));
    c.glBindVertexArray(vertex_array);
    defer c.glBindVertexArray(0);
    c.glDrawArrays(c.GL_TRIANGLES, 0, vertices.len);

    c.glfwSwapBuffers(window);
    c.glfwPollEvents();
  }
}
