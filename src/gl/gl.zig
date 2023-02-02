const c = @import("../c.zig");
const std = @import("std");

pub const log = std.log.scoped(.gl);
pub const debug = @import("debug.zig");
pub const textures = @import("textures.zig");
pub const Framebuffer = @import("Framebuffer.zig");
pub const Shader = @import("Shader.zig");
pub usingnamespace @import("program/Program.zig");

pub const String = std.ArrayList(c.GLchar);

pub const MAJOR = 4;
pub const MINOR = 6;
pub const VERSION = std.fmt.comptimePrint("#version {}{}0 core", .{ MAJOR, MINOR });
