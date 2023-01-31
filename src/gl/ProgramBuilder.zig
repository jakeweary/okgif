const c = @import("../c.zig");
const gl = @import("gl.zig");
const root = @import("root");
const std = @import("std");
const Self = @This();

id: c.GLuint,

pub fn init() Self {
  return Self{ .id = c.glCreateProgram() };
}

pub fn attach(self: *const Self, kind: c.GLenum, sources: []const []const c.GLchar) !void {
  errdefer c.glDeleteProgram(self.id);

  const shader = try gl.Shader.init(kind, sources);
  defer shader.deinit();

  c.glAttachShader(self.id, shader.id);
}

pub fn link(self: *const Self) !gl.Program {
  errdefer c.glDeleteProgram(self.id);

  gl.log.debug("linking program: {}", .{ self.id });
  c.glLinkProgram(self.id);
  try self.checkError();
  try self.logActiveResources();

  return gl.Program{ .id = self.id };
}

fn checkError(self: *const Self) !void {
  var status: c.GLint = undefined;
  c.glGetProgramiv(self.id, c.GL_LINK_STATUS, &status);

  if (status == c.GL_FALSE) {
    const stderr = std.io.getStdErr().writer();

    var info_len: c.GLint = undefined;
    c.glGetProgramiv(self.id, c.GL_INFO_LOG_LENGTH, &info_len);

    var info = try root.allocator.alloc(c.GLchar, @intCast(usize, info_len));
    defer root.allocator.free(info);

    c.glGetProgramInfoLog(self.id, info_len, null, info.ptr);
    try stderr.print("{s}", .{ @ptrCast([*:0]c.GLchar, info) });

    return error.GL_LinkProgramError;
  }
}

fn logActiveResources(self: *const Self) !void {
  var name = std.ArrayList(u8).init(root.allocator);
  defer name.deinit();

  var keys = [_]c.GLenum{ c.GL_NAME_LENGTH, c.GL_LOCATION };
  var values: [keys.len]c.GLint = undefined;

  const resources = .{
    .{ .kind = "in", .GLenum = c.GL_PROGRAM_INPUT },
    .{ .kind = "out", .GLenum = c.GL_PROGRAM_OUTPUT },
    .{ .kind = "uniform", .GLenum = c.GL_UNIFORM },
  };

  inline for (resources) |r| {
    var i: c.GLuint = 0;
    var n: c.GLint = 0;
    c.glGetProgramInterfaceiv(self.id, r.GLenum, c.GL_ACTIVE_RESOURCES, &n);

    while (i < n) : (i += 1) {
      c.glGetProgramResourceiv(self.id, r.GLenum, i, keys.len, &keys, values.len, null, &values);

      try name.resize(@intCast(usize, values[0]));
      c.glGetProgramResourceName(self.id, r.GLenum, i, values[0], null, name.items.ptr);

      gl.log.debug("layout(location = {}) {s} {s}", .{ values[1], r.kind, name.items });
    }
  }
}
