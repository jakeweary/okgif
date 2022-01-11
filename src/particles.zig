const c = @import("c.zig");
const std = @import("std");
const gl = @import("gl/gl.zig");
const Xorshift = @import("Xorshift.zig");

pub fn renderLoop(window: *c.GLFWwindow) !void {
  var particles = std.ArrayList(c.vec3).init(std.heap.c_allocator);
  defer particles.deinit();

  try perfectGrid(&particles, 200);
  // try uniformlyRandomSphere(&particles, 8_000_000);

  // ---

  const vs = @embedFile("shaders/particles/vertex.glsl");
  const fs = @embedFile("shaders/particles/fragment.glsl");
  const program = try gl.Program.init(vs, fs);
  defer program.deinit();

  const a_position = program.attribute("aPosition");
  const u_viewport = program.uniform("uViewport");
  const u_mvp = program.uniform("uMVP");

  var vbo: c.GLuint = undefined;
  c.glGenBuffers(1, &vbo);
  defer c.glDeleteBuffers(1, &vbo);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  {
    defer c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    defer c.glBindVertexArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBindVertexArray(vao);

    const size = @intCast(c_longlong, particles.items.len * @sizeOf(c.vec3));
    c.glBufferData(c.GL_ARRAY_BUFFER, size, particles.items.ptr, c.GL_STATIC_DRAW);
    c.glEnableVertexAttribArray(a_position);
    c.glVertexAttribPointer(a_position, 3, c.GL_FLOAT, c.GL_FALSE, 0, null);
  }

  c.glEnable(c.GL_PROGRAM_POINT_SIZE);
  c.glEnable(c.GL_BLEND);
  c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE);
  c.glBlendEquation(c.GL_FUNC_ADD);

  while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
    const t = @floatCast(f32, c.glfwGetTime());

    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetFramebufferSize(window, &width, &height);
    const ratio = @intToFloat(f32, width) / @intToFloat(f32, height);

    var model: c.mat4x4 = undefined;
    c.mat4x4_identity(&model);
    c.mat4x4_rotate_X(&model, &model, 0.003 * t);
    c.mat4x4_rotate_Y(&model, &model, 0.005 * t);
    c.mat4x4_rotate_Z(&model, &model, 0.007 * t);

    const eye = c.vec3{ 0, 0, 0.5 };
    const target = c.vec3{ 0, 0, 0 };
    const up = c.vec3{ 0, 1, 0 };
    var view: c.mat4x4 = undefined;
    c.mat4x4_look_at(&view, &eye, &target, &up);

    var proj: c.mat4x4 = undefined;
    c.mat4x4_perspective(&proj, 30.0 / 360.0 * std.math.tau, ratio, 1e-5, 1e1);

    var mvp: c.mat4x4 = undefined;
    c.mat4x4_identity(&mvp);
    c.mat4x4_mul(&mvp, &model, &mvp);
    c.mat4x4_mul(&mvp, &view, &mvp);
    c.mat4x4_mul(&mvp, &proj, &mvp);

    c.glClear(c.GL_COLOR_BUFFER_BIT);
    c.glUseProgram(program.id);
    defer c.glUseProgram(0);
    c.glUniform2i(u_viewport, width, height);
    c.glUniformMatrix4fv(u_mvp, 1, c.GL_FALSE, @ptrCast([*c]const f32, &mvp));
    c.glBindVertexArray(vao);
    defer c.glBindVertexArray(0);
    c.glDrawArrays(c.GL_POINTS, 0, @intCast(c_int, particles.items.len));

    c.glfwSwapBuffers(window);
    c.glfwPollEvents();
  }
}

fn perfectGrid(particles: *std.ArrayList(c.vec3), comptime n: comptime_int) !void {
  try particles.ensureTotalCapacity(n * n * n);
  var x: f32 = 0.5; while (x < n) : (x += 1) {
    var y: f32 = 0.5; while (y < n) : (y += 1) {
      var z: f32 = 0.5; while (z < n) : (z += 1) {
        var v: c.vec3 = .{ x, y, z };
        c.vec3_scale(&v, &v, 1 / @as(f32, n));
        c.vec3_sub(&v, &v, &c.vec3{ 0.5, 0.5, 0.5 });
        try particles.append(v);
      }
    }
  }
}

fn uniformlyRandomSphere(particles: *std.ArrayList(c.vec3), comptime n: comptime_int) !void {
  try particles.ensureTotalCapacity(n);
  var xs = Xorshift{};
  while (particles.items.len < n) {
    const x = @floatCast(f32, xs.next(f64) - 0.5);
    const y = @floatCast(f32, xs.next(f64) - 0.5);
    const z = @floatCast(f32, xs.next(f64) - 0.5);
    var v: c.vec3 = .{ x, y, z };
    if (c.vec3_len(&v) < 0.5)
      try particles.append(v);
  }
}
