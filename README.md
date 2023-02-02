# Okgif - GIF encoder project (WIP)

```sh
# acquire precompiled ffmpeg
curl -fLO https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip
unzip -d deps ffmpeg-*.zip && rm ffmpeg-*.zip
mv deps/ffmpeg-* deps/ffmpeg

# and blue noise textures
git clone https://github.com/Calinou/free-blue-noise-textures deps/assets/blue-noise

# debug mode build and run
zig build run -- input.mp4

# explicit release build
zig build -Doptimize=ReleaseFast -Dtarget=x86_64-windows-gnu -Dcpu=baseline
```

```sh
# upgrade Glad
url=$(curl -Lo /dev/null -w %{url_effective} https://gen.glad.sh/generate \
  -d 'generator=c&api=gl%3D4.6&profile=gl%3Dcore&options=HEADER_ONLY')
curl -o deps/include/glad/gl.h ${url}include/glad/gl.h

# upgrade GLFW
url=$(curl -Lo /dev/null -w %{url_effective} https://github.com/glfw/glfw/releases/latest)
curl -LO ${url/tag/download}/glfw-${url##*/}.bin.WIN64.zip
unzip -q glfw-*.zip
cp -r glfw-*/include/GLFW/ deps/include/
cp glfw-*/lib-mingw-w64/libglfw3.a deps/lib/glfw.lib
rm -rf glfw-*
```

## Resources

### OpenGL
- https://learnopengl.com/Getting-started/Hello-Window
- https://learnopengl.com/In-Practice/Debugging
- https://github.com/Dav1dde/glad/blob/glad2/example/c/gl_glfw.c
- https://github.com/glfw/glfw/blob/master/examples/triangle-opengl.c

### libav/ffmpeg
- https://github.com/leandromoreira/ffmpeg-libav-tutorial
- https://trac.ffmpeg.org/wiki/Using%20libav*
- https://ffmpeg.org/doxygen/trunk/api-h264-test_8c_source.html
- https://ffmpeg.org/doxygen/trunk/transcoding_8c-example.html
- https://ffmpeg.org/doxygen/trunk/libavformat_2gif_8c_source.html
