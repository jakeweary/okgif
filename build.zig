const std = @import("std");

pub fn build(b: *std.build.Builder) void {
  const target = b.standardTargetOptions(.{});
  const mode = b.standardReleaseOptions();

  const exe = b.addExecutable("gl", "src/main.zig");
  exe.single_threaded = true;
  exe.setTarget(target);
  exe.setBuildMode(mode);
  exe.linkLibC();
  exe.addIncludeDir("deps/include");
  exe.addIncludeDir("deps/ffmpeg/include");
  exe.addCSourceFile("deps/glad.c", &.{ "-std=c99" });
  exe.addCSourceFile("deps/stb_image.c", &.{ "-std=c99" });
  switch (exe.target.getOsTag()) {
    .windows => {
      exe.linkSystemLibrary("winmm");
      exe.linkSystemLibrary("gdi32");
      exe.linkSystemLibrary("opengl32");
      exe.addObjectFile("deps/lib/libglfw3.a");
      exe.addObjectFile("deps/ffmpeg/lib/avcodec.lib");
      exe.addObjectFile("deps/ffmpeg/lib/avformat.lib");
      exe.addObjectFile("deps/ffmpeg/lib/avutil.lib");
      exe.addObjectFile("deps/ffmpeg/lib/swscale.lib");
    },
    else => @panic("Unsupported OS")
  }
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
