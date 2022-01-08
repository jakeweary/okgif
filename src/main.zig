const c = @import("c.zig");
const std = @import("std");
const gl = @import("gl/gl.zig");
const VideoDecoder = @import("av/VideoDecoder.zig");

pub const log_level = .debug;

pub fn main() !void {
  if (std.os.argv.len < 2) {
    std.debug.print("Usage: {s} <file>\n", .{ std.os.argv[0] });
    std.os.exit(1);
  }

  const file = std.os.argv[1];
  var decoder = try VideoDecoder.init(file);
  defer decoder.deinit();

  // ---

  _ = c.glfwSetErrorCallback(gl.errorCallback);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFWInitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
  c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  // c.glfwWindowHint(c.GLFW_SAMPLES, 8);
  const window = c.glfwCreateWindow(960, 540, file, null, null)
    orelse return error.GLFWCreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetWindowSizeCallback(window, gl.windowSizeCallback);
  _ = c.glfwSetKeyCallback(window, gl.keyCallback);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(1);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.enableDebugMessages();
  // c.glEnable(c.GL_FRAMEBUFFER_SRGB);

  // ---

  const vs = @embedFile("shaders/video/vertex.glsl");
  const fs = @embedFile("shaders/video/fragment.glsl");
  const program = try gl.Program.init(vs, fs);
  defer program.deinit();

  const a_position = program.attribute("aPosition");
  const u_channel_r = program.uniform("uChannelR");
  const u_channel_g = program.uniform("uChannelG");
  const u_channel_b = program.uniform("uChannelB");

  var vbo: c.GLuint = undefined;
  c.glGenBuffers(1, &vbo);
  defer c.glDeleteBuffers(1, &vbo);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  {
    defer c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    defer c.glBindVertexArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBindVertexArray(vao);

    const quad = [_]c.vec2{ .{ 1, 1 }, .{ -1, 1 }, .{ 1, -1 }, .{ -1, -1 } };
    const size = @intCast(c_longlong, @sizeOf(@TypeOf(quad)));
    c.glBufferData(c.GL_ARRAY_BUFFER, size, &quad, c.GL_STATIC_DRAW);
    c.glEnableVertexAttribArray(a_position);
    c.glVertexAttribPointer(a_position, 2, c.GL_FLOAT, c.GL_FALSE, 0, null);
  }

  var textures: [3]c.GLuint = undefined;
  c.glGenTextures(textures.len, &textures);
  defer c.glDeleteTextures(textures.len, &textures);

  for (textures) |texture| {
    defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
  }

  var pixels = std.ArrayList(u8).init(std.heap.c_allocator);
  defer pixels.deinit();

  while (try decoder.readFrame()) {
    defer c.av_packet_unref(decoder.packet);
    if (decoder.packet.stream_index == decoder.video_stream.index) {
      try decoder.sendPacket();
      while (try decoder.receiveFrame()) |frame| {
        if (c.glfwWindowShouldClose(window) == c.GLFW_TRUE)
          return;

        const size = c.av_image_get_buffer_size(frame.format, frame.width, frame.height, 1);
        try pixels.ensureTotalCapacity(@intCast(usize, size));
        _ = c.av_image_copy_to_buffer(pixels.items.ptr, size,
          &frame.data, &frame.linesize, frame.format, frame.width, frame.height, 1);

        defer c.glUseProgram(0);
        defer c.glBindVertexArray(0);
        defer c.glActiveTexture(c.GL_TEXTURE0);
        defer for (textures) |_, index| {
          c.glActiveTexture(@as(c.GLenum, c.GL_TEXTURE0) + @intCast(c.GLenum, index));
          c.glBindTexture(c.GL_TEXTURE_2D, 0);
        };

        var ptr = pixels.items.ptr;
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, textures[0]);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8,
          frame.width, frame.height,
          0, c.GL_RED, c.GL_UNSIGNED_BYTE, ptr);

        ptr += @intCast(usize, frame.width * frame.height);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, textures[1]);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8,
          @divExact(frame.width, 2), @divExact(frame.height, 2),
          0, c.GL_RED, c.GL_UNSIGNED_BYTE, ptr);

        ptr += @divExact(@intCast(usize, frame.width * frame.height), 4);
        c.glActiveTexture(c.GL_TEXTURE2);
        c.glBindTexture(c.GL_TEXTURE_2D, textures[2]);
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_R8,
          @divExact(frame.width, 2), @divExact(frame.height, 2),
          0, c.GL_RED, c.GL_UNSIGNED_BYTE, ptr);

        c.glUseProgram(program.id);
        c.glBindVertexArray(vao);
        c.glUniform1i(u_channel_r, 0);
        c.glUniform1i(u_channel_g, 1);
        c.glUniform1i(u_channel_b, 2);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
      }
    }
  }
}
