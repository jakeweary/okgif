const c = @import("../c.zig");
const gl = @import("gl.zig");
const std = @import("std");
const Self = @This();

pub const TextureLevel = std.meta.Tuple(&.{ c.GLuint, c.GLint });

const enums = init: {
  var buf = [_]c.GLenum{ c.GL_COLOR_ATTACHMENT0 } ** 0x20;
  for (buf) |*ptr, i|
    ptr.* += @intCast(c.GLenum, i);
  break :init buf;
};

id: c.GLuint,
len: usize,

pub fn attach(id: c.GLuint, attachments: []const TextureLevel) Self {
  @call(.auto, updateViewport, attachments[0]);
  for (attachments) |tuple, i|
    c.glNamedFramebufferTexture(id, enums[i], tuple[0], tuple[1]);
  c.glNamedFramebufferDrawBuffers(id, @intCast(c.GLsizei, attachments.len), &enums);
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, id);
  return .{ .id = id, .len = attachments.len };
}

pub fn detach(self: *const Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
  for (enums[0..self.len]) |e|
    c.glNamedFramebufferTexture(self.id, e, 0, 0);
}

fn updateViewport(texture: c.GLuint, level: c.GLint) void {
  var size: struct { w: c.GLsizei, h: c.GLsizei } = undefined;
  c.glGetTextureLevelParameteriv(texture, level, c.GL_TEXTURE_WIDTH, &size.w);
  c.glGetTextureLevelParameteriv(texture, level, c.GL_TEXTURE_HEIGHT, &size.h);
  c.glViewport(0, 0, size.w, size.h);
}
