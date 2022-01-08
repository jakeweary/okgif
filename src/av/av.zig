const c = @import("../c.zig");
const std = @import("std");

pub fn strError(errnum: c_int) [c.AV_ERROR_MAX_STRING_SIZE:0]u8 {
  var buf = std.mem.zeroes([c.AV_ERROR_MAX_STRING_SIZE:0]u8);
  std.debug.assert(c.av_strerror(errnum, &buf, buf.len) == 0);
  return buf;
}
