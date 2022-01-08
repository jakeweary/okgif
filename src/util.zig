const testing = @import("std").testing;
const TypeInfo = @import("std").builtin.TypeInfo;

pub fn Optional(comptime T: type) type {
  return @Type(TypeInfo{ .Optional = .{ .child = T } });
}

pub fn optional(arg: anytype) Optional(@TypeOf(arg)) {
  return arg;
}

pub fn range(len: usize) []const void {
  return @as([*]void, undefined)[0..len];
}
