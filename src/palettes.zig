// https://en.wikipedia.org/wiki/Palette_(computing)#Master_palette
// https://en.wikipedia.org/wiki/List_of_color_palettes#RGB_arrangements

// https://en.wikipedia.org/wiki/List_of_software_palettes#6_level_RGB
pub const rgb666 = rgb(6, 6, 6);

// https://en.wikipedia.org/wiki/List_of_software_palettes#6-8-5_levels_RGB
pub const rgb685 = rgb(6, 8, 5);

// https://en.wikipedia.org/wiki/List_of_software_palettes#6-7-6_levels_RGB
pub const rgb676 = rgb(6, 7, 6);

// https://en.wikipedia.org/wiki/List_of_software_palettes#8-8-4_levels_RGB
pub const rgb884 = rgb(8, 8, 4);

pub fn rgb(r: usize, g: usize, b: usize) [0x100][4]u8 {
  const grayscale = 0x100 - r * g * b;
  var buffer: [0x100][4]u8 = undefined;
  for (buffer[0..grayscale]) |*bgra, i| {
    const g_u8 = @truncate(u8, (i + 1) * 0xff / (grayscale + 1));
    bgra.* = .{ g_u8, g_u8, g_u8, 0xff };
  }
  for (buffer[grayscale..]) |*bgra, i| {
    const r_u8 = @truncate(u8, i % r     * 0xff / (r - 1));
    const g_u8 = @truncate(u8, i / r % g * 0xff / (g - 1));
    const b_u8 = @truncate(u8, i / r / g * 0xff / (b - 1));
    bgra.* = .{ b_u8, g_u8, r_u8, 0xff };
  }
  return buffer;
}
