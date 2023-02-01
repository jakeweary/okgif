const std = @import("std");

pub fn build(b: *std.build.Builder) void {
  const mode = b.standardReleaseOptions();
  const target = b.standardTargetOptions(.{
    .default_target = .{ .os_tag = .windows }
  });

  const exe = b.addExecutable("okgif", "src/main.zig");
  exe.want_lto = false; // https://github.com/ziglang/zig/issues/8531
  exe.single_threaded = true;
  exe.setTarget(target);
  exe.setBuildMode(mode);
  exe.setMainPkgPath("");
  exe.addLibraryPath("deps/lib");
  exe.addIncludePath("deps/include");
  exe.addLibraryPath("deps/ffmpeg/lib");
  exe.addIncludePath("deps/ffmpeg/include");
  exe.addCSourceFile("deps/deps.c", &.{});
  exe.linkSystemLibraryName("glfw");
  exe.linkSystemLibraryName("avcodec");
  exe.linkSystemLibraryName("avformat");
  exe.linkSystemLibraryName("avutil");
  exe.linkSystemLibraryName("swscale");
  switch (exe.target.getOsTag()) {
    .windows => {
      exe.linkSystemLibraryName("winmm");
      exe.linkSystemLibraryName("gdi32");
      exe.linkSystemLibraryName("opengl32");
    },
    // .linux => {
    //   exe.linkSystemLibraryName("X11");
    //   exe.linkSystemLibraryName("GL");
    // },
    else => @panic("unsupported os"),
  }
  exe.linkLibC();
  exe.install();

  const run_cmd = exe.run();
  run_cmd.step.dependOn(b.getInstallStep());
  run_cmd.addArgs(b.args orelse &[_][]const u8{});

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  const exe_tests = b.addTest("src/tests.zig");
  exe_tests.setBuildMode(mode);

  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&exe_tests.step);
}
