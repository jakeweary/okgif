const std = @import("std");
const Self = @This();

n: u64 = 0x7466696873726f78,

pub fn next(self: *Self, comptime T: type) T {
  switch (T) {
    u64 => {
      self.n ^= self.n << 13;
      self.n ^= self.n >> 7;
      self.n ^= self.n << 17;
      return self.n;
    },
    f64 => {
      const u = self.next(u64);
      const f = 0x3ff << 52 | u >> 12;
      return @bitCast(f64, f) - 1;
    },
    else => @compileError("unsupported type: " ++ @typeName(T))
  }
}

test "next u64" {
  var xs = Self{};
  try std.testing.expectEqual(@as(u64, 0x5ba9940899ac55a6), xs.next(u64));
  try std.testing.expectEqual(@as(u64, 0xc59c044e2024a48d), xs.next(u64));
  try std.testing.expectEqual(@as(u64, 0x920ba872fcd46e84), xs.next(u64));
  try std.testing.expectEqual(@as(u64, 0x1ec4bfca6f54e759), xs.next(u64));
  try std.testing.expectEqual(@as(u64, 0x9ba6ed75c3f6b8d7), xs.next(u64));
}

test "next f64" {
  var xs = Self{};
  try std.testing.expectEqual(@as(f64, 3.5805630884139930e-01), xs.next(f64));
  try std.testing.expectEqual(@as(f64, 7.7191187770235330e-01), xs.next(f64));
  try std.testing.expectEqual(@as(f64, 5.7049038703265030e-01), xs.next(f64));
  try std.testing.expectEqual(@as(f64, 1.2018965427644757e-01), xs.next(f64));
  try std.testing.expectEqual(@as(f64, 6.0801586270460000e-01), xs.next(f64));
}
