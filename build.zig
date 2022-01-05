const std = @import("std");

pub fn build(b: *std.build.Builder) void {
  const target = b.standardTargetOptions(.{});
  const mode = b.standardReleaseOptions();

  const glad = b.addObject("glad", null);
  glad.setTarget(target);
  glad.setBuildMode(mode);
  glad.addIncludeDir("deps/include");
  glad.addCSourceFile("deps/glad/gl.c", &.{});
  glad.linkLibC();

  const exe = b.addExecutable("gl", "src/main.zig");
  exe.single_threaded = true;
  exe.setTarget(target);
  exe.setBuildMode(mode);
  exe.linkLibC();
  exe.addIncludeDir("deps/include");
  switch (exe.target.getOsTag()) {
    .windows => {
      exe.linkSystemLibrary("winmm");
      exe.linkSystemLibrary("gdi32");
      exe.linkSystemLibrary("opengl32");
      exe.addObjectFile("deps/lib/libglfw3.a");
      exe.addObject(glad);
    },
    else => @panic("Unsupported OS")
  }
  exe.install();

  const run_cmd = exe.run();
  run_cmd.step.dependOn(b.getInstallStep());
  if (b.args) |args| {
    run_cmd.addArgs(args);
  }

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  const exe_tests = b.addTest("src/main.zig");
  exe_tests.setBuildMode(mode);

  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&exe_tests.step);
}
