const c = @import("../c.zig");
const std = @import("std");
pub const log = std.log.scoped(.gl);
pub const Shader = @import("Shader.zig");
pub const Program = @import("Program.zig");

pub fn keyCallback(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
  if (action == c.GLFW_PRESS and key == c.GLFW_KEY_ESCAPE)
    c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
}

pub fn windowSizeCallback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
  c.glViewport(0, 0, width, height);
}

pub fn errorCallback(_: c_int, description: [*c]const u8) callconv(.C) void {
  std.debug.panic("GLFW Error: {s}", .{ description });
}

pub fn checkError() !void {
  return switch (c.glGetError()) {
    c.GL_NO_ERROR => {},
    c.GL_INVALID_ENUM => error.InvalidEnum,
    c.GL_INVALID_FRAMEBUFFER_OPERATION => error.InvalidFramebufferOperation,
    c.GL_INVALID_OPERATION => error.InvalidOperation,
    c.GL_INVALID_VALUE => error.InvalidValue,
    c.GL_OUT_OF_MEMORY => error.OutOfMemory,
    c.GL_STACK_OVERFLOW => error.StackOverflow,
    c.GL_STACK_UNDERFLOW => error.StackUnderflow,
    else => unreachable
  };
}

pub fn enableDebugMessages() void {
  var flags: c_int = undefined;
  c.glGetIntegerv(c.GL_CONTEXT_FLAGS, &flags);
  if (flags & c.GL_CONTEXT_FLAG_DEBUG_BIT != 0) {
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glEnable(c.GL_DEBUG_OUTPUT_SYNCHRONOUS);
    c.glDebugMessageCallback(debugMessageCallback, null);
    c.glDebugMessageControl(c.GL_DONT_CARE, c.GL_DONT_CARE, c.GL_DONT_CARE, 0, null, c.GL_TRUE);
  }

  log.info("{s}", .{ c.glGetString(c.GL_VENDOR) });
  log.info("{s}", .{ c.glGetString(c.GL_RENDERER) });
  log.info("OpenGL {s}", .{ c.glGetString(c.GL_VERSION) });
  log.info("GLSL {s}", .{ c.glGetString(c.GL_SHADING_LANGUAGE_VERSION) });
}

pub fn debugMessageCallback(
  source: c.GLenum,
  kind: c.GLenum,
  id: c.GLuint,
  severity: c.GLenum,
  _: c.GLsizei,
  message: [*c]const c.GLchar,
  _: ?*const c.GLvoid
) callconv(.C) void {
  const fmt = "{s} {s} {}: {s}";
  const args = .{
    switch (source) {
      c.GL_DEBUG_SOURCE_API => @as([]const u8, "API"),
      c.GL_DEBUG_SOURCE_WINDOW_SYSTEM => "Window System",
      c.GL_DEBUG_SOURCE_SHADER_COMPILER => "Shader Compiler",
      c.GL_DEBUG_SOURCE_THIRD_PARTY => "Third Party",
      c.GL_DEBUG_SOURCE_APPLICATION => "Application",
      c.GL_DEBUG_SOURCE_OTHER => "Other",
      else => unreachable
    },
    switch (kind) {
      c.GL_DEBUG_TYPE_ERROR => @as([]const u8, "Error"),
      c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR => "Deprecated Behavior",
      c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR => "Undefined Behavior",
      c.GL_DEBUG_TYPE_PORTABILITY => "Portability",
      c.GL_DEBUG_TYPE_PERFORMANCE => "Performance",
      c.GL_DEBUG_TYPE_MARKER => "Marker",
      c.GL_DEBUG_TYPE_PUSH_GROUP => "Push Group",
      c.GL_DEBUG_TYPE_POP_GROUP => "Pop Group",
      c.GL_DEBUG_TYPE_OTHER => "Other",
      else => unreachable
    },
    id,
    message
  };

  switch (severity) {
    c.GL_DEBUG_SEVERITY_HIGH => log.err(fmt, args),
    c.GL_DEBUG_SEVERITY_MEDIUM => log.warn(fmt, args),
    c.GL_DEBUG_SEVERITY_LOW => log.info(fmt, args),
    c.GL_DEBUG_SEVERITY_NOTIFICATION => log.debug(fmt, args),
    else => unreachable
  }
}
