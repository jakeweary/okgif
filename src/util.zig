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

pub fn splitLines(input: []const u8) std.mem.SplitIterator(u8) {
  const len = switch (input[input.len - 1]) {
    '\n' => input.len - 1,
    else => input.len
  };
  return std.mem.split(u8, input[0..len], "\n");
}

pub fn scaleToArea(area: f64, width: c_int, height: c_int) struct { width: c_int, height: c_int } {
  const w = @intToFloat(f64, width);
  const h = @intToFloat(f64, height);
  const s = @sqrt(area / w / h);
  return .{ .width = @floatToInt(c_int, s * w), .height = @floatToInt(c_int, s * h) };
}

pub fn rgb685() [0x100][4]u8 {
  var colors: [0x100][4]u8 = undefined;
  for (colors[0..0x10]) |*rgba, i| {
    const n = @truncate(u8, (i + 1) * 0xff / 17);
    rgba.* = .{ n, n, n, 0xff };
  }
  for (colors[0x10..]) |*rgba, i| {
    const r = @truncate(u8, i % 6     * 0xff / 5);
    const g = @truncate(u8, i / 6 % 8 * 0xff / 7);
    const b = @truncate(u8, i / 6 / 8 * 0xff / 4);
    rgba.* = .{ b, g, r, 0xff };
  }
  return colors;
}
