const std = @import("std");

pub fn build(b: *std.build.Builder) void {
  const mode = b.standardReleaseOptions();
  const target = b.standardTargetOptions(.{
    .default_target = .{ .os_tag = .windows }
  });

  const exe = b.addExecutable("gl", "src/main.zig");
  exe.single_threaded = true;
  exe.setTarget(target);
  exe.setBuildMode(mode);
  exe.addLibPath("deps/lib");
  exe.addLibPath("deps/ffmpeg/lib");
  exe.addIncludeDir("deps/include");
  exe.addIncludeDir("deps/ffmpeg/include");
  exe.addCSourceFile("deps/impl.c", &.{"-std=c99"});
  exe.linkSystemLibrary("glfw3");
  exe.linkSystemLibrary("avcodec");
  exe.linkSystemLibrary("avformat");
  exe.linkSystemLibrary("avutil");
  exe.linkSystemLibrary("swscale");
  switch (exe.target.getOsTag()) {
    .windows => {
      exe.linkSystemLibrary("winmm");
      exe.linkSystemLibrary("gdi32");
      exe.linkSystemLibrary("opengl32");
    },
    else => @panic("Unsupported OS")
  }
  exe.linkLibC();
  exe.install();

  const run_cmd = exe.run();
  run_cmd.step.dependOn(b.getInstallStep());
  run_cmd.addArgs(b.args orelse &.{});

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  const exe_tests = b.addTest("src/tests.zig");
  exe_tests.setBuildMode(mode);

  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&exe_tests.step);
}
