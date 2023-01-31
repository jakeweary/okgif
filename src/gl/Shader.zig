const c = @import("../c.zig");
const gl = @import("gl.zig");
const root = @import("root");
const std = @import("std");
const util = @import("../util.zig");
const Self = @This();

id: c.GLuint,

pub fn init(kind: c.GLenum, sources: []const []const c.GLchar) !Self {
  const source = try joinShaderSources(root.allocator, sources);
  defer root.allocator.free(source);

  const self = Self{ .id = c.glCreateShader(kind) };
  errdefer self.deinit();

  gl.log.debug("compiling shader: {}", .{ self.id });
  c.glShaderSource(self.id, 1, &source.ptr, &@intCast(c.GLint, source.len));
  c.glCompileShader(self.id);
  try self.checkError(source);

  return self;
}

pub fn deinit(self: *const Self) void {
  c.glDeleteShader(self.id);
}

fn checkError(self: *const Self, source: []const c.GLchar) !void {
  var status: c.GLint = undefined;
  c.glGetShaderiv(self.id, c.GL_COMPILE_STATUS, &status);

  if (status == c.GL_FALSE) {
    var line_n: usize = 1;
    var lines = util.splitLines(source);
    while (lines.next()) |line| : (line_n += 1)
      gl.log.debug("{:0>4}: {s}", .{ line_n, line });

    var info_len: c.GLint = undefined;
    c.glGetShaderiv(self.id, c.GL_INFO_LOG_LENGTH, &info_len);

    var info = try root.allocator.alloc(c.GLchar, @intCast(usize, info_len));
    defer root.allocator.free(info);

    c.glGetShaderInfoLog(self.id, info_len, null, info.ptr);
    gl.log.err("{s}", .{ @ptrCast([*:0]c.GLchar, info) });

    return error.GL_CompileShaderError;
  }
}

fn joinShaderSources(allocator: std.mem.Allocator, sources: []const []const u8) ![]const u8 {
  var acc = std.ArrayList(u8).init(allocator);
  defer acc.deinit();

  const w = acc.writer();
  try w.print("#version {}{}0 core\n\n", .{ gl.major, gl.minor });
  for (sources) |source| try w.print("{s}\n", .{ source });

  return acc.toOwnedSlice();
}
