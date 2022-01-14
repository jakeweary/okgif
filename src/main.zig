const c = @import("c.zig");
const std = @import("std");
const util = @import("util.zig");
const av = @import("av/av.zig");
const gl = @import("gl/gl.zig");
const stb = @import("stb/stb.zig");

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

  const p_convert = try blk: {
    const vs = @embedFile("glsl/convert/vertex.glsl");
    const fs = @embedFile("glsl/convert/fragment.glsl");
    break :blk gl.Program.init(vs, srgb ++ oklab ++ fs);
  };
  defer p_convert.deinit();

  const p_update = try blk: {
    const vs = @embedFile("glsl/update/vertex.glsl");
    const fs = @embedFile("glsl/update/fragment.glsl");
    break :blk gl.Program.init(kmeans ++ vs, fs);
  };
  defer p_update.deinit();

  const p_reseed = try blk: {
    const vs = @embedFile("glsl/reseed/vertex.glsl");
    const fs = @embedFile("glsl/reseed/fragment.glsl");
    break :blk gl.Program.init(vs, hashes ++ fs);
  };
  defer p_reseed.deinit();

  const p_render = try blk: {
    const vs = @embedFile("glsl/render/vertex.glsl");
    const fs = @embedFile("glsl/render/fragment.glsl");
    break :blk gl.Program.init(vs, kmeans ++ srgb ++ oklab ++ fs);
  };
  defer p_render.deinit();

  // ---

  const K = 64;
  var means = std.mem.zeroes([4 * K]c.GLfloat);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  var fbo: c.GLuint = undefined;
  c.glGenFramebuffers(1, &fbo);
  defer c.glDeleteFramebuffers(1, &fbo);

  var textures: [5]c.GLuint = undefined;
  c.glGenTextures(textures.len, &textures);
  defer c.glDeleteTextures(textures.len, &textures);

  const t_means = textures[0..2];
  const t_source = textures[2];
  const t_converted = textures[3];
  const t_noise = textures[4];

  {
    const png = @embedFile("../deps/blue_noise.png");
    const noise = try stb.Image.fromMemory(png);
    defer noise.deinit();

    defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

    for (textures) |texture| {
      c.glBindTexture(c.GL_TEXTURE_2D, texture);
      gl.textureFilterNearest();
    }

    for (t_means) |texture| {
      c.glBindTexture(c.GL_TEXTURE_2D, texture);
      c.glTexImage2D(c.GL_TEXTURE_2D, 0,
        c.GL_RGBA32F, K, 1, 0, c.GL_RGBA, c.GL_FLOAT, null);
    }

    c.glBindTexture(c.GL_TEXTURE_2D, t_converted);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_RGB32F, resizer.frame.width, resizer.frame.height, 0,
      c.GL_RGB, c.GL_FLOAT, null);

    c.glBindTexture(c.GL_TEXTURE_2D, t_noise);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_RGBA8, @intCast(c.GLint, noise.width), @intCast(c.GLint, noise.height), 0,
      c.GL_RGBA, c.GL_UNSIGNED_BYTE, noise.data.ptr);
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

        // step 0: convert to sRGB
        const resized = try resizer.resize(frame);
        const row_length = @divExact(resizer.frame.linesize[0], 3);

        // step 1: convert to Oklab
        {
          defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
          c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
          c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_converted, 0);

          defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
          c.glBindTexture(c.GL_TEXTURE_2D, t_source);
          c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, row_length);
          c.glTexImage2D(c.GL_TEXTURE_2D, 0,
            c.GL_SRGB8, resized.width, resized.height, 0,
            c.GL_RGB, c.GL_UNSIGNED_BYTE, resized.data[0]);

          defer c.glUseProgram(0);
          c.glUseProgram(p_convert.id);
          c.glUniform1i(p_convert.uniform("tFrame"), 0);

          c.glViewport(0, 0, resized.width, resized.height);
          c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        }

        // step 2: update means
        {
          defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
          c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
          c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_means[0], 0);

          defer c.glDisable(c.GL_BLEND);
          c.glEnable(c.GL_BLEND);
          c.glBlendFunc(c.GL_ONE, c.GL_ONE);

          c.glBindTextureUnit(0, t_converted);

          defer c.glUseProgram(0);
          c.glUseProgram(p_update.id);
          c.glUniform1i(p_update.uniform("tFrame"), 0);
          c.glUniform4fv(p_update.uniform("uMeans"), K, &means);

          c.glViewport(0, 0, K, 1);
          c.glClear(c.GL_COLOR_BUFFER_BIT);
          c.glDrawArrays(c.GL_POINTS, 0, resized.width * resized.height);
        }

        // step 3: reseed and read means
        {
          defer c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
          c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
          c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_means[1], 0);

          c.glBindTextureUnit(0, t_converted);
          c.glBindTextureUnit(1, t_means[0]);

          defer c.glUseProgram(0);
          c.glUseProgram(p_reseed.id);
          c.glUniform1i(p_reseed.uniform("tFrame"), 0);
          c.glUniform1i(p_reseed.uniform("tMeans"), 1);
          c.glUniform1f(p_reseed.uniform("uTime"), @floatCast(c.GLfloat, c.glfwGetTime()));

          c.glViewport(0, 0, K, 1);
          c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
          c.glReadPixels(0, 0, K, 1, c.GL_RGBA, c.GL_FLOAT, &means);
        }

        // step 4: render gif preview
        {
          defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);
          c.glEnable(c.GL_FRAMEBUFFER_SRGB);

          c.glBindTextureUnit(0, t_converted);
          c.glBindTextureUnit(1, t_means[1]);
          c.glBindTextureUnit(2, t_noise);

          defer c.glUseProgram(0);
          c.glUseProgram(p_render.id);
          c.glUniform1i(p_render.uniform("tFrame"), 0);
          c.glUniform1i(p_render.uniform("tMeans"), 1);
          c.glUniform1i(p_render.uniform("tNoise"), 2);
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
