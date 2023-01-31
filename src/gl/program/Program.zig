const c = @import("../../c.zig");
const gl = @import("../gl.zig");
const root = @import("root");
const std = @import("std");
const Inner = @import("Inner.zig");

pub const Program = ProgramWithDefs(struct {});

pub fn ProgramWithDefs(comptime Defs: type) type {
  return struct {
    const Self = @This();

    inner: Inner,
    defs: Defs = .{},
    prev: Defs = .{},
    vert: [:0]const c.GLchar,
    frag: [:0]const c.GLchar,

    pub fn init(verts: []const []const c.GLchar, frags: []const []const c.GLchar) !Self {
      const vert = try std.mem.joinZ(root.allocator, "\n", verts);
      errdefer root.allocator.free(vert);

      const frag = try std.mem.joinZ(root.allocator, "\n", frags);
      errdefer root.allocator.free(frag);

      const inner = try initInner(vert, frag, .{});
      return .{ .inner = inner, .vert = vert, .frag = frag };
    }

    pub fn deinit(self: *const Self) void {
      root.allocator.free(self.frag);
      root.allocator.free(self.vert);
      self.inner.deinit();
    }

    pub fn reinit(self: *Self) !bool {
      const changed = !std.meta.eql(self.defs, self.prev);
      if (changed) {
        gl.log.debug("defs changed, reinitializing program: {}", .{ self.inner.id });
        self.inner.deinit();
        self.inner = try initInner(self.vert, self.frag, self.defs);
        self.prev = self.defs;
      }
      return changed;
    }

    pub fn use(self: *const Self) Inner {
      self.inner.use();
      return self.inner;
    }

    fn initInner(vert: [:0]const c.GLchar, frag: [:0]const c.GLchar, defs: Defs) !Inner {
      var str = gl.String.init(root.allocator);
      defer str.deinit();

      const header = try writeHeader(&str, defs);
      return Inner.init(&.{ header, vert }, &.{ header, frag });
    }

    fn writeHeader(str: *gl.String, defs: Defs) ![:0]c.GLchar {
      try str.appendSlice(gl.VERSION ++ "\n");

      const str_w = str.writer();
      inline for (@typeInfo(Defs).Struct.fields) |f| {
        const k = f.name;
        const v = @field(defs, f.name);
        const kv = switch (f.type) {
          bool => .{ k, @boolToInt(v) },
          else => .{ k, v },
        };
        const fmt = "#define {s} {}";
        try str_w.print(fmt ++ "\n", kv);
        gl.log.debug(fmt, kv);
      }

      try str.appendSlice("\n\x00");

      return str.items[0 .. str.items.len - 1 :0];
    }
  };
}
