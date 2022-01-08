const c = @import("../c.zig");
const std = @import("std");

pub fn strError(errnum: c_int) [c.AV_ERROR_MAX_STRING_SIZE:0]u8 {
  var buf = std.mem.zeroes([c.AV_ERROR_MAX_STRING_SIZE:0]u8);
  std.debug.assert(c.av_strerror(errnum, &buf, buf.len) == 0);
  return buf;
}

pub fn imageCopyToBuffer(frame: *c.AVFrame, buffer: *std.ArrayList(u8)) !void {
  const size = c.av_image_get_buffer_size(frame.format, frame.width, frame.height, 1);
  try buffer.ensureTotalCapacity(@intCast(usize, size));

  const code = c.av_image_copy_to_buffer(buffer.items.ptr, size,
    &frame.data, &frame.linesize, frame.format, frame.width, frame.height, 1);

  if (code < 0) {
    std.log.err("{s}", .{ strError(code) });
    return error.FailedToCopyImageToBuffer;
  }
}
