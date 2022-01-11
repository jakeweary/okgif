const c = @import("../c.zig");
const std = @import("std");

pub const callbacks = @import("callbacks.zig");
pub const debug = @import("debug.zig");
pub const Shader = @import("Shader.zig");
pub const Program = @import("Program.zig");
pub const log = std.log.scoped(.gl);

pub fn texture(index: anytype) c.GLenum {
  return @as(c.GLenum, c.GL_TEXTURE0) + @intCast(c.GLenum, index);
}

pub fn textureClampToEdges() void {
  c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
  c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
}

pub fn textureFilterNearest() void {
  c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
  c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
}

pub fn textureFilterLinear() void {
  c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
  c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
}
