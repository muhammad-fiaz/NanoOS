const std = @import("std");
const Graphics = @import("../gui/graphics.zig").Graphics;
const Color = @import("../hal/framebuffer.zig").Color;

pub const Editor = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    buffer: [1024]u8,
    len: usize,
    cursor_pos: usize,

    pub fn init(x: u32, y: u32, w: u32, h: u32) Editor {
        return Editor{
            .x = x,
            .y = y,
            .width = w,
            .height = h,
            .buffer = [_]u8{0} ** 1024,
            .len = 0,
            .cursor_pos = 0,
        };
    }

    pub fn draw(self: *Editor, gfx: *Graphics) void {
        // Background (Paper look)
        gfx.drawRoundedRectSlow(self.x, self.y, self.width, self.height, 5, Color{ .r = 255, .g = 253, .b = 240, .a = 255 });

        // Text Area
        var cx: u32 = self.x + 10;
        var cy: u32 = self.y + 10;

        for (self.buffer[0..self.len]) |char| {
            if (char == '\n') {
                cx = self.x + 10;
                cy += 12;
                continue;
            }

            // Draw char
            const str = [_]u8{char};
            gfx.drawString(cx, cy, &str, Color.Black, null);
            cx += 8;

            if (cx > self.x + self.width - 15) {
                cx = self.x + 10;
                cy += 12;
            }
        }

        // Cursor (Blinking effect simulated by just drawing it)
        if (self.len < 1024) {
            gfx.drawRect(cx, cy, 2, 10, Color.Black);
        }
    }

    pub fn handleInput(self: *Editor, char: u16) void {
        if (char == 8) { // Backspace
            if (self.len > 0) {
                self.len -= 1;
            }
        } else if (char == 13) { // Enter
            if (self.len < 1024) {
                self.buffer[self.len] = '\n';
                self.len += 1;
            }
        } else if (char >= 32 and char <= 126) {
            if (self.len < 1024) {
                self.buffer[self.len] = @intCast(char);
                self.len += 1;
            }
        }
    }
};
