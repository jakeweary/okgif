const c = @import("../c.zig");
const glfw = @import("glfw.zig");

pub fn onError(code: c_int, desc: [*c]const u8) callconv(.C) void {
  glfw.log.err("{s} ({})", .{ desc, code });
}

pub fn onKey(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
  if (action == c.GLFW_PRESS and key == c.GLFW_KEY_ESCAPE)
    c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
}
