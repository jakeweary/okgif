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

pub fn setLogLevel(level: std.log.Level) void {
  c.av_log_set_level(switch (level) {
    .err => c.AV_LOG_ERROR,
    .warn => c.AV_LOG_WARNING,
    .info => c.AV_LOG_INFO,
    .debug => c.AV_LOG_DEBUG,
  });
}

// fn logCallback(avcl: ?*anyopaque, level: c_int, fmt: [*c]const u8, args: c.va_list) callconv(.C) void {
//   const name: [*:0]const u8 = if (avcl) |ptr| c.av_default_item_name(ptr) else "";

//   var buf: [0x10000]u8 = undefined;
//   const len = c.vsnprintf(&buf, buf.len, fmt, args);
//   const str = buf[0..@intCast(usize, len - 1)];

//   switch (level) {
//     c.AV_LOG_ERROR,
//     c.AV_LOG_FATAL,
//     c.AV_LOG_PANIC => log.err("{s}", .{ str }),
//     c.AV_LOG_WARNING => log.warn("{s}", .{ str }),
//     c.AV_LOG_INFO => log.info("{s}", .{ str }),
//     c.AV_LOG_DEBUG,
//     c.AV_LOG_TRACE,
//     c.AV_LOG_VERBOSE => log.debug("{s}", .{ str }),
//     else => unreachable
//   }
// }
