const std = @import("std");

pub fn build(b: *std.Build) void {
  const optimize = b.standardOptimizeOption(.{});
  const target = b.standardTargetOptions(.{
    .default_target = .{ .os_tag = .windows },
  });

  const exe = b.addExecutable(.{
    .name = "okgif",
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = optimize,
  });
  inline for (.{ "avcodec-59", "avformat-59", "avutil-57", "swresample-4", "swscale-6" }) |lib| {
    const dst = "bin/" ++ lib ++ ".dll";
    const src = std.build.FileSource.relative("deps/ffmpeg/" ++ dst);
    exe.step.dependOn(&b.addInstallFile(src, dst).step);
  }
  exe.want_lto = false; // https://github.com/ziglang/zig/issues/8531
  exe.single_threaded = true;
  exe.setMainPkgPath("");
  exe.addLibraryPath("deps/lib");
  exe.addLibraryPath("deps/ffmpeg/lib");
  exe.addIncludePath("deps/include");
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
    else => @panic("unsupported os"),
  }
  exe.linkLibC();
  exe.install();

  const run_cmd = exe.run();
  run_cmd.step.dependOn(b.getInstallStep());
  run_cmd.addArgs(b.args orelse &.{});

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);

  const exe_tests = b.addTest(.{
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = optimize,
  });

  const test_step = b.step("test", "Run unit tests");
  test_step.dependOn(&exe_tests.step);
}
