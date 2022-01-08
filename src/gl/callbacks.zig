const c = @import("../c.zig");
const std = @import("std");

pub fn onError(_: c_int, description: [*c]const u8) callconv(.C) void {
  std.debug.panic("GLFW Error: {s}", .{ description });
}

pub fn onWindowSize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
  c.glViewport(0, 0, width, height);
}

pub fn onKey(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
  if (action == c.GLFW_PRESS and key == c.GLFW_KEY_ESCAPE)
    c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
}
