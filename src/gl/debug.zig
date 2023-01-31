const c = @import("../c.zig");
const gl = @import("gl.zig");

pub fn enabled() bool {
  var flags: c_int = undefined;
  c.glGetIntegerv(c.GL_CONTEXT_FLAGS, &flags);
  return flags & c.GL_CONTEXT_FLAG_DEBUG_BIT != 0;
}

pub fn enableDebugMessages() void {
  if (enabled()) {
    c.glEnable(c.GL_DEBUG_OUTPUT);
    c.glEnable(c.GL_DEBUG_OUTPUT_SYNCHRONOUS);
    c.glDebugMessageCallback(debugMessageCallback, null);
    c.glDebugMessageControl(c.GL_DONT_CARE, c.GL_DONT_CARE, c.GL_DONT_CARE, 0, null, c.GL_TRUE);
  }

  gl.log.info("{s}", .{ c.glGetString(c.GL_VENDOR) });
  gl.log.info("{s}", .{ c.glGetString(c.GL_RENDERER) });
  gl.log.info("OpenGL {s}", .{ c.glGetString(c.GL_VERSION) });
  gl.log.info("GLSL {s}", .{ c.glGetString(c.GL_SHADING_LANGUAGE_VERSION) });
}

pub fn debugMessageCallback(
  source: c.GLenum,
  kind: c.GLenum,
  id: c.GLuint,
  severity: c.GLenum,
  _: c.GLsizei,
  message: [*c]const c.GLchar,
  _: ?*const c.GLvoid,
) callconv(.C) void {
  const fmt = "{s} {s} 0x{x}: {s}";
  const args = .{
    switch (source) {
      c.GL_DEBUG_SOURCE_API => @as([]const u8, "API"),
      c.GL_DEBUG_SOURCE_WINDOW_SYSTEM => "Window System",
      c.GL_DEBUG_SOURCE_SHADER_COMPILER => "Shader Compiler",
      c.GL_DEBUG_SOURCE_THIRD_PARTY => "Third Party",
      c.GL_DEBUG_SOURCE_APPLICATION => "Application",
      c.GL_DEBUG_SOURCE_OTHER => "Other",
      else => unreachable
    },
    switch (kind) {
      c.GL_DEBUG_TYPE_ERROR => @as([]const u8, "Error"),
      c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR => "Deprecated Behavior",
      c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR => "Undefined Behavior",
      c.GL_DEBUG_TYPE_PORTABILITY => "Portability",
      c.GL_DEBUG_TYPE_PERFORMANCE => "Performance",
      c.GL_DEBUG_TYPE_MARKER => "Marker",
      c.GL_DEBUG_TYPE_PUSH_GROUP => "Push Group",
      c.GL_DEBUG_TYPE_POP_GROUP => "Pop Group",
      c.GL_DEBUG_TYPE_OTHER => "Other",
      else => unreachable
    },
    id,
    message,
  };

  switch (severity) {
    c.GL_DEBUG_SEVERITY_HIGH => gl.log.err(fmt, args),
    c.GL_DEBUG_SEVERITY_MEDIUM => gl.log.warn(fmt, args),
    c.GL_DEBUG_SEVERITY_LOW => gl.log.info(fmt, args),
    c.GL_DEBUG_SEVERITY_NOTIFICATION => gl.log.debug(fmt, args),
    else => unreachable
  }
}

pub fn checkError() !void {
  return switch (c.glGetError()) {
    c.GL_NO_ERROR => {},
    c.GL_INVALID_ENUM => error.GL_InvalidEnum,
    c.GL_INVALID_FRAMEBUFFER_OPERATION => error.GL_InvalidFramebufferOperation,
    c.GL_INVALID_OPERATION => error.GL_InvalidOperation,
    c.GL_INVALID_VALUE => error.GL_InvalidValue,
    c.GL_OUT_OF_MEMORY => error.GL_OutOfMemory,
    c.GL_STACK_OVERFLOW => error.GL_StackOverflow,
    c.GL_STACK_UNDERFLOW => error.GL_StackUnderflow,
    else => unreachable
  };
}

pub fn typeToStr(t: c.GLint) []const u8 {
  // https://docs.gl/gl4/glGetActiveUniformsiv
  return switch (t) {
    c.GL_FLOAT => "float",
    c.GL_FLOAT_VEC2 => "vec2",
    c.GL_FLOAT_VEC3 => "vec3",
    c.GL_FLOAT_VEC4 => "vec4",
    c.GL_DOUBLE => "double",
    c.GL_DOUBLE_VEC2 => "dvec2",
    c.GL_DOUBLE_VEC3 => "dvec3",
    c.GL_DOUBLE_VEC4 => "dvec4",
    c.GL_INT => "int",
    c.GL_INT_VEC2 => "ivec2",
    c.GL_INT_VEC3 => "ivec3",
    c.GL_INT_VEC4 => "ivec4",
    c.GL_UNSIGNED_INT => "unsigned int",
    c.GL_UNSIGNED_INT_VEC2 => "uvec2",
    c.GL_UNSIGNED_INT_VEC3 => "uvec3",
    c.GL_UNSIGNED_INT_VEC4 => "uvec4",
    c.GL_BOOL => "bool",
    c.GL_BOOL_VEC2 => "bvec2",
    c.GL_BOOL_VEC3 => "bvec3",
    c.GL_BOOL_VEC4 => "bvec4",
    c.GL_FLOAT_MAT2 => "mat2",
    c.GL_FLOAT_MAT3 => "mat3",
    c.GL_FLOAT_MAT4 => "mat4",
    c.GL_FLOAT_MAT2x3 => "mat2x3",
    c.GL_FLOAT_MAT2x4 => "mat2x4",
    c.GL_FLOAT_MAT3x2 => "mat3x2",
    c.GL_FLOAT_MAT3x4 => "mat3x4",
    c.GL_FLOAT_MAT4x2 => "mat4x2",
    c.GL_FLOAT_MAT4x3 => "mat4x3",
    c.GL_DOUBLE_MAT2 => "dmat2",
    c.GL_DOUBLE_MAT3 => "dmat3",
    c.GL_DOUBLE_MAT4 => "dmat4",
    c.GL_DOUBLE_MAT2x3 => "dmat2x3",
    c.GL_DOUBLE_MAT2x4 => "dmat2x4",
    c.GL_DOUBLE_MAT3x2 => "dmat3x2",
    c.GL_DOUBLE_MAT3x4 => "dmat3x4",
    c.GL_DOUBLE_MAT4x2 => "dmat4x2",
    c.GL_DOUBLE_MAT4x3 => "dmat4x3",
    c.GL_SAMPLER_1D => "sampler1D",
    c.GL_SAMPLER_2D => "sampler2D",
    c.GL_SAMPLER_3D => "sampler3D",
    c.GL_SAMPLER_CUBE => "samplerCube",
    c.GL_SAMPLER_1D_SHADOW => "sampler1DShadow",
    c.GL_SAMPLER_2D_SHADOW => "sampler2DShadow",
    c.GL_SAMPLER_1D_ARRAY => "sampler1DArray",
    c.GL_SAMPLER_2D_ARRAY => "sampler2DArray",
    c.GL_SAMPLER_1D_ARRAY_SHADOW => "sampler1DArrayShadow",
    c.GL_SAMPLER_2D_ARRAY_SHADOW => "sampler2DArrayShadow",
    c.GL_SAMPLER_2D_MULTISAMPLE => "sampler2DMS",
    c.GL_SAMPLER_2D_MULTISAMPLE_ARRAY => "sampler2DMSArray",
    c.GL_SAMPLER_CUBE_SHADOW => "samplerCubeShadow",
    c.GL_SAMPLER_BUFFER => "samplerBuffer",
    c.GL_SAMPLER_2D_RECT => "sampler2DRect",
    c.GL_SAMPLER_2D_RECT_SHADOW => "sampler2DRectShadow",
    c.GL_INT_SAMPLER_1D => "isampler1D",
    c.GL_INT_SAMPLER_2D => "isampler2D",
    c.GL_INT_SAMPLER_3D => "isampler3D",
    c.GL_INT_SAMPLER_CUBE => "isamplerCube",
    c.GL_INT_SAMPLER_1D_ARRAY => "isampler1DArray",
    c.GL_INT_SAMPLER_2D_ARRAY => "isampler2DArray",
    c.GL_INT_SAMPLER_2D_MULTISAMPLE => "isampler2DMS",
    c.GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY => "isampler2DMSArray",
    c.GL_INT_SAMPLER_BUFFER => "isamplerBuffer",
    c.GL_INT_SAMPLER_2D_RECT => "isampler2DRect",
    c.GL_UNSIGNED_INT_SAMPLER_1D => "usampler1D",
    c.GL_UNSIGNED_INT_SAMPLER_2D => "usampler2D",
    c.GL_UNSIGNED_INT_SAMPLER_3D => "usampler3D",
    c.GL_UNSIGNED_INT_SAMPLER_CUBE => "usamplerCube",
    c.GL_UNSIGNED_INT_SAMPLER_1D_ARRAY => "usampler2DArray",
    c.GL_UNSIGNED_INT_SAMPLER_2D_ARRAY => "usampler2DArray",
    c.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE => "usampler2DMS",
    c.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY => "usampler2DMSArray",
    c.GL_UNSIGNED_INT_SAMPLER_BUFFER => "usamplerBuffer",
    c.GL_UNSIGNED_INT_SAMPLER_2D_RECT => "usampler2DRect",
    else => unreachable
  };
}
