const c = @import("../c.zig");
const stb = @import("stb.zig");
const Self = @This();

width: usize,
height: usize,
channels: usize,
data: []u8,

pub fn fromMemory(bytes: []const u8) !Self {
  var w: c_int = undefined;
  var h: c_int = undefined;
  var n: c_int = undefined;

  const len = @intCast(c_int, bytes.len);
  const data = c.stbi_load_from_memory(bytes.ptr, len, &w, &h, &n, 0) orelse {
    stb.log.err("{s}", .{ c.stbi_failure_reason() });
    return error.STB_LoadImageError;
  };

  return Self{
    .width = @intCast(usize, w),
    .height = @intCast(usize, h),
    .channels = @intCast(usize, n),
    .data = data[0..@intCast(usize, w * h * n)],
  };
}

pub fn deinit(self: *const Self) void {
  c.stbi_image_free(self.data.ptr);
}
