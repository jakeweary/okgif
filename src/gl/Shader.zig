const c = @import("../c.zig");
const std = @import("std");
const gl = @import("gl.zig");
const Self = @This();

id: c.GLuint,

pub fn init(kind: c.GLenum, source: []const u8) !Self {
  const self = Self{ .id = c.glCreateShader(kind) };
  errdefer self.deinit();

  const source_len = @intCast(c.GLint, source.len);
  c.glShaderSource(self.id, 1, &source.ptr, &source_len);
  c.glCompileShader(self.id);

  var status: c.GLint = undefined;
  c.glGetShaderiv(self.id, c.GL_COMPILE_STATUS, &status);
  if (status == c.GL_FALSE) {
    var line_n: usize = 1;
    var lines = std.mem.split(u8, source, "\n");
    while (lines.next()) |line| : (line_n += 1)
      gl.log.debug("{:0>3}: {s}", .{ line_n, line });

    var info: [0x400:0]c.GLchar = undefined;
    c.glGetShaderInfoLog(self.id, info.len, null, &info);
    gl.log.err("{s}", .{ @as([*:0]c.GLchar, &info) });

    return error.ShaderCompilationError;
  }

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteShader(self.id);
}
