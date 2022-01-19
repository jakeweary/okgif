const std = @import("std");
const TypeInfo = std.builtin.TypeInfo;

pub fn Optional(comptime T: type) type {
  return @Type(TypeInfo{ .Optional = .{ .child = T } });
}

pub fn optional(arg: anytype) Optional(@TypeOf(arg)) {
  return arg;
}

pub fn range(len: usize) []const void {
  return @as([*]void, undefined)[0..len];
}

pub fn scaleToArea(area: f64, width: c_int, height: c_int) struct { width: c_int, height: c_int } {
  const w = @intToFloat(f64, width);
  const h = @intToFloat(f64, height);
  const s = @sqrt(area / w / h);
  return .{ .width = @floatToInt(c_int, s * w), .height = @floatToInt(c_int, s * h) };
}

pub fn palette(comptime n: usize) [n][3]u8 {
  var colors: [n][3]u8 = undefined;
  for (colors) |*rgb, i| {
    const pos = .{ .x = i % 16, .y = i / 16 };
    rgb.* = .{
      @truncate(u8, (pos.x % 8) * 255 / 7),
      @truncate(u8, (pos.y % 4) * 255 / 3),
      @truncate(u8, (pos.x / 8 + pos.y / 4 * 2) * 255 / 7),
    };
  }
  return colors;
}
