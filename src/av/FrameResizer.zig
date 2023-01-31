const c = @import("../c.zig");
const av = @import("av.zig");
const util = @import("../util.zig");
const Self = @This();

sws_context: *c.SwsContext,
frame: *c.AVFrame,

pub fn init(cc: *c.AVCodecContext, width: c_int, height: c_int) !Self {
  var frame = c.av_frame_alloc();
  try av.checkNull(frame);
  errdefer c.av_frame_free(&frame);

  frame.*.format = c.AV_PIX_FMT_RGB24;
  frame.*.width = width;
  frame.*.height = height;
  try av.checkError(c.av_frame_get_buffer(frame, 32));

  const sws_context = c.sws_getContext(
    cc.width, cc.height, cc.pix_fmt,
    width, height, frame.*.format,
    c.SWS_LANCZOS, null, null, null
  );
  try av.checkNull(sws_context);
  errdefer c.sws_freeContext(sws_context);

  return Self{
    .sws_context = sws_context.?,
    .frame = frame
  };
}

pub fn deinit(self: *const Self) void {
  var frame: ?*c.AVFrame = self.frame;
  c.sws_freeContext(self.sws_context);
  c.av_frame_free(&frame);
}

pub fn resize(self: *const Self, frame: *c.AVFrame) !*c.AVFrame {
  try av.checkError(c.av_frame_copy_props(self.frame, frame));
  try av.checkError(c.sws_scale(self.sws_context,
    &frame.data, &frame.linesize, 0, frame.height,
    &self.frame.data, &self.frame.linesize));
  return self.frame;
}
