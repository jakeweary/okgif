# Video to GIF transcoder project (WIP)

```sh
# acquire precompiled ffmpeg
curl -fLO https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip
unzip -d deps ffmpeg-*.zip && rm ffmpeg-*.zip
mv deps/ffmpeg-* deps/ffmpeg

# don't forget to put the .dll files next to the .exe
mkdir -p zig-out/bin
cp deps/ffmpeg/bin/*.dll zig-out/bin

# build and run
zig build run -Dtarget=x86_64-windows-gnu -- input.mp4
```

## References:
- https://learnopengl.com/Getting-started/Hello-Window
- https://learnopengl.com/In-Practice/Debugging
- https://github.com/Dav1dde/glad/blob/glad2/example/c/gl_glfw.c
- https://github.com/glfw/glfw/blob/master/examples/triangle-opengl.c
- https://github.com/leandromoreira/ffmpeg-libav-tutorial
- https://ffmpeg.org/doxygen/4.1/api-h264-test_8c_source.html
- https://ffmpeg.org/doxygen/4.1/transcoding_8c-example.html
- https://ffmpeg.org/doxygen/4.1/libavformat_2gif_8c_source.html
