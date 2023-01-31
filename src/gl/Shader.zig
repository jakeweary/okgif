const c = @import("../c.zig");
const gl = @import("gl.zig");
const root = @import("root");
const std = @import("std");
const Self = @This();

id: c.GLuint,

pub fn init(kind: c.GLenum, sources: []const [*:0]const c.GLchar) !Self {
  const self = Self{ .id = c.glCreateShader(kind) };
  errdefer self.deinit();

  gl.log.debug("compiling shader: {}", .{ self.id });
  c.glShaderSource(self.id, @intCast(c.GLint, sources.len), sources.ptr, null);
  c.glCompileShader(self.id);
  try self.checkError();

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteShader(self.id);
}

fn checkError(self: *const Self) !void {
  var status: c.GLint = undefined;
  c.glGetShaderiv(self.id, c.GL_COMPILE_STATUS, &status);

  if (status == c.GL_FALSE) {
    var str = gl.String.init(root.allocator);
    defer str.deinit();

    try self.logSource(&str);
    try self.logError(&str);

    return error.GL_CompileShaderError;
  }
}

fn logSource(self: *const Self, str: *gl.String) !void {
  var len: c.GLint = undefined;
  c.glGetShaderiv(self.id, c.GL_SHADER_SOURCE_LENGTH, &len);

  try str.resize(@intCast(usize, len - 1));
  c.glGetShaderSource(self.id, len, null, str.items.ptr);

  const trimmed = std.mem.trimRight(c.GLchar, str.items, &std.ascii.whitespace);
  const lines_total = std.mem.count(c.GLchar, trimmed, "\n") + 1;
  const digits = @floatToInt(usize, @log10(@intToFloat(f64, lines_total))) + 1;
  var line_n: usize = 1;
  var lines = std.mem.split(c.GLchar, trimmed, "\n");
  while (lines.next()) |line| : (line_n += 1)
    gl.log.err("{:0>[2]}: {s}", .{ line_n, line, digits });
}

fn logError(self: *const Self, str: *gl.String) !void {
  var len: c.GLint = undefined;
  c.glGetShaderiv(self.id, c.GL_INFO_LOG_LENGTH, &len);

  try str.resize(@intCast(usize, len - 1));
  c.glGetShaderInfoLog(self.id, len, null, str.items.ptr);

  const trimmed = std.mem.trimRight(c.GLchar, str.items, &std.ascii.whitespace);
  var lines = std.mem.split(c.GLchar, trimmed, "\n");
  while (lines.next()) |line|
    gl.log.err("{s}", .{ line });
}
