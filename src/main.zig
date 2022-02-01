const c = @import("c.zig");
const std = @import("std");
const util = @import("util.zig");
const av = @import("av/av.zig");
const gl = @import("gl/gl.zig");
const stb = @import("stb/stb.zig");

pub const log_level = std.log.Level.info;
pub const allocator = std.heap.c_allocator;

pub fn main() !void {
  av.setLogLevel(log_level);

  if (std.os.argv.len < 2) {
    std.debug.print("Usage: {s} <file>\n", .{ std.os.argv[0] });
    std.os.exit(1);
  }

  const filepath = std.mem.sliceTo(std.os.argv[1], 0);
  const filename = std.fs.path.basename(filepath);

  var decoder = try av.VideoDecoder.init(filepath.ptr);
  defer decoder.deinit();

  const cc = decoder.codec_context;
  const scaled = util.scaleToArea(166320, cc.width, cc.height);
  // const scaled = util.scaleToArea(332640, cc.width, cc.height);
  // const scaled = util.scaleToArea(720720, cc.width, cc.height);
  // const scaled = .{ .width = 400, .height = 225 };

  var encoder = try av.GifEncoder.init("test.gif", scaled.width, scaled.height);
  defer encoder.deinit();

  var resizer = try av.FrameResizer.init(cc, scaled.width, scaled.height);
  defer resizer.deinit();

  // ---

  _ = c.glfwSetErrorCallback(gl.callbacks.onError);

  if (c.glfwInit() == c.GLFW_FALSE)
    return error.GLFW_InitError;
  defer c.glfwTerminate();

  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, gl.major);
  c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, gl.minor);
  c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
  c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
  const window = c.glfwCreateWindow(scaled.width, scaled.height, filename.ptr, null, null)
    orelse return error.GLFW_CreateWindowError;
  defer c.glfwDestroyWindow(window);

  _ = c.glfwSetWindowSizeCallback(window, gl.callbacks.onWindowSize);
  _ = c.glfwSetKeyCallback(window, gl.callbacks.onKey);
  c.glfwMakeContextCurrent(window);
  c.glfwSwapInterval(0);
  _ = c.gladLoadGL(c.glfwGetProcAddress);

  gl.debug.enableDebugMessages();

  // ---

  const hashes = @embedFile("glsl/lib/hashes.glsl");
  const kmeans = @embedFile("glsl/lib/kmeans.glsl");
  const oklab = @embedFile("glsl/lib/Oklab.glsl");
  const srgb = @embedFile("glsl/lib/sRGB.glsl");
  const ucs = @embedFile("glsl/lib/UCS.glsl");

  const p_convert_rgb = try blk: {
    const vs = @embedFile("glsl/pass/convert_YCbCr_sRGB/vertex.glsl");
    const fs = @embedFile("glsl/pass/convert_YCbCr_sRGB/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ srgb, fs });
  };
  defer p_convert_rgb.deinit();

  const p_convert_ucs = try blk: {
    const vs = @embedFile("glsl/pass/convert_sRGB_UCS/vertex.glsl");
    const fs = @embedFile("glsl/pass/convert_sRGB_UCS/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ srgb, oklab, ucs, fs });
  };
  defer p_convert_ucs.deinit();

  const p_means_update = try blk: {
    const vs = @embedFile("glsl/pass/means_update/vertex.glsl");
    const fs = @embedFile("glsl/pass/means_update/fragment.glsl");
    break :blk gl.Program.init(&.{ kmeans, vs }, &.{ fs });
  };
  defer p_means_update.deinit();

  const p_means_reseed = try blk: {
    const vs = @embedFile("glsl/pass/means_reseed/vertex.glsl");
    const fs = @embedFile("glsl/pass/means_reseed/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ hashes, fs });
  };
  defer p_means_reseed.deinit();

  const p_quantize = try blk: {
    const vs = @embedFile("glsl/pass/quantize/vertex.glsl");
    const fs = @embedFile("glsl/pass/quantize/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ kmeans, fs });
  };
  defer p_quantize.deinit();

  const p_preview = try blk: {
    const vs = @embedFile("glsl/pass/preview/vertex.glsl");
    const fs = @embedFile("glsl/pass/preview/fragment.glsl");
    break :blk gl.Program.init(&.{ vs }, &.{ srgb, oklab, ucs, fs });
  };
  defer p_preview.deinit();

  // ---

  const K = 256;
  var means = std.mem.zeroes([K][4]c.GLfloat);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);

  var fbo: c.GLuint = undefined;
  c.glGenFramebuffers(1, &fbo);
  defer c.glDeleteFramebuffers(1, &fbo);

  var textures: [9]c.GLuint = undefined;
  c.glGenTextures(textures.len, &textures);
  defer c.glDeleteTextures(textures.len, &textures);

  const t_means = textures[0..2];
  const t_ycbcr = textures[2..5];
  const t_rgb = textures[5];
  const t_ucs = textures[6];
  const t_gif = textures[7];
  const t_noise = textures[8];

  {
    const png = @embedFile("../deps/bluenoise/128/LDR_RGB1_0.png");
    const noise = try stb.Image.fromMemory(png);
    defer noise.deinit();

    defer c.glBindTexture(c.GL_TEXTURE_2D, 0);

    for (textures) |id| {
      c.glBindTexture(c.GL_TEXTURE_2D, id);
      gl.textureFilterNearest();
    }

    for (t_ycbcr) |id| {
      c.glBindTexture(c.GL_TEXTURE_2D, id);
      gl.textureFilterLinear();
    }

    for (t_means) |id| {
      c.glBindTexture(c.GL_TEXTURE_2D, id);
      c.glTexImage2D(c.GL_TEXTURE_2D, 0,
        c.GL_RGBA32F, K, 1, 0, c.GL_RGBA, c.GL_FLOAT, null);
    }

    c.glBindTexture(c.GL_TEXTURE_2D, t_ucs);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_RGB32F, scaled.width, scaled.height, 0,
      c.GL_RGB, c.GL_FLOAT, null);

    c.glBindTexture(c.GL_TEXTURE_2D, t_gif);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_R8UI, scaled.width, scaled.height, 0,
      c.GL_RED_INTEGER, c.GL_UNSIGNED_BYTE, null);

    c.glBindTexture(c.GL_TEXTURE_2D, t_noise);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_RGBA8, @intCast(c.GLint, noise.width), @intCast(c.GLint, noise.height), 0,
      c.GL_RGBA, c.GL_UNSIGNED_BYTE, noise.data.ptr);
  }

  // ---

  c.glDisable(c.GL_DITHER);
  c.glBindVertexArray(vao);

  // const lvl = c.av_log_get_level();
  // defer c.av_log_set_level(lvl);
  // c.av_log_set_level(c.AV_LOG_TRACE);

  // ---

  const palette = util.rgb685();

  {
    var texture: c.GLuint = undefined;
    c.glGenTextures(1, &texture);
    defer c.glDeleteTextures(1, &texture);

    defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0,
      c.GL_SRGB8, K, 1, 0,
      c.GL_BGRA, c.GL_UNSIGNED_BYTE, &palette);
    gl.textureFilterNearest();

    c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
    c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_means[1], 0);

    p_convert_ucs.use();
    p_convert_ucs.bindTexture("tFrame", 0, texture);

    c.glViewport(0, 0, K, 1);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    c.glReadPixels(0, 0, K, 1, c.GL_RGBA, c.GL_FLOAT, &means);
  }

  // ---

  var frame_pts: c_int = 0;
  while (try decoder.nextFrame()) |frame| : (frame_pts += 1) {
    if (c.glfwWindowShouldClose(window) == c.GLFW_TRUE)
      return;

    defer c.glfwPollEvents();
    defer c.glfwSwapBuffers(window);
    defer c.glUseProgram(0);

    // step 1: resize and convert to sRGB (on CPU)
    {
      const resized = try resizer.resize(frame);

      defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
      defer c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, 0);
      c.glBindTexture(c.GL_TEXTURE_2D, t_rgb);
      c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, @divExact(resized.linesize[0], 3));
      c.glTexImage2D(c.GL_TEXTURE_2D, 0,
        c.GL_SRGB8, resized.width, resized.height, 0,
        c.GL_RGB, c.GL_UNSIGNED_BYTE, resized.data[0]);
    }

    // // step 1: resize and convert to sRGB (on GPU)
    // {
    //   c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
    //   c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_rgb, 0);

    //   defer c.glBindTexture(c.GL_TEXTURE_2D, 0);
    //   defer c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, 0);

    //   c.glBindTexture(c.GL_TEXTURE_2D, t_rgb);
    //   c.glTexImage2D(c.GL_TEXTURE_2D, 0,
    //     c.GL_SRGB8, scaled.width, scaled.height, 0,
    //     c.GL_RGB, c.GL_UNSIGNED_BYTE, null);

    //   for ([_]c_int{ 1, 2, 2 }) |n, i| {
    //     c.glBindTexture(c.GL_TEXTURE_2D, t_ycbcr[i]);
    //     c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, frame.linesize[i]);
    //     c.glTexImage2D(c.GL_TEXTURE_2D, 0,
    //       c.GL_R8, @divTrunc(frame.width, n), @divTrunc(frame.height, n), 0,
    //       c.GL_RED, c.GL_UNSIGNED_BYTE, frame.data[i]);
    //   }

    //   p_convert_rgb.use();
    //   p_convert_rgb.bindTexture("tY", 0, t_ycbcr[0]);
    //   p_convert_rgb.bindTexture("tCb", 1, t_ycbcr[1]);
    //   p_convert_rgb.bindTexture("tCr", 2, t_ycbcr[2]);

    //   c.glViewport(0, 0, scaled.width, scaled.height);
    //   c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    // }

    // step 2: convert to UCS
    {
      c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
      c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_ucs, 0);

      p_convert_ucs.use();
      p_convert_ucs.bindTexture("tFrame", 0, t_rgb);

      c.glViewport(0, 0, scaled.width, scaled.height);
      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    // // step 3: update means
    // {
    //   c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
    //   c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_means[0], 0);

    //   defer c.glDisable(c.GL_BLEND);
    //   c.glEnable(c.GL_BLEND);
    //   c.glBlendFunc(c.GL_ONE, c.GL_ONE);

    //   p_means_update.use();
    //   p_means_update.bind("uMeans", &means);
    //   p_means_update.bindTexture("tFrame", 0, t_ucs);

    //   c.glViewport(0, 0, K, 1);
    //   c.glClear(c.GL_COLOR_BUFFER_BIT);
    //   c.glDrawArrays(c.GL_POINTS, 0, scaled.width * scaled.height);
    // }

    // // step 4: reseed and read means
    // {
    //   c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
    //   c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_means[1], 0);

    //   p_means_reseed.use();
    //   p_means_reseed.bind("uTime", c.glfwGetTime());
    //   p_means_reseed.bindTexture("tFrame", 0, t_ucs);
    //   p_means_reseed.bindTexture("tMeans", 1, t_means[0]);

    //   c.glViewport(0, 0, K, 1);
    //   c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    //   c.glReadPixels(0, 0, K, 1, c.GL_RGBA, c.GL_FLOAT, &means);

    //   // const T = std.meta.Child(@TypeOf(means));
    //   // const sortFn = struct {
    //   //   fn asc(_: void, a: T, b: T) bool { return a[0] < b[0]; }
    //   // };
    //   // std.sort.sort(T, &means, {}, sortFn.asc);
    // }

    // step 5: quantize
    {
      c.glBindFramebuffer(c.GL_FRAMEBUFFER, fbo);
      c.glNamedFramebufferTexture(fbo, c.GL_COLOR_ATTACHMENT0, t_gif, 0);

      p_quantize.use();
      p_quantize.bind("uMeans", &means);
      p_quantize.bindTexture("tFrame", 0, t_ucs);
      p_quantize.bindTexture("tNoise", 1, t_noise);

      c.glViewport(0, 0, scaled.width, scaled.height);
      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

      var gif_frame = try encoder.allocFrame(&palette);
      defer c.av_frame_free(&util.optional(gif_frame));

      c.glReadPixels(0, 0, scaled.width, scaled.height,
        c.GL_RED_INTEGER, c.GL_UNSIGNED_BYTE, gif_frame.data[0]);
      gif_frame.pts = frame_pts;

      try encoder.encodeFrame(gif_frame);
    }

    // step 6: render gif preview
    {
      c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);

      defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);
      c.glEnable(c.GL_FRAMEBUFFER_SRGB);

      p_preview.use();
      p_preview.bindTexture("tFrame", 0, t_gif);
      p_preview.bindTexture("tMeans", 1, t_means[1]);

      c.glViewport(0, 0, scaled.width, scaled.height);
      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }
  }

  try encoder.encodeFrame(null); // flush
  try encoder.finish();
}
