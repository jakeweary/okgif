const c = @import("c.zig");
const std = @import("std");
const util = @import("util.zig");
const av = @import("av/av.zig");
const gl = @import("gl/gl.zig");

pub const log_level = .debug;

pub fn main() !void {
  if (std.os.argv.len < 2) {
    std.debug.print("Usage: {s} <file>\n", .{ std.os.argv[0] });
    std.os.exit(1);
  }

  const filepath = std.mem.sliceTo(std.os.argv[1], 0);
  const filename = std.fs.path.basename(filepath);

  var decoder = try av.VideoDecoder.init(filepath.ptr);
  defer decoder.deinit();

  // ---

  _ = c.glfwSetErrorCallback(gl.callbacks.onError);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFWInitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
  c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  // c.glfwWindowHint(c.GLFW_SAMPLES, 8);
  const window = c.glfwCreateWindow(960, 540, filename.ptr, null, null)
    orelse return error.GLFWCreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetWindowSizeCallback(window, gl.callbacks.onWindowSize);
  _ = c.glfwSetKeyCallback(window, gl.callbacks.onKey);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(1);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.debug.enableDebugMessages();
  // c.glEnable(c.GL_FRAMEBUFFER_SRGB);

  // ---

  const vs = @embedFile("shaders/video/vertex.glsl");
  const fs = @embedFile("shaders/video/fragment.glsl");
  const program = try gl.Program.init(vs, fs);
  defer program.deinit();

  const u_rgb = program.uniform("uRGB");

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  var texture: c.GLuint = undefined;
  c.glGenTextures(1, &texture);
  defer c.glDeleteTextures(1, &texture);

  {
    defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);

    gl.textureClampToEdges();
    gl.textureFilterNearest();
  }

  // ---

  var resizer = try av.FrameResizer.init(decoder.codec_context, 960, 540);
  defer resizer.deinit();

  var pixels = std.ArrayList(u8).init(std.heap.c_allocator);
  defer pixels.deinit();

  while (try decoder.readFrame()) {
    defer c.av_packet_unref(decoder.packet);
    if (decoder.packet.stream_index == decoder.video_stream.index) {
      try decoder.sendPacket();
      while (try decoder.receiveFrame()) |frame| {
        if (c.glfwWindowShouldClose(window) == c.GLFW_TRUE)
          return;

        const resized = try resizer.resize(frame);
        try av.imageCopyToBuffer(resized, &pixels);

        defer c.glActiveTexture(c.GL_TEXTURE0);
        defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0,
          c.GL_RGB8, resized.width, resized.height, 0,
          c.GL_RGB, c.GL_UNSIGNED_BYTE, pixels.items.ptr);

        defer c.glUseProgram(0);
        c.glUseProgram(program.id);
        c.glUniform1i(u_rgb, 0);

        defer c.glBindVertexArray(0);
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
      }
    }
  }
}
