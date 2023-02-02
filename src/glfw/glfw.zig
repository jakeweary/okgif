const c = @import("../c.zig");
const std = @import("std");

pub const log = std.log.scoped(.glfw);
pub const Rect = @import("Rect.zig");
pub const Window = @import("Window.zig");

pub fn init(hints: []const [2]c_int) !void {
  _ = c.glfwSetErrorCallback(onError);

  for (hints) |*hint|
    c.glfwInitHint(hint[0], hint[1]);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFW_InitError;
}

pub fn deinit() void {
  c.glfwTerminate();
}

pub fn onError(code: c_int, desc: [*c]const u8) callconv(.C) void {
  log.err("{s} ({})", .{ desc, code });
}

pub fn windowUserPointerUpcast(T: anytype, window: ?*c.GLFWwindow) *T {
  const ptr_opaque = c.glfwGetWindowUserPointer(window);
  const ptr_aligned = @alignCast(@alignOf(T), ptr_opaque);
  return @ptrCast(*T, ptr_aligned);
}
