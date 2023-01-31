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

fbo: c.GLuint,
len: usize,

pub fn attach(fbo: c.GLuint, attachments: []const TextureLevel) Self {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
  for (attachments) |tuple, i|
    c.glNamedFramebufferTexture(fbo, enums[i], tuple[0], tuple[1]);
  c.glNamedFramebufferDrawBuffers(fbo, @intCast(c.GLsizei, attachments.len), &enums);
  updateViewport(attachments[0]);
  return .{ .fbo = fbo, .len = attachments.len };
}

pub fn detach(self: *const Self) void {
  c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
  for (enums[0..self.len]) |e|
    c.glNamedFramebufferTexture(self.fbo, e, 0, 0);
}

fn updateViewport(tuple: TextureLevel) void {
  var size: struct { w: c.GLsizei, h: c.GLsizei } = undefined;
  c.glGetTextureLevelParameteriv(tuple[0], tuple[1], c.GL_TEXTURE_WIDTH, &size.w);
  c.glGetTextureLevelParameteriv(tuple[0], tuple[1], c.GL_TEXTURE_HEIGHT, &size.h);
  c.glViewport(0, 0, size.w, size.h);
}
