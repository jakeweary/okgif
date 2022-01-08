const Xorshift = @import("Xorshift.zig");

test {
  @import("std").testing.refAllDecls(@This());
}
