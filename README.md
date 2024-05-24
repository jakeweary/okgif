# Okgif

A video-to-GIF transcoder. Using ffmpeg for video decoding and gif encoding, and OpenGL for frame processing.

_Work in progress..._

## The Problem

So, why yet another gif encoder, don't we have enough of them already? Well, there are many on the market, but none of them are good enough for my liking.

 1. The use of a perceptually uniform color space is crucial, but rarely implemented. This often results in poor color choices both while generating the palette and while matching colors against it.

 2. Additionally, common dithering methods also have their shortcomings:

    - [Error diffusion][1]: This is the typical choice when aiming for quality. However, it tends to be too volatile for gif purposes. A single pixel change can trigger a complete dithering recalculation, resulting in distracting motion artifacts and ridiculous file sizes.

    - [Ordered dithering][2]: While it offers reasonable visual quality and file sizes, most implementations are stuck with the ordinary Bayer threshold matrix instead of the lovely blue noise. This results in gifs having that retrowave 8-bit kind of aesthetic, which is rarely desirable.

[1]: https://en.wikipedia.org/wiki/Error_diffusion
[2]: https://en.wikipedia.org/wiki/Ordered_dithering

## The Solution

So, the idea is to use a good perceptually uniform color space ([Oklab][3] my beloved) for high-quality palette generation and color matching, and [blue noise][4] for dithering. In theory, this approach should result in gifs that would look pleasant to the human eye, while offering a nice balance between quality and file sizes.

[3]: https://bottosson.github.io/posts/oklab/
[4]: https://momentsingraphics.de/BlueNoise.html

## Instructions

### Preparations

```sh
# acquire precompiled ffmpeg
curl -fLO https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip
unzip -d deps ffmpeg-*.zip && rm ffmpeg-*.zip
mv deps/ffmpeg-* deps/ffmpeg

# and blue noise textures
git clone https://github.com/Calinou/free-blue-noise-textures deps/assets/blue-noise
```

### Building and running

```sh
# debug mode build and run
zig build run -- input.mp4

# explicit release build
zig build -Doptimize=ReleaseFast -Dtarget=x86_64-windows-gnu -Dcpu=baseline
```

### Managing dependencies

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

## Useful resources

### OpenGL
- https://learnopengl.com/Getting-started/Hello-Window
- https://learnopengl.com/In-Practice/Debugging
- https://github.com/Dav1dde/glad/blob/glad2/example/c/gl_glfw.c
- https://github.com/glfw/glfw/blob/master/examples/triangle-opengl.c

### libav/ffmpeg
- https://github.com/leandromoreira/ffmpeg-libav-tutorial
- https://trac.ffmpeg.org/wiki/Using%20libav%2A
- https://ffmpeg.org/doxygen/trunk/api-h264-test_8c_source.html
- https://ffmpeg.org/doxygen/trunk/transcoding_8c-example.html
- https://ffmpeg.org/doxygen/trunk/libavformat_2gif_8c_source.html
