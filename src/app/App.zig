const std = @import("std");
const c = @import("../c.zig");
const av = @import("../av/av.zig");
const gl = @import("../gl/gl.zig");
const glfw = @import("../glfw/glfw.zig");
const scaling = @import("../scaling.zig");
const palettes = @import("../palettes.zig");
const Programs = @import("Programs.zig");
const Textures = @import("Textures.zig");
const Self = @This();

const K = 256;

pub const log = std.log.scoped(.App);

scaled_width: c_int,
scaled_height: c_int,

window: glfw.Window,

decoder: av.VideoDecoder,
encoder: av.GifEncoder,
resizer: av.FrameResizer,

textures: Textures,
programs: Programs,

fbo: c.GLuint,
vao: c.GLuint,

pub fn init() !Self {
  log.debug("App.init", .{});

  av.setLogLevel(std.options.log_level);

  if (std.os.argv.len < 2) {
    std.debug.print("Usage: {s} <file>\n", .{ std.os.argv[0] });
    std.os.exit(1);
  }

  // ---

  var self: Self = undefined;

  const filepath = std.mem.sliceTo(std.os.argv[1], 0);
  // const filename = std.fs.path.basename(filepath);

  // ---

  self.decoder = try av.VideoDecoder.init(filepath.ptr);
  errdefer self.decoder.deinit();

  const cc = self.decoder.codec_context;
  const scaled = scaling.contain(.{ cc.width, cc.height }, .{ 400 * 5/2, 300 * 5/2 });
  self.scaled_width = scaled[0];
  self.scaled_height = scaled[1];

  self.encoder = try av.GifEncoder.init("out.gif", self.scaled_width, self.scaled_height);
  errdefer self.encoder.deinit();

  self.resizer = try av.FrameResizer.init(cc, self.scaled_width, self.scaled_height);
  errdefer self.resizer.deinit();

  // ---

  log.info("Glad v{s}", .{ c.GLAD_GENERATOR_VERSION });
  log.info("GLFW v{s}", .{ c.glfwGetVersionString() });
  log.info("libav {s}", .{ c.av_version_info() });

  try glfw.init(&.{});
  errdefer glfw.deinit();

  self.window = try glfw.Window.init(self.scaled_width, self.scaled_height, "", &.{
    .{ c.GLFW_CONTEXT_VERSION_MAJOR, gl.MAJOR },
    .{ c.GLFW_CONTEXT_VERSION_MINOR, gl.MINOR },
    .{ c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE },
    .{ c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE },
    .{ c.GLFW_RESIZABLE, c.GLFW_FALSE },
  });
  errdefer self.window.deinit();

  c.glfwSwapInterval(1);

  // ---

  self.textures = try Textures.init(K, self.scaled_width, self.scaled_height);
  errdefer self.textures.deinit();

  self.programs = try Programs.init();
  errdefer self.programs.deinit();

  c.glCreateFramebuffers(1, &self.fbo);
  errdefer c.glDeleteFramebuffers(1, &self.fbo);

  c.glCreateVertexArrays(1, &self.vao);
  errdefer c.glDeleteVertexArrays(1, &self.vao);

  c.glBindVertexArray(self.vao);
  c.glDisable(c.GL_DITHER);

  // ---

  const callbacks = struct {
    fn onKey(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
      glfw.windowUserPointerUpcast(Self, window).onKey(key, scancode, action, mods);
    }

    fn onMouseButton(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
      glfw.windowUserPointerUpcast(Self, window).onMouseButton(button, action, mods);
    }

    fn onCursorPos(window: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
      glfw.windowUserPointerUpcast(Self, window).onCursorPos(x, y);
    }
  };

  _ = c.glfwSetKeyCallback(self.window.ptr, callbacks.onKey);
  _ = c.glfwSetMouseButtonCallback(self.window.ptr, callbacks.onMouseButton);
  _ = c.glfwSetCursorPosCallback(self.window.ptr, callbacks.onCursorPos);

  // ---

  return self;
}

pub fn deinit(self: *const Self) void {
  log.debug("App.deinit", .{});

  c.glDeleteVertexArrays(1, &self.vao);
  c.glDeleteFramebuffers(1, &self.fbo);

  self.programs.deinit();
  self.textures.deinit();

  self.window.deinit();
  glfw.deinit();

  self.resizer.deinit();
  self.encoder.deinit();
  self.decoder.deinit();
}

pub fn onKey(self: *Self, key: c_int, scancode: c_int, action: c_int, mods: c_int) void {
  log.debug("key: {x}, scancode: {x}, action: {x}, mods: {x}", .{ key, scancode, action, mods });

  if (action == c.GLFW_PRESS) {
    switch (key) {
      c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(self.window.ptr, c.GLFW_TRUE),
      // c.GLFW_KEY_LEFT => self.seek(-100),
      // c.GLFW_KEY_RIGHT => self.seek(100),
      else => {},
    }
  }
}

pub fn onMouseButton(_: *Self, button: c_int, action: c_int, mods: c_int) void {
  log.debug("button: {x}, action: {x}, mods: {x}", .{ button, action, mods });
}

pub fn onCursorPos(_: *Self, x: f64, y: f64) void {
  log.debug("x: {d}, y: {d}", .{ x, y });
}

pub fn run(self: *Self) !void {
  c.glfwSetWindowUserPointer(self.window.ptr, self);

  // var prng = std.rand.DefaultPrng.init(0);
  // var rand = prng.random();

  var means = std.mem.zeroes([K][4]c.GLfloat);

  // ---

  var palette = palettes.rgb685;

  {
    const fbo = gl.Framebuffer.attach(self.fbo, &.{
      .{ self.textures.means[1], 0 },
    });
    defer fbo.detach();

    var tid: c.GLuint = undefined;
    c.glCreateTextures(c.GL_TEXTURE_2D, 1, &tid);
    c.glTextureStorage2D(tid, 1, c.GL_SRGB8, K, 1);
    c.glTextureParameteri(tid, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTextureParameteri(tid, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    errdefer c.glDeleteTextures(1, &tid);

    c.glTextureSubImage2D(tid, 0, 0, 0, K, 1,
      c.GL_BGRA, c.GL_UNSIGNED_BYTE, &palette);

    const p = self.programs.convert_ucs.use();
    p.textures(.{ .tFrame = tid });

    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

    c.glReadBuffer(c.GL_COLOR_ATTACHMENT0);
    c.glReadPixels(0, 0, K, 1, c.GL_RGBA, c.GL_FLOAT, &means);
  }

  // ---

  var frame_pts: c_int = 0;
  while (try self.decoder.nextFrame()) |frame| : (frame_pts += 1) {
    if (c.glfwWindowShouldClose(self.window.ptr) == c.GLFW_TRUE)
      return;

    log.debug("--- frame {} ---", .{ frame_pts });

    log.info("{} {} {}", .{ frame_pts, frame.pts, frame.pkt_dts });

    {
      log.debug("step 1: resize and convert to sRGB (on CPU)", .{});

      const resized = try self.resizer.resize(frame);
      const stride = @divExact(resized.linesize[0], 3);

      c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, stride);
      defer c.glPixelStorei(c.GL_UNPACK_ROW_LENGTH, 0);

      c.glTextureSubImage2D(self.textures.rgb, 0,
        0, 0, resized.width, resized.height,
        c.GL_RGB, c.GL_UNSIGNED_BYTE, resized.data[0]);
    }

    {
      log.debug("step 2: convert to UCS", .{});

      const fbo = gl.Framebuffer.attach(self.fbo, &.{
        .{ self.textures.ucs, 0 },
      });
      defer fbo.detach();

      const p = self.programs.convert_ucs.use();
      p.textures(.{ .tFrame = self.textures.rgb });

      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    {
      log.debug("step 3: update means", .{});

      const fbo = gl.Framebuffer.attach(self.fbo, &.{
        .{ self.textures.means[0], 0 },
      });
      defer fbo.detach();

      c.glBlendFunc(c.GL_ONE, c.GL_ONE);
      c.glEnable(c.GL_BLEND);
      defer c.glDisable(c.GL_BLEND);

      const p = self.programs.means_update.use();
      p.uniforms(.{ .uMeans = &means });
      p.textures(.{ .tFrame = self.textures.ucs });

      c.glClear(c.GL_COLOR_BUFFER_BIT);
      c.glDrawArrays(c.GL_POINTS, 0, self.scaled_width * self.scaled_height);
    }

    {
      log.debug("step 4: reseed and read means", .{});

      const fbo = gl.Framebuffer.attach(self.fbo, &.{
        .{ self.textures.means[1], 0 },
      });
      defer fbo.detach();

      const p = self.programs.means_reseed.use();
      p.uniforms(.{ .uTime = c.glfwGetTime() });
      p.textures(.{ .tFrame = self.textures.ucs, .tMeans = self.textures.means[0] });

      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
      c.glReadPixels(0, 0, K, 1, c.GL_RGBA, c.GL_FLOAT, &means);

      // const T = std.meta.Child(@TypeOf(means));
      // const sortFn = struct {
      //   fn asc(_: void, a: T, b: T) bool { return a[0] < b[0]; }
      // };
      // std.sort.sort(T, &means, {}, sortFn.asc);
    }

    {
      log.debug("step 5: quantize", .{});

      const fbo = gl.Framebuffer.attach(self.fbo, &.{
        .{ self.textures.gif, 0 },
      });
      defer fbo.detach();

      const p = self.programs.quantize.use();
      p.uniforms(.{ .uFrame = frame_pts, .uMeans = &means });
      p.textures(.{ .tFrame = self.textures.ucs, .tNoise = self.textures.noise });

      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

      // ---

      // rand.shuffle([4]u8, &palette);

      // var gif_frame = try self.encoder.allocFrame(frame_pts, &palette);
      // var gif_frame_opt: ?*c.AVFrame = gif_frame;
      // defer c.av_frame_free(&gif_frame_opt);

      // c.glReadBuffer(c.GL_COLOR_ATTACHMENT0);
      // c.glReadPixels(0, 0, gif_frame.width, gif_frame.height,
      //   c.GL_RED_INTEGER, c.GL_UNSIGNED_BYTE, gif_frame.data[0]);

      // try self.encoder.encodeFrame(gif_frame);
    }

    {
      log.debug("step 6: render gif preview", .{});

      c.glEnable(c.GL_FRAMEBUFFER_SRGB);
      defer c.glDisable(c.GL_FRAMEBUFFER_SRGB);

      const p = self.programs.preview.use();
      p.textures(.{ .tFrame = self.textures.gif, .tMeans = self.textures.means[1] });

      c.glViewport(0, 0, self.scaled_width, self.scaled_height);
      c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    c.glfwSwapBuffers(self.window.ptr);
    c.glfwPollEvents();
  }

  try self.encoder.encodeFrame(null); // flush
  try self.encoder.finish();
}
