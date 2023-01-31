const std = @import("std");
const Type = std.builtin.Type;

pub fn Optional(comptime T: type) type {
  return @Type(Type{ .Optional = .{ .child = T } });
}

pub fn optional(arg: anytype) Optional(@TypeOf(arg)) {
  return arg;
}

pub fn range(len: usize) []const void {
  return @as([*]void, undefined)[0..len];
}

pub fn overwrite(dst: anytype, src: anytype) void {
  inline for (std.meta.fields(@TypeOf(src))) |field|
    @field(dst.*, field.name) = @field(src, field.name);
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

/// Returns a palette of 256 colors in BGRA format
/// 16 levels of true grays and 685 levels of RGB respectively
/// https://en.wikipedia.org/wiki/Palette_(computing)#Master_palette
/// https://en.wikipedia.org/wiki/List_of_software_palettes#6-8-5_levels_RGB
pub fn rgb685() [0x100][4]u8 {
  var palette: [0x100][4]u8 = undefined;
  for (palette[0..0x10]) |*bgra, i| {
    const n = @truncate(u8, (i + 1) * 0xff / 17);
    bgra.* = .{ n, n, n, 0xff };
  }
  for (palette[0x10..]) |*bgra, i| {
    const r = @truncate(u8, i % 6     * 0xff / 5);
    const g = @truncate(u8, i / 6 % 8 * 0xff / 7);
    const b = @truncate(u8, i / 6 / 8 * 0xff / 4);
    bgra.* = .{ b, g, r, 0xff };
  }
  return palette;
}

// pub fn rgb685() [0x100]u32 {
//   var palette: [0x100]u32 = undefined;
//   for (palette[0..0x10]) |*ptr, i| {
//     const n = (i + 1) * 0xff / 17;
//     ptr.* = @truncate(u32, 0xff << 24 | n << 16 | n << 8 | n);
//   }
//   for (palette[0x10..]) |*ptr, i| {
//     const r = i % 6     * 0xff / 5;
//     const g = i / 6 % 8 * 0xff / 7;
//     const b = i / 6 / 8 * 0xff / 4;
//     ptr.* = @truncate(u32, 0xff << 24 | r << 16 | g << 8 | b);
//   }
//   return palette;
// }
