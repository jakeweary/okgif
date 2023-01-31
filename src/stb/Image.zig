const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const stb = @import("stb.zig");
const Self = @This();

width: usize,
height: usize,
channels: usize,
data: []u8,

pub fn fromMemory(bytes: []const u8) !Self {
  var shape: struct { w: c_int, h: c_int, c: c_int } = undefined;
  const len = @intCast(c_int, bytes.len);
  const data = c.stbi_load_from_memory(bytes.ptr, len, &shape.w, &shape.h, &shape.c, 0) orelse {
    stb.log.err("{s}", .{ c.stbi_failure_reason() });
    return error.STB_LoadImageError;
  };

  return .{
    .width = @intCast(usize, shape.w),
    .height = @intCast(usize, shape.h),
    .channels = @intCast(usize, shape.c),
    .data = data[0..@intCast(usize, shape.w * shape.h * shape.c)],
  };
}

pub fn deinit(self: *const Self) void {
  c.stbi_image_free(self.data.ptr);
}

pub fn uploadToGPU(self: *const Self, id: *c.GLuint, fmt: c.GLenum, params: []const gl.textures.KeyValue) void {
  const storage_formats = [_]c.GLenum{ c.GL_RED, c.GL_RG, c.GL_RGB, c.GL_RGBA };
  const sfmt = storage_formats[self.channels - 1];
  const w = @intCast(c.GLsizei, self.width);
  const h = @intCast(c.GLsizei, self.height);
  gl.textures.init(@as(*[1]c.GLuint, id), fmt, 1, w, h, params);
  c.glTextureSubImage2D(id.*, 0, 0, 0, w, h, sfmt, c.GL_UNSIGNED_BYTE, self.data.ptr);
}
