const c = @import("../../c.zig");
const gl = @import("../gl.zig");
const root = @import("root");
const std = @import("std");
const Self = @This();

id: c.GLuint,

pub fn init() Self {
  return .{ .id = c.glCreateProgram() };
}

pub fn attach(self: *const Self, kind: c.GLenum, sources: []const [*:0]const c.GLchar) !void {
  errdefer c.glDeleteProgram(self.id);

  const shader = try gl.Shader.init(kind, sources);
  defer shader.deinit();

  c.glAttachShader(self.id, shader.id);
}

pub fn link(self: *const Self) !c.GLuint {
  errdefer c.glDeleteProgram(self.id);

  var str = gl.String.init(root.allocator);
  defer str.deinit();

  gl.log.debug("linking program: {}", .{ self.id });
  c.glLinkProgram(self.id);
  try self.checkError(&str);

  try self.logActiveResources(&str, c.GL_PROGRAM_INPUT, "in");
  try self.logActiveResources(&str, c.GL_PROGRAM_OUTPUT, "out");
  try self.logActiveResources(&str, c.GL_UNIFORM, "uniform");

  return self.id;
}

fn checkError(self: *const Self, str: *gl.String) !void {
  var status: c.GLint = undefined;
  c.glGetProgramiv(self.id, c.GL_LINK_STATUS, &status);

  if (status == c.GL_FALSE) {
    try self.logError(str);
    return error.GL_LinkProgramError;
  }
}

fn logError(self: *const Self, str: *gl.String) !void {
  var len: c.GLint = undefined;
  c.glGetProgramiv(self.id, c.GL_INFO_LOG_LENGTH, &len);

  if (len > 0) {
    try str.resize(@intCast(usize, len - 1));
    c.glGetProgramInfoLog(self.id, len, null, str.items.ptr);

    const trimmed = std.mem.trimRight(c.GLchar, str.items, &std.ascii.whitespace);
    var lines = std.mem.split(c.GLchar, trimmed, "\n");
    while (lines.next()) |line|
      gl.log.err("{s}", .{ line });
  }
}

fn logActiveResources(self: *const Self, str: *gl.String, kind: c.GLenum, kind_str: []const u8) !void {
  var name_len: c.GLint = undefined;
  c.glGetProgramInterfaceiv(self.id, kind, c.GL_MAX_NAME_LENGTH, &name_len);
  try str.resize(@intCast(usize, name_len));

  var resources: c.GLint = undefined;
  c.glGetProgramInterfaceiv(self.id, kind, c.GL_ACTIVE_RESOURCES, &resources);

  var r: c.GLuint = 0;
  while (r < resources) : (r += 1) {
    const name = @ptrCast([*:0]c.GLchar, str.items.ptr);
    const keys = [_]c.GLenum{ c.GL_LOCATION, c.GL_TYPE, c.GL_ARRAY_SIZE };
    var values: [keys.len]c.GLint = undefined;
    c.glGetProgramResourceiv(self.id, kind, r, keys.len, &keys, values.len, null, &values);
    c.glGetProgramResourceName(self.id, kind, r, name_len, null, name);

    const fmt = "layout(location = {}) {s} {s}[{}] {s}";
    const args = .{ values[0], kind_str, gl.debug.typeToStr(values[1]), values[2], name };
    gl.log.debug(fmt, args);
  }
}
