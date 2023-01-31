const c = @import("../c.zig");
const std = @import("std");
const fns = @import("fns.zig");

pub const log = std.log.scoped(.glfw);
pub const Rect = @import("Rect.zig");
pub const Window = @import("Window.zig");

pub fn init(hints: []const [2]c_int) !void {
  _ = c.glfwSetErrorCallback(fns.onError);

  for (hints) |*hint|
    c.glfwInitHint(hint[0], hint[1]);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFW_InitError;
}

pub fn deinit() void {
  c.glfwTerminate();
}
