const c = @import("../c.zig");
const gl = @import("gl.zig");
const std = @import("std");
const Self = @This();

pub const TextureLevel = std.meta.Tuple(&.{ c.GLuint, c.GLint });

id: c.GLuint,

pub fn init(attachments: []const TextureLevel) Self {
  @call(.auto, updateViewport, attachments[0]);

  var id: c.GLuint = undefined;
  c.glCreateFramebuffers(1, &id);

  for (attachments) |tuple, i| {
    const att = @intCast(c.GLenum, c.GL_COLOR_ATTACHMENT0 + i);
    c.glNamedFramebufferDrawBuffer(id, att);
    c.glNamedFramebufferTexture(id, att, tuple[0], tuple[1]);
  }

  c.glBindFramebuffer(c.GL_FRAMEBUFFER, id);
  return .{ .id = id };
}

pub fn deinit(self: *const Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
  c.glDeleteFramebuffers(1, &self.id);
}

fn updateViewport(texture: c.GLuint, level: c.GLint) void {
  var size: struct { w: c.GLsizei, h: c.GLsizei } = undefined;
  c.glGetTextureLevelParameteriv(texture, level, c.GL_TEXTURE_WIDTH, &size.w);
  c.glGetTextureLevelParameteriv(texture, level, c.GL_TEXTURE_HEIGHT, &size.h);
  c.glViewport(0, 0, size.w, size.h);
}
