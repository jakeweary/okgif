const c = @import("../c.zig");
const std = @import("std");
const gl = @import("gl.zig");
const Self = @This();

id: c.GLuint,

pub fn init(vert: []const c.GLchar, frag: []const c.GLchar) !Self {
  const pb = gl.ProgramBuilder.init();
  try pb.attach(c.GL_VERTEX_SHADER, vert);
  try pb.attach(c.GL_FRAGMENT_SHADER, frag);
  return pb.link();
}

pub fn deinit(self: *const Self) void {
  c.glDeleteProgram(self.id);
}

pub fn attribute(self: *const Self, name: [:0]const u8) c.GLuint {
  return @intCast(c.GLuint, c.glGetAttribLocation(self.id, name));
}

pub fn uniform(self: *const Self, name: [:0]const u8) c.GLint {
  return c.glGetUniformLocation(self.id, name);
}
