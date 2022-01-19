const c = @import("../c.zig");
const gl = @import("gl.zig");
const Self = @This();

id: c.GLuint,

pub fn init() Self {
  return Self{ .id = c.glCreateProgram() };
}

pub fn attach(self: *const Self, kind: c.GLenum, source: []const c.GLchar) !void {
  errdefer c.glDeleteProgram(self.id);

  const shader = try gl.Shader.init(kind, source);
  defer shader.deinit();

  c.glAttachShader(self.id, shader.id);
}

pub fn link(self: *const Self) !gl.Program {
  errdefer c.glDeleteProgram(self.id);

  var status: c.GLint = undefined;
  c.glLinkProgram(self.id);
  c.glGetProgramiv(self.id, c.GL_LINK_STATUS, &status);

  if (status == c.GL_FALSE) {
    var info: [0x400:0]c.GLchar = undefined;
    c.glGetProgramInfoLog(self.id, info.len, null, &info);
    gl.log.err("{s}", .{ @as([*:0]c.GLchar, &info) });

    return error.GL_LinkProgramError;
  }

  return gl.Program{ .id = self.id };
}
