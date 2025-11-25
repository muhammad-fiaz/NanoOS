const std = @import("std");
const Graphics = @import("../gui/graphics.zig").Graphics;
const Color = @import("../hal/framebuffer.zig").Color;

pub const Settings = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    selected_tab: u8 = 0, // 0=Display, 1=Network, 2=Hardware, 3=System, 4=About
    wallpaper_index: u8 = 0,
    brightness: u8 = 100,
    volume: u8 = 75,

    // Network settings
    wifi_enabled: bool = true,
    ethernet_connected: bool = true,

    // Hardware settings
    cpu_performance: u8 = 2, // 0=PowerSave, 1=Balanced, 2=Performance
    gpu_acceleration: bool = true,

    pub fn init(x: u32, y: u32, w: u32, h: u32) Settings {
        return Settings{
            .x = x,
            .y = y,
            .width = w,
            .height = h,
        };
    }

    pub fn draw(self: *Settings, gfx: *Graphics) void {
        const bg = Color{ .r = 30, .g = 30, .b = 35, .a = 255 };
        gfx.drawRect(self.x, self.y, self.width, self.height, bg);

        // Sidebar
        const sidebar_bg = Color{ .r = 25, .g = 25, .b = 30, .a = 255 };
        gfx.drawRect(self.x, self.y, 100, self.height, sidebar_bg);

        // Tab buttons
        const tabs = [_][]const u8{ "Display", "Network", "Hardware", "System", "About" };
        var tab_y: u32 = self.y + 10;

        for (tabs, 0..) |tab, i| {
            const is_selected = (i == self.selected_tab);
            const tab_bg = if (is_selected) Color.NanoBlue else sidebar_bg;
            const fg = if (is_selected) Color.White else Color.Gray;

            if (is_selected) {
                gfx.drawRect(self.x + 4, tab_y, 92, 22, tab_bg);
            }
            gfx.drawString(self.x + 10, tab_y + 6, tab, fg, tab_bg);
            tab_y += 28;
        }

        // Separator
        gfx.drawRect(self.x + 100, self.y, 1, self.height, Color.DarkGray);

        // Content area
        const content_x = self.x + 110;
        const content_y = self.y + 10;

        switch (self.selected_tab) {
            0 => self.drawDisplaySettings(gfx, content_x, content_y),
            1 => self.drawNetworkSettings(gfx, content_x, content_y),
            2 => self.drawHardwareSettings(gfx, content_x, content_y),
            3 => self.drawSystemSettings(gfx, content_x, content_y),
            4 => self.drawAbout(gfx, content_x, content_y),
            else => {},
        }
    }

    fn drawDisplaySettings(self: *Settings, gfx: *Graphics, x: u32, y: u32) void {
        const bg = Color{ .r = 30, .g = 30, .b = 35, .a = 255 };
        gfx.drawString(x, y, "Display Settings", Color.NanoAccent, bg);

        // Wallpaper
        gfx.drawString(x, y + 24, "Wallpaper:", Color.White, bg);
        gfx.drawRect(x, y + 40, 150, 20, Color{ .r = 40, .g = 40, .b = 45, .a = 255 });
        var wp_buf: [16]u8 = undefined;
        const wp_str = std.fmt.bufPrint(&wp_buf, "Wallpaper {d}", .{self.wallpaper_index + 1}) catch "Wallpaper";
        gfx.drawString(x + 8, y + 44, wp_str, Color.White, Color{ .r = 40, .g = 40, .b = 45, .a = 255 });
        gfx.drawString(x + 160, y + 44, "[W]+/-", Color.Gray, bg);

        // Brightness
        gfx.drawString(x, y + 74, "Brightness:", Color.White, bg);
        self.drawSlider(gfx, x, y + 90, 150, self.brightness);
        var br_buf: [8]u8 = undefined;
        const br_str = std.fmt.bufPrint(&br_buf, "{d}%", .{self.brightness}) catch "?%";
        gfx.drawString(x + 160, y + 90, br_str, Color.Gray, bg);

        // Resolution info
        gfx.drawString(x, y + 124, "Resolution:", Color.White, bg);
        gfx.drawString(x + 90, y + 124, "Auto (UEFI GOP)", Color.Gray, bg);

        gfx.drawString(x, y + 144, "Color Depth:", Color.White, bg);
        gfx.drawString(x + 100, y + 144, "32-bit BGRA", Color.Gray, bg);
    }

    fn drawNetworkSettings(self: *Settings, gfx: *Graphics, x: u32, y: u32) void {
        const bg = Color{ .r = 30, .g = 30, .b = 35, .a = 255 };
        gfx.drawString(x, y, "Network Settings", Color.NanoAccent, bg);

        // WiFi
        gfx.drawString(x, y + 24, "WiFi:", Color.White, bg);
        const wifi_status = if (self.wifi_enabled) "Enabled" else "Disabled";
        const wifi_color = if (self.wifi_enabled) Color.Success else Color.Error;
        gfx.drawString(x + 60, y + 24, wifi_status, wifi_color, bg);
        gfx.drawString(x + 140, y + 24, "[1]Toggle", Color.Gray, bg);

        if (self.wifi_enabled) {
            gfx.drawString(x + 20, y + 44, "SSID: NanoNet", Color.Gray, bg);
            gfx.drawString(x + 20, y + 60, "Signal: Excellent", Color.Success, bg);
            gfx.drawString(x + 20, y + 76, "IP: 192.168.1.100", Color.Gray, bg);
        }

        // Ethernet
        gfx.drawString(x, y + 100, "Ethernet:", Color.White, bg);
        const eth_status = if (self.ethernet_connected) "Connected" else "Disconnected";
        const eth_color = if (self.ethernet_connected) Color.Success else Color.Warning;
        gfx.drawString(x + 80, y + 100, eth_status, eth_color, bg);
        gfx.drawString(x + 180, y + 100, "[2]Toggle", Color.Gray, bg);

        if (self.ethernet_connected) {
            gfx.drawString(x + 20, y + 120, "Speed: 1 Gbps", Color.Gray, bg);
            gfx.drawString(x + 20, y + 136, "IP: 192.168.1.50", Color.Gray, bg);
            gfx.drawString(x + 20, y + 152, "Gateway: 192.168.1.1", Color.Gray, bg);
        }

        // Network status
        gfx.drawRect(x, y + 176, self.width - 120, 1, Color.DarkGray);
        gfx.drawString(x, y + 184, "Status: Online", Color.Success, bg);
        gfx.drawString(x, y + 200, "DNS: 8.8.8.8", Color.Gray, bg);
    }

    fn drawHardwareSettings(self: *Settings, gfx: *Graphics, x: u32, y: u32) void {
        const bg = Color{ .r = 30, .g = 30, .b = 35, .a = 255 };
        gfx.drawString(x, y, "Hardware Settings", Color.NanoAccent, bg);

        // CPU
        gfx.drawString(x, y + 24, "CPU Performance:", Color.White, bg);
        const cpu_modes = [_][]const u8{ "PowerSave", "Balanced", "Performance" };
        const cpu_colors = [_]Color{ Color.Success, Color.Warning, Color.Error };
        gfx.drawString(x + 130, y + 24, cpu_modes[self.cpu_performance], cpu_colors[self.cpu_performance], bg);
        gfx.drawString(x, y + 40, "[C] Cycle mode", Color.Gray, bg);

        // CPU Info
        gfx.drawString(x + 20, y + 60, "Arch: x86_64", Color.Gray, bg);
        gfx.drawString(x + 20, y + 76, "Cores: 4 (simulated)", Color.Gray, bg);
        gfx.drawString(x + 20, y + 92, "Usage: ~5%", Color.Gray, bg);

        // GPU
        gfx.drawRect(x, y + 112, self.width - 120, 1, Color.DarkGray);
        gfx.drawString(x, y + 120, "GPU Acceleration:", Color.White, bg);
        const gpu_status = if (self.gpu_acceleration) "Enabled" else "Disabled";
        const gpu_color = if (self.gpu_acceleration) Color.Success else Color.Gray;
        gfx.drawString(x + 140, y + 120, gpu_status, gpu_color, bg);
        gfx.drawString(x, y + 136, "[G] Toggle", Color.Gray, bg);

        // GPU Info
        gfx.drawString(x + 20, y + 156, "Driver: UEFI GOP", Color.Gray, bg);
        gfx.drawString(x + 20, y + 172, "VRAM: Shared", Color.Gray, bg);

        // Memory
        gfx.drawRect(x, y + 192, self.width - 120, 1, Color.DarkGray);
        gfx.drawString(x, y + 200, "Memory: 512 MB", Color.White, bg);
    }

    fn drawSystemSettings(_: *Settings, gfx: *Graphics, x: u32, y: u32) void {
        const bg = Color{ .r = 30, .g = 30, .b = 35, .a = 255 };
        gfx.drawString(x, y, "System Settings", Color.NanoAccent, bg);

        // Power options
        gfx.drawString(x, y + 24, "Power Options:", Color.White, bg);

        // Shutdown button
        gfx.drawRect(x, y + 44, 100, 28, Color.Error);
        gfx.drawString(x + 16, y + 52, "Shutdown", Color.White, Color.Error);
        gfx.drawString(x + 110, y + 52, "[S]", Color.Gray, bg);

        // Restart button
        gfx.drawRect(x, y + 80, 100, 28, Color.Warning);
        gfx.drawString(x + 20, y + 88, "Restart", Color.White, Color.Warning);
        gfx.drawString(x + 110, y + 88, "[R]", Color.Gray, bg);

        // Sleep button
        gfx.drawRect(x, y + 116, 100, 28, Color.NanoBlue);
        gfx.drawString(x + 28, y + 124, "Sleep", Color.White, Color.NanoBlue);
        gfx.drawString(x + 110, y + 124, "[Z]", Color.Gray, bg);

        // System info
        gfx.drawRect(x, y + 156, 200, 1, Color.DarkGray);
        gfx.drawString(x, y + 164, "System Information:", Color.White, bg);
        gfx.drawString(x + 20, y + 184, "OS: NanoOS v1.0.0", Color.Gray, bg);
        gfx.drawString(x + 20, y + 200, "Platform: x86_64-UEFI", Color.Gray, bg);
        gfx.drawString(x + 20, y + 216, "Built with: Zig 0.15", Color.Gray, bg);
    }

    fn drawAbout(_: *Settings, gfx: *Graphics, x: u32, y: u32) void {
        const bg = Color{ .r = 30, .g = 30, .b = 35, .a = 255 };

        // Logo area
        gfx.drawRect(x + 50, y, 80, 40, Color.NanoBlue);
        gfx.drawString(x + 60, y + 14, "NanoOS", Color.White, Color.NanoBlue);

        gfx.drawString(x, y + 54, "Version: 1.0.0", Color.White, bg);
        gfx.drawString(x, y + 74, "A lightweight UEFI OS", Color.Gray, bg);

        gfx.drawRect(x, y + 94, 200, 1, Color.DarkGray);

        gfx.drawString(x, y + 104, "Features:", Color.NanoAccent, bg);
        gfx.drawString(x + 10, y + 122, "- Modern GUI Desktop", Color.Gray, bg);
        gfx.drawString(x + 10, y + 138, "- Mouse & Keyboard Input", Color.Gray, bg);
        gfx.drawString(x + 10, y + 154, "- Multiple Applications", Color.Gray, bg);
        gfx.drawString(x + 10, y + 170, "- File Manager + Recycle Bin", Color.Gray, bg);
        gfx.drawString(x + 10, y + 186, "- System Settings", Color.Gray, bg);

        gfx.drawRect(x, y + 206, 200, 1, Color.DarkGray);
        gfx.drawString(x, y + 214, "Built with Zig language", Color.Gray, bg);
    }

    fn drawSlider(_: *Settings, gfx: *Graphics, x: u32, y: u32, width: u32, value: u8) void {
        // Background
        gfx.drawRect(x, y + 4, width, 8, Color{ .r = 50, .g = 50, .b = 55, .a = 255 });

        // Fill
        const fill_width = (width * @as(u32, value)) / 100;
        gfx.drawRect(x, y + 4, fill_width, 8, Color.NanoBlue);

        // Handle
        gfx.drawRect(x + fill_width - 2, y, 6, 16, Color.White);
    }

    pub fn handleInput(self: *Settings, char: u16) ?SystemAction {
        // Tab switching with numbers 1-5
        if (char >= '1' and char <= '5') {
            self.selected_tab = @intCast(char - '1');
            return null;
        }

        // Tab-specific controls
        switch (self.selected_tab) {
            0 => { // Display
                switch (char) {
                    'w', 'W' => self.wallpaper_index = (self.wallpaper_index + 1) % 5,
                    '+', '=' => self.brightness = @min(100, self.brightness + 10),
                    '-', '_' => self.brightness = self.brightness -| 10,
                    else => {},
                }
            },
            1 => { // Network
                switch (char) {
                    '1' => {}, // Already handled above
                    '2' => self.ethernet_connected = !self.ethernet_connected,
                    else => {
                        if (char == '!' or char == 0x31) { // Shift+1 or 1
                            self.wifi_enabled = !self.wifi_enabled;
                        }
                    },
                }
            },
            2 => { // Hardware
                switch (char) {
                    'c', 'C' => self.cpu_performance = (self.cpu_performance + 1) % 3,
                    'g', 'G' => self.gpu_acceleration = !self.gpu_acceleration,
                    else => {},
                }
            },
            3 => { // System
                switch (char) {
                    's', 'S' => return .Shutdown,
                    'r', 'R' => return .Restart,
                    'z', 'Z' => return .Sleep,
                    else => {},
                }
            },
            else => {},
        }
        return null;
    }

    pub fn handleClick(self: *Settings, mx: u32, my: u32) ?SystemAction {
        // Check sidebar tabs
        if (mx >= self.x and mx < self.x + 100) {
            const tab_y_start = self.y + 10;
            if (my >= tab_y_start and my < tab_y_start + 140) {
                const tab_idx = (my - tab_y_start) / 28;
                if (tab_idx < 5) {
                    self.selected_tab = @intCast(tab_idx);
                }
            }
        }

        // Check power buttons in System tab
        if (self.selected_tab == 3) {
            const content_x = self.x + 110;
            const btn_x_end = content_x + 100;

            if (mx >= content_x and mx < btn_x_end) {
                // Shutdown
                if (my >= self.y + 54 and my < self.y + 82) {
                    return .Shutdown;
                }
                // Restart
                if (my >= self.y + 90 and my < self.y + 118) {
                    return .Restart;
                }
                // Sleep
                if (my >= self.y + 126 and my < self.y + 154) {
                    return .Sleep;
                }
            }
        }

        return null;
    }
};

pub const SystemAction = enum {
    None,
    Shutdown,
    Restart,
    Sleep,
};
