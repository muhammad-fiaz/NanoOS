const std = @import("std");
const uefi = std.os.uefi;

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    // Basic colors
    pub const Black = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
    pub const White = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    pub const Red = Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
    pub const Green = Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
    pub const Blue = Color{ .r = 0, .g = 0, .b = 255, .a = 255 };
    pub const Cyan = Color{ .r = 0, .g = 255, .b = 255, .a = 255 };
    pub const Magenta = Color{ .r = 255, .g = 0, .b = 255, .a = 255 };
    pub const Yellow = Color{ .r = 255, .g = 255, .b = 0, .a = 255 };
    pub const Transparent = Color{ .r = 0, .g = 0, .b = 0, .a = 0 };

    // Grays
    pub const Gray = Color{ .r = 128, .g = 128, .b = 128, .a = 255 };
    pub const DarkGray = Color{ .r = 50, .g = 50, .b = 50, .a = 255 };
    pub const LightGray = Color{ .r = 180, .g = 180, .b = 180, .a = 255 };
    pub const Silver = Color{ .r = 192, .g = 192, .b = 192, .a = 255 };

    // NanoOS Theme
    pub const NanoBlue = Color{ .r = 50, .g = 100, .b = 200, .a = 255 };
    pub const NanoDarkBlue = Color{ .r = 30, .g = 60, .b = 140, .a = 255 };
    pub const NanoLightBlue = Color{ .r = 100, .g = 150, .b = 230, .a = 255 };
    pub const NanoAccent = Color{ .r = 0, .g = 150, .b = 255, .a = 255 };

    // UI Colors
    pub const DarkBackground = Color{ .r = 25, .g = 25, .b = 30, .a = 255 };
    pub const LightBackground = Color{ .r = 240, .g = 240, .b = 245, .a = 255 };
    pub const WindowBackground = Color{ .r = 40, .g = 40, .b = 45, .a = 255 };
    pub const TitleBarActive = Color{ .r = 50, .g = 50, .b = 60, .a = 255 };
    pub const TitleBarInactive = Color{ .r = 35, .g = 35, .b = 40, .a = 255 };
    pub const ButtonNormal = Color{ .r = 60, .g = 60, .b = 70, .a = 255 };
    pub const ButtonHover = Color{ .r = 70, .g = 70, .b = 80, .a = 255 };
    pub const ButtonActive = Color{ .r = 80, .g = 80, .b = 90, .a = 255 };
    pub const ButtonDanger = Color{ .r = 200, .g = 50, .b = 50, .a = 255 };
    pub const Warning = Color{ .r = 255, .g = 200, .b = 0, .a = 255 };
    pub const Success = Color{ .r = 50, .g = 200, .b = 50, .a = 255 };

    // Modern UI Colors
    pub const CardBackground = Color{ .r = 35, .g = 35, .b = 40, .a = 255 };
    pub const Hover = Color{ .r = 60, .g = 60, .b = 70, .a = 255 };
    pub const Selected = Color{ .r = 50, .g = 100, .b = 180, .a = 255 };

    // Status colors
    pub const Error = Color{ .r = 220, .g = 60, .b = 60, .a = 255 };
    pub const Info = Color{ .r = 60, .g = 150, .b = 220, .a = 255 };

    // Pastel colors
    pub const PastelPink = Color{ .r = 255, .g = 182, .b = 193, .a = 255 };
    pub const PastelBlue = Color{ .r = 173, .g = 216, .b = 230, .a = 255 };
    pub const PastelGreen = Color{ .r = 144, .g = 238, .b = 144, .a = 255 };
    pub const PastelYellow = Color{ .r = 255, .g = 255, .b = 200, .a = 255 };
    pub const PastelPurple = Color{ .r = 200, .g = 162, .b = 200, .a = 255 };

    // Dark mode colors
    pub const DarkSurface = Color{ .r = 40, .g = 40, .b = 45, .a = 255 };
    pub const DarkSurfaceLight = Color{ .r = 55, .g = 55, .b = 60, .a = 255 };
    pub const DarkBorder = Color{ .r = 70, .g = 70, .b = 75, .a = 255 };
    pub const DarkText = Color{ .r = 220, .g = 220, .b = 225, .a = 255 };
    pub const DarkTextSecondary = Color{ .r = 150, .g = 150, .b = 155, .a = 255 };

    // Window colors
    pub const WindowBorder = Color{ .r = 80, .g = 80, .b = 85, .a = 255 };

    // Button colors
    pub const ButtonPrimary = Color{ .r = 50, .g = 120, .b = 200, .a = 255 };
    pub const ButtonSecondary = Color{ .r = 70, .g = 70, .b = 75, .a = 255 };
    pub const ButtonSuccess = Color{ .r = 50, .g = 160, .b = 80, .a = 255 };

    // Cursor color
    pub const CursorWhite = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    pub const CursorOutline = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };

    // Helper functions
    pub fn blend(self: Color, other: Color, alpha: u8) Color {
        const a = @as(u16, alpha);
        const inv_a = 255 - a;
        return Color{
            .r = @intCast((@as(u16, self.r) * inv_a + @as(u16, other.r) * a) / 255),
            .g = @intCast((@as(u16, self.g) * inv_a + @as(u16, other.g) * a) / 255),
            .b = @intCast((@as(u16, self.b) * inv_a + @as(u16, other.b) * a) / 255),
            .a = 255,
        };
    }

    pub fn darken(self: Color, amount: u8) Color {
        return Color{
            .r = if (self.r > amount) self.r - amount else 0,
            .g = if (self.g > amount) self.g - amount else 0,
            .b = if (self.b > amount) self.b - amount else 0,
            .a = self.a,
        };
    }

    pub fn lighten(self: Color, amount: u8) Color {
        return Color{
            .r = if (@as(u16, self.r) + amount < 255) self.r + amount else 255,
            .g = if (@as(u16, self.g) + amount < 255) self.g + amount else 255,
            .b = if (@as(u16, self.b) + amount < 255) self.b + amount else 255,
            .a = self.a,
        };
    }
};

pub const FrameBuffer = struct {
    base: [*]u32,
    width: u32,
    height: u32,
    pitch: u32, // Pixels per scanline (stride)

    pub fn init(boot_services: *uefi.tables.BootServices) !FrameBuffer {
        const gop_opt = boot_services.locateProtocol(uefi.protocol.GraphicsOutput, null) catch return error.GopNotFound;
        const gop = gop_opt orelse return error.GopNotFound;

        const mode = gop.mode;
        const info = mode.info;

        return FrameBuffer{
            .base = @ptrFromInt(mode.frame_buffer_base),
            .width = info.horizontal_resolution,
            .height = info.vertical_resolution,
            .pitch = info.pixels_per_scan_line,
        };
    }

    pub fn clear(self: *FrameBuffer, color: Color) void {
        const c = self.colorToU32(color);
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                self.base[y * self.pitch + x] = c;
            }
        }
    }

    pub fn putPixel(self: *FrameBuffer, x: u32, y: u32, color: Color) void {
        if (x >= self.width or y >= self.height) return;
        self.base[y * self.pitch + x] = self.colorToU32(color);
    }

    pub fn fillRect(self: *FrameBuffer, x: u32, y: u32, w: u32, h: u32, color: Color) void {
        const c = self.colorToU32(color);
        const end_x = @min(x + w, self.width);
        const end_y = @min(y + h, self.height);

        var curr_y = y;
        while (curr_y < end_y) : (curr_y += 1) {
            var curr_x = x;
            while (curr_x < end_x) : (curr_x += 1) {
                self.base[curr_y * self.pitch + curr_x] = c;
            }
        }
    }

    fn colorToU32(self: *FrameBuffer, color: Color) u32 {
        _ = self;
        // UEFI GOP is usually BGR or RGB. We assume BGR reserved 8 bit (Blue, Green, Red, Reserved)
        // Ideally we check gop.mode.info.pixel_format
        return (@as(u32, 0) << 24) | (@as(u32, color.r) << 16) | (@as(u32, color.g) << 8) | @as(u32, color.b);
    }

    pub fn getPixel(self: *FrameBuffer, x: u32, y: u32) u32 {
        if (x >= self.width or y >= self.height) return 0;
        return self.base[y * self.pitch + x];
    }

    pub fn u32ToColor(self: *FrameBuffer, c: u32) Color {
        _ = self;
        return Color{ .r = @truncate(c >> 16), .g = @truncate(c >> 8), .b = @truncate(c), .a = 255 };
    }
};
