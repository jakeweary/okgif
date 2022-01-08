const c = @import("../c.zig");
const std = @import("std");
const gl = @import("gl.zig");
const Shader = @import("Shader.zig");
const Self = @This();

id: c.GLuint,

pub fn init(vertex: []const u8, fragment: []const u8) !Self {
  const vs = try Shader.init(c.GL_VERTEX_SHADER, vertex);
  errdefer vs.deinit();

  const fs = try Shader.init(c.GL_FRAGMENT_SHADER, fragment);
  errdefer fs.deinit();

  const self = Self{ .id = c.glCreateProgram() };
  errdefer self.deinit();

  c.glAttachShader(self.id, vs.id);
  c.glAttachShader(self.id, fs.id);
  c.glLinkProgram(self.id);

  var status: c.GLint = undefined;
  c.glGetProgramiv(self.id, c.GL_LINK_STATUS, &status);
  if (status == c.GL_FALSE) {
    var info: [0x400:0]c.GLchar = undefined;
    c.glGetProgramInfoLog(self.id, info.len, null, &info);
    gl.log.err("{s}", .{ @as([*:0]c.GLchar, &info) });

    return error.ProgramLinkageError;
  }

  return self;
}

pub fn deinit(self: *const Self) void {
  var shaders: [0x10]c.GLuint = undefined;
  var count: c.GLsizei = undefined;
  c.glGetAttachedShaders(self.id, shaders.len, &count, &shaders);
  c.glDeleteProgram(self.id);
  for (shaders[0..@intCast(usize, count)]) |id|
    c.glDeleteShader(id);
}

pub fn attribute(self: *const Self, name: [:0]const u8) c.GLuint {
  return @intCast(c.GLuint, c.glGetAttribLocation(self.id, name));
}

pub fn uniform(self: *const Self, name: [:0]const u8) c.GLint {
  return c.glGetUniformLocation(self.id, name);
}
