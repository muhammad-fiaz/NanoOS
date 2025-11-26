const std = @import("std");
const Graphics = @import("../gui/graphics.zig").Graphics;
const Color = @import("../hal/framebuffer.zig").Color;
const TerminalIcon = @import("../assets/icons/apps/terminal_icon.zig");

pub const TerminalAction = enum {
    None,
    Shutdown,
    Reboot,
    OpenAbout,
    OpenColors,
    OpenSettings,
    OpenCalc,
    OpenEditor,
    OpenFiles,
    Clear,
};

pub const Terminal = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    cursor_x: u32,
    cursor_y: u32,
    prompt: []const u8 = "nano> ",
    buffer: [128]u8 = undefined,
    buffer_len: usize = 0,
    history: [8][128]u8 = undefined,
    history_count: usize = 0,
    output_lines: [32][80]u8 = undefined,
    output_lengths: [32]usize = .{0} ** 32,
    output_count: usize = 0,

    pub fn init(x: u32, y: u32, w: u32, h: u32) Terminal {
        return Terminal{
            .x = x,
            .y = y,
            .width = w,
            .height = h,
            .cursor_x = 0,
            .cursor_y = 0,
        };
    }

    pub fn drawContent(self: *Terminal, gfx: *Graphics) void {
        // Clear terminal area
        gfx.drawRect(self.x, self.y, self.width, self.height, Color.Black);

        // Welcome banner
        // Welcome banner with Icon
        gfx.drawSprite(@intCast(self.x + 5), @intCast(self.y + 5), 32, 32, struct {
            pub fn getPixel(x: u32, y: u32) Color {
                return TerminalIcon.getScaledPixel(x, y, 32, 32);
            }
        }.getPixel);

        gfx.drawString(self.x + 45, self.y + 10, "NanoOS Terminal v1.0", Color.NanoAccent, Color.Black);
        gfx.drawString(self.x + 45, self.y + 22, "Type 'help' for commands", Color.DarkTextSecondary, Color.Black);

        // Draw output history
        var line_y = self.y + 35;
        var i: usize = 0;
        while (i < self.output_count and line_y < self.y + self.height - 30) : (i += 1) {
            if (self.output_lengths[i] > 0) {
                gfx.drawString(self.x + 5, line_y, self.output_lines[i][0..self.output_lengths[i]], Color.White, Color.Black);
            }
            line_y += 12;
        }

        // Draw current prompt and input
        self.cursor_y = @intCast(line_y - self.y);
        self.printPromptAt(gfx, line_y);

        // Draw current input
        if (self.buffer_len > 0) {
            gfx.drawString(self.x + 5 + @as(u32, @intCast(self.prompt.len * 8)), line_y, self.buffer[0..self.buffer_len], Color.White, Color.Black);
        }
    }

    fn printPromptAt(self: *Terminal, gfx: *Graphics, y: u32) void {
        gfx.drawString(self.x + 5, y, self.prompt, Color.Success, Color.Black);
    }

    pub fn handleInput(self: *Terminal, gfx: *Graphics, char: u16) TerminalAction {
        _ = gfx;

        if (char == '\r' or char == 13) {
            const cmd = self.buffer[0..self.buffer_len];
            var action = TerminalAction.None;

            if (std.mem.eql(u8, cmd, "help")) {
                self.addOutput("=== NanoOS Commands ===");
                self.addOutput("help     - Show this help");
                self.addOutput("clear    - Clear screen");
                self.addOutput("about    - About NanoOS");
                self.addOutput("sysinfo  - System information");
                self.addOutput("time     - Show current time");
                self.addOutput("uptime   - Show system uptime");
                self.addOutput("memory   - Memory information");
                self.addOutput("network  - Network status");
                self.addOutput("hardware - Hardware info");
                self.addOutput("ls       - List files");
                self.addOutput("echo     - Echo text");
                self.addOutput("calc     - Open calculator");
                self.addOutput("edit     - Open text editor");
                self.addOutput("files    - Open file manager");
                self.addOutput("settings - System settings");
                self.addOutput("colors   - Color test");
                self.addOutput("shutdown - Power off");
                self.addOutput("reboot   - Restart system");
            } else if (std.mem.eql(u8, cmd, "clear")) {
                self.output_count = 0;
                action = .Clear;
            } else if (std.mem.eql(u8, cmd, "about")) {
                action = .OpenAbout;
            } else if (std.mem.eql(u8, cmd, "colors")) {
                action = .OpenColors;
            } else if (std.mem.eql(u8, cmd, "calc")) {
                action = .OpenCalc;
            } else if (std.mem.eql(u8, cmd, "edit")) {
                action = .OpenEditor;
            } else if (std.mem.eql(u8, cmd, "files")) {
                action = .OpenFiles;
            } else if (std.mem.eql(u8, cmd, "settings")) {
                action = .OpenSettings;
            } else if (std.mem.eql(u8, cmd, "sysinfo")) {
                self.addOutput("=== System Information ===");
                self.addOutput("OS: NanoOS v1.0.0");
                self.addOutput("Architecture: x86_64-UEFI");
                self.addOutput("Built with: Zig 0.15");
                self.addOutput("Platform: UEFI Application");
            } else if (std.mem.eql(u8, cmd, "time")) {
                self.addOutput("Time: (UEFI RTC) 12:00:00");
            } else if (std.mem.eql(u8, cmd, "uptime")) {
                self.addOutput("Uptime: 0h 0m (since boot)");
            } else if (std.mem.eql(u8, cmd, "memory")) {
                self.addOutput("=== Memory Information ===");
                self.addOutput("Total: 512 MB");
                self.addOutput("Used: 64 MB");
                self.addOutput("Free: 448 MB");
                self.addOutput("Kernel: 32 MB");
            } else if (std.mem.eql(u8, cmd, "network")) {
                self.addOutput("=== Network Status ===");
                self.addOutput("WiFi: Enabled (NanoNet)");
                self.addOutput("Signal: Excellent (85%)");
                self.addOutput("IP: 192.168.1.100");
                self.addOutput("Ethernet: Connected (1Gbps)");
                self.addOutput("Gateway: 192.168.1.1");
                self.addOutput("DNS: 8.8.8.8");
            } else if (std.mem.eql(u8, cmd, "hardware")) {
                self.addOutput("=== Hardware Info ===");
                self.addOutput("CPU: x86_64 UEFI Virtual");
                self.addOutput("Cores: 4 (8 threads)");
                self.addOutput("GPU: UEFI GOP Driver");
                self.addOutput("Mode: Performance");
            } else if (std.mem.eql(u8, cmd, "ls")) {
                self.addOutput("=== /home/user/ ===");
                self.addOutput("Documents/  Pictures/");
                self.addOutput("Downloads/  System/");
                self.addOutput("readme.txt  kernel.zig");
                self.addOutput("boot.efi    config.json");
            } else if (std.mem.startsWith(u8, cmd, "echo ")) {
                if (cmd.len > 5) {
                    self.addOutput(cmd[5..]);
                }
            } else if (std.mem.eql(u8, cmd, "shutdown")) {
                action = .Shutdown;
            } else if (std.mem.eql(u8, cmd, "reboot")) {
                action = .Reboot;
            } else if (self.buffer_len > 0) {
                self.addOutput("Unknown command. Type 'help'");
            }

            self.buffer_len = 0;
            return action;
        } else if (char == 8) { // Backspace
            if (self.buffer_len > 0) {
                self.buffer_len -= 1;
            }
        } else if (char >= 32 and char < 127) {
            if (self.buffer_len < self.buffer.len - 1) {
                const c = @as(u8, @intCast(char));
                self.buffer[self.buffer_len] = c;
                self.buffer_len += 1;
            }
        }
        return .None;
    }

    fn addOutput(self: *Terminal, text: []const u8) void {
        if (self.output_count >= 32) {
            // Shift lines up
            var i: usize = 0;
            while (i < 31) : (i += 1) {
                self.output_lines[i] = self.output_lines[i + 1];
                self.output_lengths[i] = self.output_lengths[i + 1];
            }
            self.output_count = 31;
        }

        const len = @min(text.len, 79);
        @memcpy(self.output_lines[self.output_count][0..len], text[0..len]);
        self.output_lengths[self.output_count] = len;
        self.output_count += 1;
    }
};
