const c = @import("../c.zig");
const std = @import("std");
const gl = @import("gl.zig");
const Self = @This();

id: c.GLuint,

pub fn init(kind: c.GLenum, source: []const u8) !Self {
  const self = Self{ .id = c.glCreateShader(kind) };
  errdefer self.deinit();

  const sources = [_][*]const u8{source.ptr};
  c.glShaderSource(self.id, 1, sources[0..], null);
  c.glCompileShader(self.id);

  var status: c.GLint = undefined;
  c.glGetShaderiv(self.id, c.GL_COMPILE_STATUS, &status);
  if (status == c.GL_FALSE) {
    var info: [0x1000]c.GLchar = undefined;
    c.glGetShaderInfoLog(self.id, info.len, null, &info);
    gl.log.err("{s}", .{ @as([*c]c.GLchar, &info) });

    var num: usize = 1;
    var lines = std.mem.split(u8, source, "\n");
    while (lines.next()) |line| : (num += 1)
      gl.log.debug("{:0>3}: {s}", .{ num, line });

    return error.ShaderCompilationError;
  }

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteShader(self.id);
}
