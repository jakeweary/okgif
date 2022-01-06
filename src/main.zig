const c = @import("c.zig");
const std = @import("std");
const gl = @import("gl/gl.zig");

pub fn main() !void {
  var gpu = std.heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpu.deinit();

  //

  _ = c.glfwSetErrorCallback(gl.errorCallback);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFWInitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
  c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  c.glfwWindowHint(c.GLFW_SAMPLES, 8);
  const window = c.glfwCreateWindow(960, 540, "", null, null)
    orelse return error.GLFWCreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetKeyCallback(window, gl.keyCallback);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(1);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.enableDebugMessages();

  // c.glEnable(c.GL_FRAMEBUFFER_SRGB);
  c.glEnable(c.GL_PROGRAM_POINT_SIZE);
  c.glEnable(c.GL_BLEND);
  c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE);
  c.glBlendEquation(c.GL_FUNC_ADD);

  //

  var particles = std.ArrayList(c.vec3).init(gpu.allocator());
  defer particles.deinit();

  {
    const n = 200;
    try particles.ensureTotalCapacity(n * n * n);
    var x: f32 = 0.5; while (x < n) : (x += 1) {
      var y: f32 = 0.5; while (y < n) : (y += 1) {
        var z: f32 = 0.5; while (z < n) : (z += 1) {
          var v: c.vec3 = .{ x, y, z };
          c.vec3_scale(&v, &v, 1.0 / @as(f32, n));
          c.vec3_sub(&v, &v, &c.vec3{ 0.5, 0.5, 0.5 });
          try particles.append(v);
        }
      }
    }
  }

  //

  const vs = @embedFile("shaders/particle.vert");
  const fs = @embedFile("shaders/particle.frag");
  const program = try gl.Program.init(vs, fs);
  defer program.deinit();

  const a_position = program.attribute("aPosition");
  const u_mvp = program.uniform("uMVP");

  var vbo: c.GLuint = undefined;
  c.glGenBuffers(1, &vbo);
  defer c.glDeleteBuffers(1, &vbo);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBindVertexArray(vao);
    defer c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    defer c.glBindVertexArray(0);
    defer c.glEnableVertexAttribArray(0);

    const size = @intCast(c_longlong, particles.items.len * @sizeOf(c.vec3));
    c.glBufferData(c.GL_ARRAY_BUFFER, size, particles.items.ptr, c.GL_STATIC_DRAW);
    c.glEnableVertexAttribArray(a_position);
    c.glVertexAttribPointer(a_position, 3, c.GL_FLOAT, c.GL_FALSE, 0, null);
  }

  while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
    const t = @floatCast(f32, c.glfwGetTime());

    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetFramebufferSize(window, &width, &height);
    const ratio = @intToFloat(f32, width) / @intToFloat(f32, height);

    c.glViewport(0, 0, width, height);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    var m: c.mat4x4 = undefined;
    var p: c.mat4x4 = undefined;
    var mvp: c.mat4x4 = undefined;
    c.mat4x4_translate(&m, 0, 0, -0.5);
    c.mat4x4_rotate_X(&m, &m, 0.003 * t);
    c.mat4x4_rotate_Y(&m, &m, 0.005 * t);
    c.mat4x4_rotate_Z(&m, &m, 0.007 * t);
    c.mat4x4_perspective(&p, 30.0 / 360.0 * std.math.tau, ratio, 1e-3, 1e3);
    c.mat4x4_mul(&mvp, &p, &m);

    c.glUseProgram(program.id);
    defer c.glUseProgram(0);
    c.glUniformMatrix4fv(u_mvp, 1, c.GL_FALSE, @ptrCast([*c]const f32, &mvp));
    c.glBindVertexArray(vao);
    defer c.glBindVertexArray(0);
    c.glDrawArrays(c.GL_POINTS, 0, @intCast(c_int, particles.items.len));

    c.glfwSwapBuffers(window);
    c.glfwPollEvents();
  }
}
