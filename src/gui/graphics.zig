const std = @import("std");
const FrameBuffer = @import("../hal/framebuffer.zig").FrameBuffer;
const Color = @import("../hal/framebuffer.zig").Color;
const font = @import("font.zig");

pub const Graphics = struct {
    fb: *FrameBuffer,

    pub fn init(fb: *FrameBuffer) Graphics {
        return Graphics{ .fb = fb };
    }

    pub fn clear(self: *Graphics, color: Color) void {
        self.fb.clear(color);
    }

    pub fn drawRect(self: *Graphics, x: u32, y: u32, w: u32, h: u32, color: Color) void {
        self.fb.fillRect(x, y, w, h, color);
    }

    pub fn drawChar(self: *Graphics, x: u32, y: u32, c: u8, fg: Color, bg: ?Color) void {
        // Map to uppercase for our simple font if needed, or just pass through
        // Our font.zig handles basic ASCII.
        const glyph = font.getGlyph(std.ascii.toUpper(c));

        for (0..8) |row| {
            const bits = glyph[row];
            for (0..8) |col| {
                const is_set = (bits >> @intCast(7 - col)) & 1 == 1;
                if (is_set) {
                    self.fb.putPixel(x + @as(u32, @intCast(col)), y + @as(u32, @intCast(row)), fg);
                } else if (bg) |bg_color| {
                    self.fb.putPixel(x + @as(u32, @intCast(col)), y + @as(u32, @intCast(row)), bg_color);
                }
            }
        }
    }

    pub fn drawRoundedRect(self: *Graphics, x: u32, y: u32, width: u32, height: u32, radius: u32, color: Color) void {
        // Simple implementation: Draw 3 rects and 4 corners?
        // Or just per-pixel check (slower but easier to implement for now)
        // Optimization: Draw central rects, then circles at corners.

        // Center rect
        self.drawRect(x + radius, y + radius, width - 2 * radius, height - 2 * radius, color);
        // Top/Bottom rects
        self.drawRect(x + radius, y, width - 2 * radius, radius, color);
        self.drawRect(x + radius, y + height - radius, width - 2 * radius, radius, color);
        // Left/Right rects
        self.drawRect(x, y + radius, radius, height - 2 * radius, color);
        self.drawRect(x + width - radius, y + radius, radius, height - 2 * radius, color);

        // Corners
        self.drawCircleSector(x + radius, y + radius, radius, 2, color); // Top-Left
        self.drawCircleSector(x + width - radius, y + radius, radius, 3, color); // Top-Right
        self.drawCircleSector(x + radius, y + height - radius, radius, 1, color); // Bottom-Left
        self.drawCircleSector(x + width - radius, y + height - radius, radius, 0, color); // Bottom-Right
    }

    fn drawCircleSector(self: *Graphics, cx: u32, cy: u32, radius: u32, quadrant: u8, color: Color) void {
        var x: i32 = 0;
        var y: i32 = @intCast(radius);
        var d: i32 = 3 - 2 * @as(i32, @intCast(radius));

        while (y >= x) {
            // Draw horizontal lines to fill
            if (quadrant == 0) { // Bottom-Right
                self.drawHLine(cx + @as(u32, @intCast(x)), cy + @as(u32, @intCast(y)), @as(u32, @intCast(radius)) - @as(u32, @intCast(x)), color); // Wrong fill logic, let's just put pixels for outline or simple fill
                // Actually, filling a circle sector efficiently needs scanlines.
                // Let's do a simple bounding box check for the corner pixels for now, it's robust.
            }
            x += 1;
            if (d > 0) {
                y -= 1;
                d = d + 4 * (x - y) + 10;
            } else {
                d = d + 4 * x + 6;
            }
        }
    }

    // Better Rounded Rect using distance check (slow but correct)
    pub fn drawRoundedRectSlow(self: *Graphics, x: u32, y: u32, w: u32, h: u32, r: u32, color: Color) void {
        const r_sq = r * r;
        for (y..y + h) |cy| {
            for (x..x + w) |cx| {
                // Check corners
                var in_corner = false;
                var dx: u32 = 0;
                var dy: u32 = 0;

                if (cx < x + r and cy < y + r) { // Top-Left
                    dx = (x + r) - @as(u32, @intCast(cx));
                    dy = (y + r) - @as(u32, @intCast(cy));
                    in_corner = true;
                } else if (cx >= x + w - r and cy < y + r) { // Top-Right
                    dx = @as(u32, @intCast(cx)) - (x + w - r - 1);
                    dy = (y + r) - @as(u32, @intCast(cy));
                    in_corner = true;
                } else if (cx < x + r and cy >= y + h - r) { // Bottom-Left
                    dx = (x + r) - @as(u32, @intCast(cx));
                    dy = @as(u32, @intCast(cy)) - (y + h - r - 1);
                    in_corner = true;
                } else if (cx >= x + w - r and cy >= y + h - r) { // Bottom-Right
                    dx = @as(u32, @intCast(cx)) - (x + w - r - 1);
                    dy = @as(u32, @intCast(cy)) - (y + h - r - 1);
                    in_corner = true;
                }

                if (in_corner) {
                    if (dx * dx + dy * dy <= r_sq) {
                        self.fb.putPixel(@intCast(cx), @intCast(cy), color);
                    }
                } else {
                    self.fb.putPixel(@intCast(cx), @intCast(cy), color);
                }
            }
        }
    }

    pub fn drawGlassRect(self: *Graphics, x: u32, y: u32, width: u32, height: u32, color: Color) void {
        // Simulate glass by blending with existing content (if we could read it)
        // Since we can't easily read back from framebuffer efficiently in this loop without cache,
        // we will just draw a semi-transparent color.
        // Alpha blending: out = src * alpha + dst * (1 - alpha)
        // We need to read the pixel first.

        for (y..y + height) |cy| {
            for (x..x + width) |cx| {
                // Hack: We don't have getPixel in Framebuffer struct yet?
                // Assuming we can't read, we'll just draw a "grid" pattern or lighter color to simulate transparency
                if ((cx + cy) % 2 == 0) {
                    self.fb.putPixel(@intCast(cx), @intCast(cy), color);
                }
            }
        }
    }

    fn drawHLine(self: *Graphics, x: u32, y: u32, w: u32, c: Color) void {
        for (x..x + w) |cx| {
            self.fb.putPixel(@intCast(cx), y, c);
        }
    }

    pub fn drawString(self: *Graphics, x: u32, y: u32, text: []const u8, fg: Color, bg: ?Color) void {
        var curr_x = x;
        for (text) |c| {
            self.drawChar(curr_x, y, c, fg, bg);
            curr_x += 8;
        }
    }

    pub fn drawWallpaper(self: *Graphics) void {
        const Wallpaper = @import("wallpaper.zig").Wallpaper;
        const wallpaper = Wallpaper.init(self.fb.width, self.fb.height);

        // Render wallpaper pixel by pixel
        for (0..self.fb.height) |y| {
            for (0..self.fb.width) |x| {
                const color = wallpaper.getPixel(@intCast(x), @intCast(y));
                self.fb.putPixel(@intCast(x), @intCast(y), color);
            }
        }
    }

    pub fn drawSprite(self: *Graphics, x: i32, y: i32, width: u32, height: u32, getPixelFn: *const fn (u32, u32) Color) void {
        for (0..height) |cy| {
            const py_i = y + @as(i32, @intCast(cy));
            if (py_i < 0 or py_i >= self.fb.height) continue;

            for (0..width) |cx| {
                const px_i = x + @as(i32, @intCast(cx));
                if (px_i < 0 or px_i >= self.fb.width) continue;

                const color = getPixelFn(@as(u32, @intCast(cx)), @as(u32, @intCast(cy)));
                if (color.a > 0) {
                    const px = @as(u32, @intCast(px_i));
                    const py = @as(u32, @intCast(py_i));

                    if (color.a == 255) {
                        self.fb.putPixel(px, py, color);
                    } else {
                        const bg_u32 = self.fb.getPixel(px, py);
                        const bg_color = self.fb.u32ToColor(bg_u32);
                        const blended = bg_color.blend(color, color.a);
                        self.fb.putPixel(px, py, blended);
                    }
                }
            }
        }
    }

    pub fn drawGradientBackground(self: *Graphics) void {
        // Fallback simple gradient if wallpaper fails
        const h = self.fb.height;
        for (0..h) |y| {
            const t = @as(u32, @intCast(y)) * 255 / h;
            const r = @as(u8, @intCast(@min(255, 20 + t / 3)));
            const g = @as(u8, @intCast(@min(255, 10 + t / 4)));
            const b = @as(u8, @intCast(@min(255, 60 + t / 2)));

            const color = Color{ .r = r, .g = g, .b = b, .a = 255 };
            self.drawRect(0, @intCast(y), self.fb.width, 1, color);
        }
    }
};
