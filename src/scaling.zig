pub const Size = @Vector(2, c_int);

pub fn area(source: Size, target: c_int) Size {
  const w = @intToFloat(f64, source[0]);
  const h = @intToFloat(f64, source[1]);
  const t = @intToFloat(f64, target);
  const scale = @sqrt(t / w / h);
  return .{
    @floatToInt(c_int, scale * w),
    @floatToInt(c_int, scale * h),
  };
}

pub fn contain(source: Size, target: Size) Size {
  return containOrCover(source, target, false);
}

pub fn cover(source: Size, target: Size) Size {
  return containOrCover(source, target, true);
}

fn containOrCover(source: Size, target: Size, xor: bool) Size {
  const sw = @intToFloat(f64, source[0]);
  const sh = @intToFloat(f64, source[1]);
  const sr = sw / sh;
  const tw = @intToFloat(f64, target[0]);
  const th = @intToFloat(f64, target[1]);
  const tr = tw / th;
  return if ((sr > tr) != xor)
    .{ target[0], @floatToInt(c_int, tw / sr) }
  else
    .{ @floatToInt(c_int, th * sr), target[1] };
}
