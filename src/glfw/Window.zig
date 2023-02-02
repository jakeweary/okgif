const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("glfw.zig");
const Rect = @import("Rect.zig");
const Self = @This();

ptr: *c.GLFWwindow,
r: Rect = undefined,

pub fn init(w: c_int, h: c_int, title: [*:0]const u8, hints: []const [2]c_int) !Self {
  for (hints) |*hint|
    c.glfwWindowHint(hint[0], hint[1]);

  const ptr = c.glfwCreateWindow(w, h, title, null, null)
    orelse return error.GLFW_CreateWindowError;
  errdefer c.glfwDestroyWindow(ptr);

  c.glfwMakeContextCurrent(ptr);
  if (c.gladLoadGL(c.glfwGetProcAddress) == 0)
    return error.GLAD_LoadError;

  gl.debug.enableDebugMessages();

  return .{ .ptr = ptr };
}

pub fn deinit(self: *const Self) void {
  c.glfwDestroyWindow(self.ptr);
  c.glfwTerminate();
}

pub fn fullscreen(self: *Self) void {
  if (c.glfwGetWindowMonitor(self.ptr) != null)
    return c.glfwSetWindowMonitor(self.ptr, null, self.r.x, self.r.y, self.r.w, self.r.h, 0);

  self.r = Rect.ofWindow(self.ptr);
  const monitor = self.getMonitorWithMaxOverlap();
  const mode: *const c.GLFWvidmode = c.glfwGetVideoMode(monitor);
  c.glfwSetWindowMonitor(self.ptr, monitor, 0, 0, mode.width, mode.height, 0);
}

fn getMonitorWithMaxOverlap(self: *const Self) *c.GLFWmonitor {
  var best: struct {
    overlap: c_int = 0,
    monitor: ?*c.GLFWmonitor = null
  } = .{};

  const wr = Rect.ofWindow(self.ptr);
  for (getMonitors()) |m| {
    const mr = Rect.ofMonitor(m);
    const o = mr.overlap(&wr);
    if (o > best.overlap)
      best = .{ .overlap = o, .monitor = m };
  }

  return best.monitor.?;
}

fn getMonitors() []*c.GLFWmonitor {
  var n: c_int = undefined;
  const ptr = @ptrCast([*]*c.GLFWmonitor, c.glfwGetMonitors(&n));
  return ptr[0..@intCast(usize, n)];
}
