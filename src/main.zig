const std = @import("std");
const App = @import("app/App.zig");

pub const allocator = std.heap.c_allocator;
pub const std_options = struct {
  pub const log_level = std.log.Level.info;
};

pub fn main() !void {
  var app = try App.init();
  defer app.deinit();

  try app.run();
}
