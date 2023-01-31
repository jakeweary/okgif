const c = @import("../c.zig");
const gl = @import("gl.zig");
const std = @import("std");

pub const KeyValue = std.meta.Tuple(&.{ c.GLenum, c.GLint });

pub fn init(ids: []c.GLuint, fmt: c.GLenum, mips: c.GLsizei, w: c.GLsizei, h: c.GLsizei, params: []const KeyValue) void {
  c.glCreateTextures(c.GL_TEXTURE_2D, @intCast(c.GLsizei, ids.len), ids.ptr);
  for (ids) |id|
    c.glTextureStorage2D(id, mips, fmt, w, h);
  setParams(ids, params);
}

pub fn deinit(ids: []const c.GLuint) void {
  c.glDeleteTextures(@intCast(c.GLsizei, ids.len), ids.ptr);
}

pub fn resize(ids: []c.GLuint, mips: c.GLsizei, w: c.GLsizei, h: c.GLsizei, params: []const KeyValue) void {
  var fmt: c.GLint = undefined;
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_INTERNAL_FORMAT, &fmt);

  deinit(ids);
  init(ids, @intCast(c.GLenum, fmt), mips, w, h, params);
}

pub fn resizeIfChanged(ids: []c.GLuint, mips: c.GLsizei, w: c.GLsizei, h: c.GLsizei, params: []const KeyValue) bool {
  var self: struct { mips: c.GLsizei, w: c.GLsizei, h: c.GLsizei } = undefined;
  c.glGetTextureParameteriv(ids[0], c.GL_TEXTURE_IMMUTABLE_LEVELS, &self.mips);
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_WIDTH, &self.w);
  c.glGetTextureLevelParameteriv(ids[0], 0, c.GL_TEXTURE_HEIGHT, &self.h);

  const changed = self.mips != mips or self.w != w or self.h != h;
  if (changed) {
    const fmt = "resizing {} textures from {}x{} ({} mips) to {}x{} ({} mips)";
    gl.log.debug(fmt, .{ ids.len, self.w, self.h, self.mips, w, h, mips });
    resize(ids, mips, w, h, params);
  }
  return changed;
}

pub fn setParams(ids: []const c.GLuint, params: []const KeyValue) void {
  for (ids) |id|
    for (params) |kv|
      c.glTextureParameteri(id, kv[0], kv[1]);
}

pub fn swap(pair: *[2]c.GLuint) void {
  std.mem.swap(c.GLuint, &pair[0], &pair[1]);
}
