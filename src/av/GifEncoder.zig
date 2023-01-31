const c = @import("../c.zig");
const std = @import("std");
const av = @import("av.zig");
const util = @import("../util.zig");
const Self = @This();

gif_stream: *c.AVStream,
format_context: *c.AVFormatContext,
codec_context: *c.AVCodecContext,
packet: *c.AVPacket,

pub fn init(file: [*:0]const u8, width: c_int, height: c_int) !Self {
  const fmt = c.av_guess_format("gif", file, "video/gif");
  try av.checkNull(fmt);

  var fmt_ctx: [*c]c.AVFormatContext = undefined;
  try av.checkError(c.avformat_alloc_output_context2(&fmt_ctx, fmt, "gif", file));
  errdefer c.avformat_free_context(fmt_ctx);

  const codec = c.avcodec_find_encoder(c.AV_CODEC_ID_GIF);
  try av.checkNull(codec);

  const stream = c.avformat_new_stream(fmt_ctx, codec);
  try av.checkNull(stream);

  util.overwrite(stream.*.codecpar, .{
    .codec_tag = 0,
    .codec_id = codec.*.id,
    .codec_type = c.AVMEDIA_TYPE_VIDEO,
    .format = c.AV_PIX_FMT_PAL8,
    .width = width,
    .height = height,
  });

  var codec_ctx = c.avcodec_alloc_context3(codec);
  try av.checkNull(codec_ctx);
  errdefer c.avcodec_free_context(&codec_ctx);

  try av.checkError(c.avcodec_parameters_to_context(codec_ctx, stream.*.codecpar));
  codec_ctx.*.time_base = c.av_make_q(1, 24);

  try av.checkError(c.avcodec_open2(codec_ctx, codec, null));
  try av.checkError(c.avio_open(&fmt_ctx.*.pb, file, c.AVIO_FLAG_WRITE));
  errdefer _ = c.avio_closep(&fmt_ctx.*.pb);
  try av.checkError(c.avformat_write_header(fmt_ctx, null));

  var packet = c.av_packet_alloc();
  try av.checkNull(packet);
  errdefer c.av_packet_free(&packet);

  return Self{
    .gif_stream = stream,
    .format_context = fmt_ctx,
    .codec_context = codec_ctx,
    .packet = packet,
  };
}

pub fn deinit(self: *const Self) void {
  var packet: ?*c.AVPacket = self.packet;
  var codec_ctx: ?*c.AVCodecContext = self.codec_context;
  var format_ctx: ?*c.AVFormatContext = self.format_context;
  c.av_packet_free(&packet);
  c.avcodec_free_context(&codec_ctx);
  c.avformat_close_input(&format_ctx);
}

pub fn finish(self: *const Self) !void {
  try av.checkError(c.av_write_trailer(self.format_context));
  try av.checkError(c.avio_closep(&self.format_context.pb));
}

pub fn allocFrame(self: *const Self, palette: *const [0x100][4]u8) !*c.AVFrame {
  var frame = c.av_frame_alloc();
  try av.checkNull(frame);
  errdefer c.av_frame_free(&frame);

  frame.*.format = c.AV_PIX_FMT_PAL8;
  frame.*.width = self.codec_context.width;
  frame.*.height = self.codec_context.height;
  try av.checkError(c.av_frame_get_buffer(frame, 4));

  @memcpy(frame.*.data[1], @ptrCast([*]const u8, palette), 0x400);

  return frame;
}

pub fn encodeFrame(self: *const Self, frame: ?*c.AVFrame) !void {
  try av.checkError(c.avcodec_send_frame(self.codec_context, frame));
  while (try self.receivePacket()) |packet| {
    c.av_packet_rescale_ts(packet, self.codec_context.time_base, self.gif_stream.time_base);
    try av.checkError(c.av_write_frame(self.format_context, packet));
  }
}

fn receivePacket(self: *const Self) !?*c.AVPacket {
  switch (c.avcodec_receive_packet(self.codec_context, self.packet)) {
    c.AVERROR_EOF, c.AVERROR(c.EAGAIN) => return null,
    else => |code| {
      try av.checkError(code);
      return self.packet;
    }
  }
}
