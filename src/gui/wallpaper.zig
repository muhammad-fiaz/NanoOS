const std = @import("std");
const Color = @import("../hal/framebuffer.zig").Color;
const wallpaper_data = @import("../assets/wallpapers/wallpaper1_image.zig");

// Wallpaper manager - handles loading and scaling wallpaper
pub const Wallpaper = struct {
    width: u32,
    height: u32,

    pub fn init(width: u32, height: u32) Wallpaper {
        return Wallpaper{
            .width = width,
            .height = height,
        };
    }

    // Get pixel with automatic scaling to fit screen
    pub fn getPixel(self: *const Wallpaper, x: u32, y: u32) Color {
        return wallpaper_data.getScaledPixel(x, y, self.width, self.height);
    }
};
