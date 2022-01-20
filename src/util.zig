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

pub fn rgb685() [0x100][3]u8 {
  var colors: [0x100][3]u8 = undefined;
  for (colors[0..0x10]) |*rgb, i| {
    const vec = @splat(3, (i + 1) * 0xff / 17);
    rgb.* = @truncate(u8, vec);
  }
  for (colors[0x10..]) |*rgb, i| {
    const vec: @Vector(3, usize) = .{
      i % 6 * 0xff / 5,
      i / 6 % 8 * 0xff / 7,
      i / 6 / 8 * 0xff / 4,
    };
    rgb.* = @truncate(u8, vec);
  }
  return colors;
}
