const c = @import("c.zig");
const std = @import("std");
const util = @import("util.zig");
const av = @import("av/av.zig");
const gl = @import("gl/gl.zig");

pub const log_level = .debug;
pub const allocator = std.heap.c_allocator;

fn scaleToArea(area: f64, width: c_int, height: c_int) struct { width: c_int, height: c_int } {
  const w = @intToFloat(f64, width);
  const h = @intToFloat(f64, height);
  const s = @sqrt(area / w / h);
  return .{ .width = @floatToInt(c_int, s * w), .height = @floatToInt(c_int, s * h) };
}

pub fn main() !void {
  if (std.os.argv.len < 2) {
    std.debug.print("Usage: {s} <file>\n", .{ std.os.argv[0] });
    std.os.exit(1);
  }

  const filepath = std.mem.sliceTo(std.os.argv[1], 0);
  const filename = std.fs.path.basename(filepath);

  var decoder = try av.VideoDecoder.init(filepath.ptr);
  defer decoder.deinit();

  const cc = decoder.codec_context;
  const scaled = scaleToArea(960 * 540, cc.width, cc.height);

  var resizer = try av.FrameResizer.init(cc, scaled.width, scaled.height);
  defer resizer.deinit();

  // ---

  _ = c.glfwSetErrorCallback(gl.callbacks.onError);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFW_InitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
  c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  // c.glfwWindowHint(c.GLFW_SAMPLES, 8);
  const window = c.glfwCreateWindow(scaled.width, scaled.height, filename.ptr, null, null)
    orelse return error.GLFW_CreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetWindowSizeCallback(window, gl.callbacks.onWindowSize);
  _ = c.glfwSetKeyCallback(window, gl.callbacks.onKey);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(1);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.debug.enableDebugMessages();

  // ---

  const hashes = @embedFile("glsl/hashes.glsl");
  const kmeans = @embedFile("glsl/kmeans.glsl");
  const oklab = @embedFile("glsl/Oklab.glsl");
  const srgb = @embedFile("glsl/sRGB.glsl");

  const vs1 = @embedFile("glsl/convert/vertex.glsl");
  const fs1 = @embedFile("glsl/convert/fragment.glsl");
  const p_convert = try gl.Program.init(vs1, srgb ++ oklab ++ fs1);
  defer p_convert.deinit();

  const vs2 = @embedFile("glsl/update/vertex.glsl");
  const fs2 = @embedFile("glsl/update/fragment.glsl");
  const p_update = try gl.Program.init(kmeans ++ vs2, fs2);
  defer p_update.deinit();

  const vs3 = @embedFile("glsl/reseed/vertex.glsl");
  const fs3 = @embedFile("glsl/reseed/fragment.glsl");
  const p_reseed = try gl.Program.init(vs3, hashes ++ fs3);
  defer p_reseed.deinit();

  const vs4 = @embedFile("glsl/render/vertex.glsl");
  const fs4 = @embedFile("glsl/render/fragment.glsl");
  const p_render = try gl.Program.init(vs4, hashes ++ kmeans ++ srgb ++ oklab ++ fs4);
  defer p_render.deinit();

  // ---

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  var fbo: c.GLuint = undefined;
  c.glGenFramebuffers(1, &fbo);
  defer c.glDeleteFramebuffers(1, &fbo);

  var textures: [4]c.GLuint = undefined;
  c.glGenTextures(textures.len, &textures);
  defer c.glDeleteTextures(textures.len, &textures);

  const t_source = textures[0];
  const t_converted = textures[1];
  const t_palettes = textures[2..4];

  const K = 64;
  var means = std.mem.zeroes([4 * K]c.GLfloat);

  {
    defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

    for (textures) |texture| {
      c.glBindTexture(c.GL_TEXTURE_2D, texture);
      gl.textureFilterNearest();
      gl.textureClampToEdges();
    }

    for (t_palettes) |texture| {
      c.glBindTexture(c.GL_TEXTURE_2D, texture);
      c.glTexImage2D(c.GL_TEXTURE_2D, 0,
        c.GL_RGBA32F, K, 1, 0,
        c.GL_RGBA, c.GL_FLOAT, null);
    }

    c.glBindTexture(c.GL_TEXTURE_2D, t_converted);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_RGB32F, resizer.frame.width, resizer.frame.height, 0,
      c.GL_RGB, c.GL_FLOAT, null);
  }

  while (try decoder.readFrame()) {
    defer c.av_packet_unref(decoder.packet);
    if (decoder.packet.stream_index == decoder.video_stream.index) {
      try decoder.sendPacket();
      while (try decoder.receiveFrame()) |frame| {
        if (c.glfwWindowShouldClose(window) == c.GLFW_TRUE)
          return;

        defer c.glBindVertexArray(0);
        c.glBindVertexArray(vao);

        const time = @floatCast(c.GLfloat, c.glfwGetTime());

        // step 0: convert to sRGB
        const resized = try resizer.resize(frame);
        const row_length = @divExact(resizer.frame.linesize[0], 3);

        // step 1: convert to Oklab
        {
          defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
          c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
          c.glFramebufferTexture2D(c.GL_FRAMEBUFFER,
            c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, t_converted, 0);

          defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
          c.glBindTexture(c.GL_TEXTURE_2D, t_source);
          c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, row_length);
          c.glTexImage2D(c.GL_TEXTURE_2D, 0,
            c.GL_SRGB8, resized.width, resized.height, 0,
            c.GL_RGB, c.GL_UNSIGNED_BYTE, resized.data[0]);

          defer c.glUseProgram(0);
          c.glUseProgram(p_convert.id);
          c.glUniform1i(p_convert.uniform("tFrame"), 0);

          c.glViewport(0, 0, scaled.width, scaled.height);
          c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        }

        // step 2: update means
        {
          defer c.glDisable(c.GL_BLEND);
          c.glEnable(c.GL_BLEND);
          c.glBlendFunc(c.GL_ONE, c.GL_ONE);

          defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
          c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
          c.glFramebufferTexture2D(c.GL_FRAMEBUFFER,
            c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, t_palettes[0], 0);

          defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
          c.glBindTexture(c.GL_TEXTURE_2D, t_converted);

          defer c.glUseProgram(0);
          c.glUseProgram(p_update.id);
          c.glUniform1i(p_update.uniform("tFrame"), 0);
          c.glUniform4fv(p_update.uniform("uMeans"), K, &means);

          c.glViewport(0, 0, K, 1);
          c.glClear(c.GL_COLOR_BUFFER_BIT);
          c.glDrawArrays(c.GL_POINTS, 0, scaled.width * scaled.height);
        }

        // step 3: reseed and read means
        {
          defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
          c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
          c.glFramebufferTexture2D(c.GL_FRAMEBUFFER,
            c.GL_COLOR_ATTACHMENT0, c.GL_TEXTURE_2D, t_palettes[1], 0);

          defer c.glActiveTexture(c.GL_TEXTURE0);
          defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
          c.glActiveTexture(c.GL_TEXTURE0);
          c.glBindTexture(c.GL_TEXTURE_2D, t_converted);
          c.glActiveTexture(c.GL_TEXTURE1);
          c.glBindTexture(c.GL_TEXTURE_2D, t_palettes[0]);

          defer c.glUseProgram(0);
          c.glUseProgram(p_reseed.id);
          c.glUniform1i(p_reseed.uniform("tFrame"), 0);
          c.glUniform1i(p_reseed.uniform("tMeans"), 1);
          c.glUniform1f(p_reseed.uniform("uTime"), time);

          c.glViewport(0, 0, K, 1);
          c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
          c.glReadPixels(0, 0, K, 1, c.GL_RGBA, c.GL_FLOAT, &means);
        }

        // step 4: render gif preview
        {
          defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);
          c.glEnable(c.GL_FRAMEBUFFER_SRGB);

          defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
          c.glBindTexture(c.GL_TEXTURE_2D, t_converted);

          defer c.glActiveTexture(c.GL_TEXTURE0);
          defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
          c.glActiveTexture(c.GL_TEXTURE0);
          c.glBindTexture(c.GL_TEXTURE_2D, t_converted);
          c.glActiveTexture(c.GL_TEXTURE1);
          c.glBindTexture(c.GL_TEXTURE_2D, t_palettes[1]);

          defer c.glUseProgram(0);
          c.glUseProgram(p_render.id);
          c.glUniform1i(p_render.uniform("tFrame"), 0);
          c.glUniform1i(p_render.uniform("tMeans"), 1);
          c.glUniform1f(p_render.uniform("uTime"), time);
          c.glUniform4fv(p_render.uniform("uMeans"), K, &means);

          c.glViewport(0, 0, scaled.width, scaled.height);
          c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
      }
    }
  }
}
