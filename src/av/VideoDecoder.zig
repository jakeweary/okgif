const c = @import("../c.zig");
const std = @import("std");
const av = @import("av.zig");
const util = @import("../util.zig");
const Self = @This();

state: enum { reading, decoding, finished } = .reading,

video_stream: *c.AVStream,
format_context: *c.AVFormatContext,
codec_context: *c.AVCodecContext,
packet: *c.AVPacket,
frame: *c.AVFrame,

pub fn init(file: [*:0]const u8) !Self {
  var fmt_ctx: [*c]c.AVFormatContext = null;
  try av.checkError(c.avformat_open_input(&fmt_ctx, file, null, null));
  errdefer c.avformat_close_input(&fmt_ctx);

  try av.checkError(c.avformat_find_stream_info(fmt_ctx, null));
  const stream_index = c.av_find_best_stream(fmt_ctx, c.AVMEDIA_TYPE_VIDEO, -1, -1, null, 0);
  try av.checkError(stream_index);

  const stream = fmt_ctx.*.streams[@intCast(usize, stream_index)];
  const params = stream.*.codecpar;
  av.log.info("Found the stream: {s} {}x{}", .{
    c.av_get_pix_fmt_name(params.*.format), params.*.width, params.*.height
  });

  const codec = c.avcodec_find_decoder(params.*.codec_id);
  try av.checkNull(codec);
  av.log.info("Found the decoder: {s}", .{ codec.*.name });

  var codec_ctx = c.avcodec_alloc_context3(codec);
  try av.checkNull(codec_ctx);
  errdefer c.avcodec_free_context(&codec_ctx);

  try av.checkError(c.avcodec_parameters_to_context(codec_ctx, params));
  try av.checkError(c.avcodec_open2(codec_ctx, codec, null));

  var packet = c.av_packet_alloc();
  try av.checkNull(packet);
  errdefer c.av_packet_free(&packet);

  var frame = c.av_frame_alloc();
  try av.checkNull(frame);
  errdefer c.av_frame_free(&frame);

  return Self{
    .video_stream = stream,
    .format_context = fmt_ctx,
    .codec_context = codec_ctx,
    .packet = packet,
    .frame = frame,
  };
}

pub fn deinit(self: *const Self) void {
  var frame = util.optional(self.frame);
  var packet = util.optional(self.packet);
  var codec_context = util.optional(self.codec_context);
  var format_context = util.optional(self.format_context);
  c.av_frame_free(&frame);
  c.av_packet_free(&packet);
  c.avcodec_free_context(&codec_context);
  c.avformat_close_input(&format_context);
}

pub fn nextFrame(self: *Self) !?*c.AVFrame {
  while (true) {
    switch (self.state) {
      .reading => {
        c.av_packet_unref(self.packet);
        if (!try self.readPacket()) {
          self.state = .finished;
        }
        else if (self.packet.stream_index == self.video_stream.index) {
          try self.sendPacket();
          self.state = .decoding;
        }
      },
      .decoding => {
        if (try self.receiveFrame()) |frame| {
          return frame;
        }
        self.state = .reading;
      },
      .finished => {
        return null;
      }
    }
  }
}

fn receiveFrame(self: *const Self) !?*c.AVFrame {
  switch (c.avcodec_receive_frame(self.codec_context, self.frame)) {
    c.AVERROR_EOF, c.AVERROR(c.EAGAIN) => return null,
    else => |code| {
      try av.checkError(code);
      return self.frame;
    }
  }
}

fn readPacket(self: *const Self) !bool {
  switch (c.av_read_frame(self.format_context, self.packet)) {
    c.AVERROR_EOF => return false,
    else => |code| {
      try av.checkError(code);
      return true;
    }
  }
}

fn sendPacket(self: *const Self) !void {
  const code = c.avcodec_send_packet(self.codec_context, self.packet);
  try av.checkError(code);
}
