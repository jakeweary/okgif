const c = @import("../c.zig");
const std = @import("std");

pub const FrameResizer = @import("FrameResizer.zig");
pub const VideoDecoder = @import("VideoDecoder.zig");
pub const GifEncoder = @import("GifEncoder.zig");
pub const log = std.log.scoped(.av);

pub fn checkNull(arg: anytype) !void {
  if (arg == null)
    return error.AV_Null;
}

pub fn checkError(arg: c_int) !void {
  if (arg < 0) {
    var buf: [c.AV_ERROR_MAX_STRING_SIZE:0]u8 = undefined;
    std.debug.assert(c.av_strerror(arg, &buf, buf.len) == 0);
    log.err("{s}", .{ @as([*:0]u8, &buf) });
    return error.AV_Error;
  }
}

pub fn imageCopyToBuffer(frame: *c.AVFrame, buffer: *std.ArrayList(u8)) !void {
  const size = c.av_image_get_buffer_size(frame.format, frame.width, frame.height, 1);
  try checkError(size);
  try buffer.ensureTotalCapacity(@intCast(usize, size));

  try checkError(c.av_image_copy_to_buffer(buffer.items.ptr, size,
    &frame.data, &frame.linesize, frame.format, frame.width, frame.height, 1));
}
