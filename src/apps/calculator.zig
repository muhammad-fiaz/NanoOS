const std = @import("std");
const Graphics = @import("../gui/graphics.zig").Graphics;
const Color = @import("../hal/framebuffer.zig").Color;

pub const Calculator = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    display_buffer: [32]u8,
    display_len: usize,
    result: f64,

    pub fn init(x: u32, y: u32, w: u32, h: u32) Calculator {
        return Calculator{
            .x = x,
            .y = y,
            .width = w,
            .height = h,
            .display_buffer = [_]u8{0} ** 32,
            .display_len = 0,
            .result = 0,
        };
    }

    pub fn draw(self: *Calculator, gfx: *Graphics) void {
        // Background
        gfx.drawRoundedRectSlow(self.x, self.y, self.width, self.height, 10, Color{ .r = 240, .g = 240, .b = 240, .a = 255 });

        // Display Area
        gfx.drawRoundedRectSlow(self.x + 10, self.y + 10, self.width - 20, 50, 5, Color{ .r = 30, .g = 30, .b = 30, .a = 255 });

        const text = if (self.display_len == 0) "0" else self.display_buffer[0..self.display_len];
        // Right align text
        const text_width = @as(u32, @intCast(text.len)) * 8;
        const text_x = if (text_width < self.width - 40) (self.x + self.width - 30 - text_width) else self.x + 20;

        gfx.drawString(text_x, self.y + 30, text, Color.Green, Color{ .r = 30, .g = 30, .b = 30, .a = 255 });

        // Buttons (Modern Grid)
        const btn_labels = [_][]const u8{ "7", "8", "9", "/", "4", "5", "6", "*", "1", "2", "3", "-", "0", ".", "C", "+" };

        const btn_w: u32 = 50;
        const btn_h: u32 = 40;
        const gap: u32 = 10;
        const start_x = self.x + 20;
        const start_y = self.y + 80;

        var bx = start_x;
        var by = start_y;

        for (btn_labels, 0..) |lbl, i| {
            const is_op = (lbl[0] < '0' or lbl[0] > '9') and lbl[0] != '.';
            const btn_color = if (is_op) Color{ .r = 255, .g = 160, .b = 0, .a = 255 } else Color{ .r = 200, .g = 200, .b = 200, .a = 255 };
            const text_color = if (is_op) Color.White else Color.Black;

            gfx.drawRoundedRectSlow(bx, by, btn_w, btn_h, 8, btn_color);
            gfx.drawString(bx + 20, by + 12, lbl, text_color, btn_color);

            bx += btn_w + gap;
            if ((i + 1) % 4 == 0) {
                bx = start_x;
                by += btn_h + gap;
            }
        }
    }

    pub fn handleInput(self: *Calculator, char: u16) void {
        if (char >= '0' and char <= '9') {
            if (self.display_len < 31) {
                self.display_buffer[self.display_len] = @intCast(char);
                self.display_len += 1;
            }
        } else if (char == '.') {
            if (self.display_len < 31) {
                self.display_buffer[self.display_len] = '.';
                self.display_len += 1;
            }
        } else if (char == '+' or char == '-' or char == '*' or char == '/') {
            if (self.display_len < 31) {
                self.display_buffer[self.display_len] = @intCast(char);
                self.display_len += 1;
            }
        } else if (char == 'c' or char == 'C') {
            self.display_len = 0;
            self.result = 0;
        } else if (char == '=' or char == 13) { // = or Enter
            self.evaluate();
        } else if (char == 8) { // Backspace
            if (self.display_len > 0) {
                self.display_len -= 1;
            }
        }
    }

    fn evaluate(self: *Calculator) void {
        // Simple parser: Number Op Number
        // Find operator
        var op_idx: ?usize = null;
        var op: u8 = 0;

        for (self.display_buffer[0..self.display_len], 0..) |c, i| {
            if (c == '+' or c == '-' or c == '*' or c == '/') {
                op_idx = i;
                op = c;
                break;
            }
        }

        if (op_idx) |idx| {
            const left_str = self.display_buffer[0..idx];
            const right_str = self.display_buffer[idx + 1 .. self.display_len];

            const left = std.fmt.parseFloat(f64, left_str) catch 0;
            const right = std.fmt.parseFloat(f64, right_str) catch 0;

            var res: f64 = 0;
            switch (op) {
                '+' => res = left + right,
                '-' => res = left - right,
                '*' => res = left * right,
                '/' => res = if (right != 0) left / right else 0,
                else => {},
            }

            // Format result back to buffer
            const res_slice = std.fmt.bufPrint(&self.display_buffer, "{d}", .{res}) catch {
                self.display_len = 0;
                return;
            };
            self.display_len = res_slice.len;
        }
    }
};
