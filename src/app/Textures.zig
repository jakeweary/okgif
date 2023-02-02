const c = @import("../c.zig");
const std = @import("std");
const stb = @import("../stb/stb.zig");
const App = @import("App.zig");
const Self = @This();

means: [2]c.GLuint,
rgb: c.GLuint,
ucs: c.GLuint,
gif: c.GLuint,
noise: c.GLuint,

pub fn init(k: c.GLsizei, w: c.GLsizei, h: c.GLsizei) !Self {
  App.log.debug("Textures.init", .{});

  var self: Self = undefined;

  c.glCreateTextures(c.GL_TEXTURE_2D, self.means.len, &self.means);
  for (self.means) |id|
    c.glTextureStorage2D(id, 1, c.GL_RGBA32F, k, 1);
  errdefer c.glDeleteTextures(self.means.len, &self.means);

  c.glCreateTextures(c.GL_TEXTURE_2D, 1, &self.rgb);
  c.glTextureStorage2D(self.rgb, 1, c.GL_SRGB8, w, h);
  errdefer c.glDeleteTextures(1, &self.rgb);

  c.glCreateTextures(c.GL_TEXTURE_2D, 1, &self.ucs);
  c.glTextureStorage2D(self.ucs, 1, c.GL_RGB32F, w, h);
  errdefer c.glDeleteTextures(1, &self.ucs);

  c.glCreateTextures(c.GL_TEXTURE_2D, 1, &self.gif);
  c.glTextureStorage2D(self.gif, 1, c.GL_R8UI, w, h);
  errdefer c.glDeleteTextures(1, &self.gif);

  c.glCreateTextures(c.GL_TEXTURE_3D, 1, &self.noise);
  c.glTextureStorage3D(self.noise, 1, c.GL_RGBA8, 128, 128, 16);
  errdefer c.glDeleteTextures(1, &self.noise);

  for (blueNoise3D(.{ .x = 128, .y = 128, .z = 16 })) |png, i| {
    const img = try stb.Image.fromMemory(png);
    defer img.deinit();

    const z = @intCast(c.GLint, i);
    c.glTextureSubImage3D(self.noise, 0, 0, 0, z, 128, 128, 1,
      c.GL_RGBA, c.GL_UNSIGNED_BYTE, img.data.ptr);
  }

  for (self.means ++ .{ self.rgb, self.ucs, self.gif, self.noise }) |id| {
    c.glTextureParameteri(id, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTextureParameteri(id, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
  }

  return self;
}

pub fn deinit(self: *const Self) void {
  App.log.debug("Textures.deinit", .{});

  c.glDeleteTextures(self.means.len, &self.means);
  c.glDeleteTextures(1, &self.rgb);
  c.glDeleteTextures(1, &self.ucs);
  c.glDeleteTextures(1, &self.gif);
  c.glDeleteTextures(1, &self.noise);
}

fn blueNoise3D(comptime shape: struct { x: usize, y: usize, z: usize }) [shape.z][]const u8 {
  var pngs: [shape.z][]const u8 = undefined;
  inline for (pngs) |*png, i| {
    const path_fmt = "../../deps/assets/blue-noise/{}_{}/LDR_RGB1_{}.png";
    const path = comptime std.fmt.comptimePrint(path_fmt, .{ shape.x, shape.y, i });
    png.* = @embedFile(path);
  }
  return pngs;
}
