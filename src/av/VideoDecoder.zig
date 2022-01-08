const c = @import("../c.zig");
const std = @import("std");
const av = @import("av.zig");
const util = @import("../util.zig");
const Self = @This();

video_stream: *c.AVStream,
format_context: *c.AVFormatContext,
codec_context: *c.AVCodecContext,
packet: *c.AVPacket,
frame: *c.AVFrame,

pub fn init(file: [*:0]const u8) !Self {
  c.av_register_all();

  var fmt_ctx: [*c]c.AVFormatContext = null;
  if (c.avformat_open_input(&fmt_ctx, file, null, null) != 0)
    return error.CannotOpenFile;
  errdefer c.avformat_close_input(&fmt_ctx);

  if (c.avformat_find_stream_info(fmt_ctx, null) < 0)
    return error.CannotGetStreamInfo;

  const video = switch (c.av_find_best_stream(fmt_ctx, c.AVMEDIA_TYPE_VIDEO, -1, -1, null, 0)) {
    c.AVERROR_STREAM_NOT_FOUND => return error.CannotFindVideoStreamInInputFile,
    else => |index| fmt_ctx.*.streams[@intCast(usize, index)]
  };

  const codec_params = video.*.codecpar;
  const codec = c.avcodec_find_decoder(codec_params.*.codec_id) orelse
    return error.CannotFindDecoder;

  var codec_ctx = c.avcodec_alloc_context3(codec) orelse
    return error.CannotAllocateDecoderContext;
  errdefer c.avcodec_free_context(&codec_ctx);

  if (c.avcodec_parameters_to_context(codec_ctx, codec_params) < 0)
    return error.CannotCopyDecoderContext;

  if (c.avcodec_open2(codec_ctx, codec, null) < 0)
    return error.CannotOpenDecoder;

  var frame = c.av_frame_alloc() orelse
    return error.CannotAllocateFrame;
  errdefer c.av_frame_free(&frame);

  var packet = c.av_packet_alloc() orelse
    return error.CannotAllocatePacket;
  errdefer c.av_packet_free(&packet);

  return Self{
    .video_stream = video,
    .format_context = fmt_ctx,
    .codec_context = codec_ctx,
    .packet = packet,
    .frame = frame,
  };
}

pub fn deinit(self: *Self) void {
  c.av_frame_free(&util.optional(self.frame));
  c.av_packet_free(&util.optional(self.packet));
  c.avcodec_free_context(&util.optional(self.codec_context));
  c.avformat_close_input(&util.optional(self.format_context));
}

pub fn sendPacket(self: *Self) !void {
  const code = c.avcodec_send_packet(self.codec_context, self.packet);
  if (code < 0) {
    std.log.err("{s}", .{ av.strError(code) });
    return error.ErrorWhileSendingAPacketToTheDecoder;
  }
}

pub fn receiveFrame(self: *Self) !?*c.AVFrame {
  return switch (c.avcodec_receive_frame(self.codec_context, self.frame)) {
    c.AVERROR_EOF, c.AVERROR(c.EAGAIN) => null,
    else => |code| if (code >= 0) self.frame else {
      std.log.err("{s}", .{ av.strError(code) });
      return error.ErrorWhileReceivingAFrameFromTheDecoder;
    }
  };
}

pub fn readFrame(self: *Self) !bool {
  return switch (c.av_read_frame(self.format_context, self.packet)) {
    c.AVERROR_EOF => false,
    else => |code| if (code >= 0) true else {
      std.log.err("{s}", .{ av.strError(code) });
      return error.ErrorWhileReadingAFrameFromTheDecoder;
    }
  };
}
