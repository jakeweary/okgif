const c = @import("../c.zig");
const std = @import("std");
const gl = @import("gl.zig");
const Self = @This();

id: c.GLuint,

pub fn init(kind: c.GLenum, source: []const c.GLchar) !Self {
  const self = Self{ .id = c.glCreateShader(kind) };
  errdefer self.deinit();

  const version = "#version 460\n";
  const ptrs = [_][*]const c.GLchar{ version, source.ptr };
  const lens = [_]c.GLint{ version.len, @intCast(c.GLint, source.len) };
  c.glShaderSource(self.id, ptrs.len, &ptrs, &lens);

  var status: c.GLint = undefined;
  c.glCompileShader(self.id);
  c.glGetShaderiv(self.id, c.GL_COMPILE_STATUS, &status);

  if (status == c.GL_FALSE) {
    var line_n: usize = 2;
    var lines = std.mem.split(u8, source, "\n");
    while (lines.next()) |line| : (line_n += 1)
      gl.log.debug("{:0>3}: {s}", .{ line_n, line });

    var info: [0x400:0]c.GLchar = undefined;
    c.glGetShaderInfoLog(self.id, info.len, null, &info);
    gl.log.err("{s}", .{ @as([*:0]c.GLchar, &info) });

    return error.GL_CompileShaderError;
  }

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteShader(self.id);
}
