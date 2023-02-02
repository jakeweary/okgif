const c = @import("../c.zig");
const gl = @import("../gl/gl.zig");
const App = @import("App.zig");
const Self = @This();

convert_rgb: gl.Program,
convert_ucs: gl.Program,
means_update: gl.Program,
means_reseed: gl.Program,
quantize: gl.Program,
preview: gl.Program,

pub fn init() !Self {
  App.log.debug("Programs.init", .{});

  const srgb = @embedFile("../../deps/glsl/colorspaces/srgb.glsl");
  const oklab = @embedFile("../../deps/glsl/colorspaces/oklab.glsl");
  const hashes = @embedFile("../../deps/glsl/hashes.glsl");

  const quad = @embedFile("glsl/quad/vertex.glsl");
  const quad_flip_y = @embedFile("glsl/quad/vertex_flip_y.glsl");

  const kmeans = @embedFile("glsl/lib/kmeans.glsl");
  const ucs = @embedFile("glsl/lib/ucs.glsl");

  var self: Self = undefined;

  self.convert_rgb = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/convert_YCbCr_sRGB/fragment.glsl");
    break :blk try gl.Program.init(&.{ vs }, &.{ srgb, fs });
  };
  errdefer self.convert_rgb.deinit();

  self.convert_ucs = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/convert_sRGB_UCS/fragment.glsl");
    break :blk try gl.Program.init(&.{ vs }, &.{ srgb, oklab, ucs, fs });
  };
  errdefer self.convert_ucs.deinit();

  self.means_update = blk: {
    const vs = @embedFile("glsl/pass/means_update/vertex.glsl");
    const fs = @embedFile("glsl/pass/means_update/fragment.glsl");
    break :blk try gl.Program.init(&.{ kmeans, vs }, &.{ fs });
  };
  errdefer self.means_update.deinit();

  self.means_reseed = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/means_reseed/fragment.glsl");
    break :blk try gl.Program.init(&.{ vs }, &.{ hashes, fs });
  };
  errdefer self.means_reseed.deinit();

  self.quantize = blk: {
    const vs = quad;
    const fs = @embedFile("glsl/pass/quantize/fragment.glsl");
    break :blk try gl.Program.init(&.{ vs }, &.{ kmeans, fs });
  };
  errdefer self.quantize.deinit();

  self.preview = blk: {
    const vs = quad_flip_y;
    const fs = @embedFile("glsl/pass/preview/fragment.glsl");
    break :blk try gl.Program.init(&.{ vs }, &.{ srgb, oklab, ucs, fs });
  };
  errdefer self.preview.deinit();

  return self;
}

pub fn deinit(self: *const Self) void {
  App.log.debug("Programs.deinit", .{});

  self.convert_rgb.deinit();
  self.convert_ucs.deinit();
  self.means_update.deinit();
  self.means_reseed.deinit();
  self.quantize.deinit();
  self.preview.deinit();
}
