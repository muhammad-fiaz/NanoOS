const std = @import("std");
const Graphics = @import("graphics.zig").Graphics;
const Color = @import("../hal/framebuffer.zig").Color;
const Terminal = @import("../apps/terminal.zig").Terminal;
const Calculator = @import("../apps/calculator.zig").Calculator;
const Editor = @import("../apps/editor.zig").Editor;
const FileManager = @import("../apps/file_manager.zig").FileManager;
const Settings = @import("../apps/settings.zig").Settings;
const MouseState = @import("../hal/mouse.zig").MouseState;

pub const WindowType = enum {
    Terminal,
    About,
    ColorTest,
    FileManager,
    Calculator,
    Editor,
    Settings,
};

pub const Window = struct {
    id: u32,
    type: WindowType,
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    title: []const u8,
    active: bool,

    terminal_state: ?Terminal = null,
    file_manager_state: ?FileManager = null,
    calculator_state: ?Calculator = null,
    editor_state: ?Editor = null,
    settings_state: ?Settings = null,

    pub fn draw(self: *Window, gfx: *Graphics) void {
        // Draw Frame
        const title_bg = if (self.active) Color.TitleBarActive else Color.TitleBarInactive;
        const window_bg = Color.WindowBackground;

        // Shadow (more subtle)
        gfx.drawRect(self.x + 6, self.y + 6, self.width, self.height, Color{ .r = 10, .g = 10, .b = 12, .a = 255 });

        // Main Window Body (Rounded)
        gfx.drawRoundedRectSlow(self.x, self.y, self.width, self.height, 10, window_bg);

        // Title Bar (Rounded Top)
        const title_height: u32 = 28;
        gfx.drawRoundedRectSlow(self.x, self.y - title_height, self.width, title_height + 5, 8, title_bg);
        // Fix bottom corners of title bar
        gfx.drawRect(self.x, self.y - 5, self.width, 10, title_bg);

        // Window title
        gfx.drawString(self.x + 12, self.y - title_height + 8, self.title, Color.White, title_bg);

        // Close button (X) - Red circle with X
        const close_x = self.x + self.width - 24;
        const close_y = self.y - title_height + 6;
        gfx.drawRoundedRectSlow(close_x, close_y, 16, 16, 8, Color.ButtonDanger);
        // Draw X
        gfx.drawString(close_x + 4, close_y + 4, "X", Color.White, Color.ButtonDanger);

        // Minimize button (optional - yellow)
        const min_x = close_x - 22;
        gfx.drawRoundedRectSlow(min_x, close_y, 16, 16, 8, Color.Warning);
        gfx.drawRect(min_x + 4, close_y + 7, 8, 2, Color.White);

        // Content Background (Inside the window)
        const content_y = self.y + 5;
        const content_h = self.height - 10;
        gfx.drawRect(self.x + 5, content_y, self.width - 10, content_h, Color.Black);

        // Draw Content
        switch (self.type) {
            .Terminal => {
                if (self.terminal_state) |*term| {
                    term.drawContent(gfx);
                }
            },
            .About => {
                gfx.drawString(self.x + 20, self.y + 20, "NanoOS v0.0.0", Color.White, Color.Black);
                gfx.drawString(self.x + 20, self.y + 40, "Modern UI Update", Color.Cyan, Color.Black);
                gfx.drawString(self.x + 20, self.y + 60, "Built with Zig", Color.Green, Color.Black);
            },
            .ColorTest => {
                // ... existing color test ...
                const block_w = self.width / 4;
                const block_h = self.height / 2;
                gfx.drawRect(self.x + 5, content_y, block_w, block_h, Color.Red);
                gfx.drawRect(self.x + 5 + block_w, content_y, block_w, block_h, Color.Green);
                gfx.drawRect(self.x + 5 + block_w * 2, content_y, block_w, block_h, Color.Blue);
                gfx.drawRect(self.x + 5 + block_w * 3, content_y, block_w, block_h, Color.White);
            },
            .FileManager => {
                if (self.file_manager_state) |*fm| {
                    fm.draw(gfx);
                }
            },
            .Calculator => {
                if (self.calculator_state) |*calc| {
                    calc.draw(gfx);
                }
            },
            .Editor => {
                if (self.editor_state) |*ed| {
                    ed.draw(gfx);
                }
            },
            .Settings => {
                if (self.settings_state) |*settings| {
                    settings.draw(gfx);
                }
            },
        }
    }

    pub fn contains(self: *Window, mx: u32, my: u32) bool {
        // Title bar is 28 pixels above window body
        return (mx >= self.x and mx < self.x + self.width and
            my >= self.y - 28 and my < self.y + self.height);
    }

    pub fn isCloseButtonClicked(self: *Window, mx: u32, my: u32) bool {
        const close_x = self.x + self.width - 24;
        const close_y = self.y - 22; // title_height - 6
        return (mx >= close_x and mx < close_x + 16 and
            my >= close_y and my < close_y + 16);
    }
};

pub const DesktopIcon = struct {
    label: []const u8,
    x: u32,
    y: u32,
    app_type: WindowType,

    pub fn draw(self: *DesktopIcon, gfx: *Graphics) void {
        // Draw actual icon from converted image data
        switch (self.app_type) {
            .Calculator => {
                const icon = @import("../assets/icons/apps/calculator_icon.zig");
                gfx.drawSprite(@intCast(self.x), @intCast(self.y), 64, 64, icon.getPixel);
            },
            .Editor => {
                const icon = @import("../assets/icons/apps/editor_icon.zig");
                gfx.drawSprite(@intCast(self.x), @intCast(self.y), 64, 64, icon.getPixel);
            },
            .FileManager => {
                const icon = @import("../assets/icons/apps/files_icon.zig");
                gfx.drawSprite(@intCast(self.x), @intCast(self.y), 64, 64, icon.getPixel);
            },
            .Settings => {
                const icon = @import("../assets/icons/apps/settings_icon.zig");
                gfx.drawSprite(@intCast(self.x), @intCast(self.y), 64, 64, icon.getPixel);
            },
            .About => {
                const icon = @import("../assets/icons/apps/about_icon.zig");
                gfx.drawSprite(@intCast(self.x), @intCast(self.y), 64, 64, icon.getPixel);
            },
            else => {
                // Fallback: simple colored square
                gfx.drawRect(self.x + 8, self.y + 8, 48, 48, Color.NanoBlue);
            },
        }

        // Label with shadow
        gfx.drawString(self.x + 1, self.y + 68, self.label, Color.Black, null); // Shadow
        gfx.drawString(self.x, self.y + 67, self.label, Color.White, null);
    }

    pub fn contains(self: *DesktopIcon, mx: u32, my: u32) bool {
        return (mx >= self.x and mx < self.x + 64 and
            my >= self.y and my < self.y + 80); // 64px icon + label
    }
};

pub const Desktop = struct {
    width: u32,
    height: u32,
    windows: [10]?Window,
    active_window_index: ?usize,
    icons: [6]DesktopIcon,
    mouse_x: u32,
    mouse_y: u32,

    // Dragging
    dragged_icon_index: ?usize = null,
    drag_offset_x: u32 = 0,
    drag_offset_y: u32 = 0,

    // System Info
    current_time_str: [8]u8 = "12:00   ".*,

    // Double click detection
    last_click_time: u64 = 0, // Placeholder, we need a timer source

    pub fn init(w: u32, h: u32) Desktop {
        return Desktop{
            .width = w,
            .height = h,
            .windows = .{null} ** 10,
            .active_window_index = null,
            .mouse_x = w / 2,
            .mouse_y = h / 2,
            .icons = .{
                DesktopIcon{ .label = "Terminal", .x = 20, .y = 30, .app_type = .Terminal },
                DesktopIcon{ .label = "Files", .x = 20, .y = 120, .app_type = .FileManager },
                DesktopIcon{ .label = "Calc", .x = 20, .y = 210, .app_type = .Calculator },
                DesktopIcon{ .label = "Editor", .x = 20, .y = 300, .app_type = .Editor },
                DesktopIcon{ .label = "Settings", .x = 20, .y = 390, .app_type = .Settings },
                DesktopIcon{ .label = "About", .x = 20, .y = 480, .app_type = .About },
            },
            .current_time_str = "12:00   ".*,
        };
    }

    pub fn addWindow(self: *Desktop, win_type: WindowType, title: []const u8) !void {
        for (0..self.windows.len) |i| {
            if (self.windows[i] == null) {
                var win = Window{
                    .id = @intCast(i),
                    .type = win_type,
                    .x = 100 + (@as(u32, @intCast(i)) * 30),
                    .y = 100 + (@as(u32, @intCast(i)) * 30),
                    .width = 400,
                    .height = 300,
                    .title = title,
                    .active = true,
                };

                if (win_type == .Terminal) {
                    win.width = 600;
                    win.height = 400;
                    win.terminal_state = Terminal.init(win.x, win.y, win.width, win.height);
                } else if (win_type == .FileManager) {
                    win.width = 500;
                    win.height = 300;
                    win.file_manager_state = FileManager.init(win.x, win.y, win.width, win.height);
                } else if (win_type == .Calculator) {
                    win.width = 300;
                    win.height = 400;
                    win.calculator_state = Calculator.init(win.x, win.y, win.width, win.height);
                } else if (win_type == .Editor) {
                    win.width = 600;
                    win.height = 500;
                    win.editor_state = Editor.init(win.x, win.y, win.width, win.height);
                } else if (win_type == .Settings) {
                    win.width = 600;
                    win.height = 450;
                    win.settings_state = Settings.init(win.x, win.y, win.width, win.height);
                }

                if (self.active_window_index) |idx| {
                    if (self.windows[idx]) |*w| w.active = false;
                }

                self.windows[i] = win;
                self.active_window_index = i;
                return;
            }
        }
        return error.TooManyWindows;
    }

    pub fn draw(self: *Desktop, gfx: *Graphics) void {
        gfx.drawWallpaper();

        // Draw Icons
        for (&self.icons) |*icon| {
            icon.draw(gfx);
        }

        // Modern Taskbar
        const tb_height: u32 = 48;
        const tb_y = self.height - tb_height;

        // Taskbar background (dark with transparency effect)
        gfx.drawGlassRect(0, tb_y, self.width, tb_height, Color.DarkBackground);
        // Top border highlight
        gfx.drawRect(0, tb_y, self.width, 1, Color.DarkBorder);

        // Start Button (Modern rounded)
        const start_btn_x: u32 = 8;
        const start_btn_y = tb_y + 8;
        const start_btn_w: u32 = 90;
        const start_btn_h: u32 = 32;
        gfx.drawRoundedRectSlow(start_btn_x, start_btn_y, start_btn_w, start_btn_h, 6, Color.ButtonPrimary);
        gfx.drawString(start_btn_x + 20, start_btn_y + 10, "NanoOS", Color.White, Color.ButtonPrimary);

        // System Tray area (right side)
        const tray_width: u32 = 120;
        const tray_x = self.width - tray_width - 10;
        gfx.drawRoundedRectSlow(tray_x, start_btn_y, tray_width, start_btn_h, 6, Color.DarkSurface);

        // Clock placeholder
        gfx.drawString(tray_x + 30, start_btn_y + 10, &self.current_time_str, Color.DarkText, Color.DarkSurface);

        // Draw Taskbar Items (Open Windows)
        var tb_x: u32 = 110;
        for (&self.windows) |*w_opt| {
            if (w_opt.*) |*w| {
                const item_bg = if (w.active) Color.Selected else Color.DarkSurfaceLight;
                // Rounded taskbar items
                gfx.drawRoundedRectSlow(tb_x, start_btn_y, 110, start_btn_h, 6, item_bg);
                // Active indicator line
                if (w.active) {
                    gfx.drawRect(tb_x + 30, start_btn_y + start_btn_h - 3, 50, 2, Color.NanoAccent);
                }
                gfx.drawString(tb_x + 10, start_btn_y + 10, w.title, Color.White, item_bg);
                tb_x += 120;
            }
        }

        // Draw Windows (back to front)
        for (&self.windows) |*w_opt| {
            if (w_opt.*) |*w| {
                if (!w.active) w.draw(gfx);
            }
        }

        if (self.active_window_index) |idx| {
            if (self.windows[idx]) |*w| {
                w.draw(gfx);
            }
        }

        // Mouse Cursor (always on top)
        self.drawCursor(gfx);
    }

    fn drawCursor(self: *Desktop, gfx: *Graphics) void {
        const x = self.mouse_x;
        const y = self.mouse_y;

        const cursor_icon = @import("../assets/icons/system/cursor_icon.zig");
        gfx.drawSprite(@intCast(x), @intCast(y), cursor_icon.DIRECT_SELECTION_WIDTH, cursor_icon.DIRECT_SELECTION_HEIGHT, cursor_icon.getPixel);
    }
    fn drawLine(self: *Desktop, gfx: *Graphics, x1: u32, y1: u32, x2: u32, y2: u32, color: Color) void {
        _ = self;
        // Simple Bresenham line
        const dx = if (x2 > x1) x2 - x1 else x1 - x2;
        const dy = if (y2 > y1) y2 - y1 else y1 - y2;
        const sx: i32 = if (x1 < x2) 1 else -1;
        const sy: i32 = if (y1 < y2) 1 else -1;
        var err: i32 = @as(i32, @intCast(dx)) - @as(i32, @intCast(dy));

        var cx: i32 = @intCast(x1);
        var cy: i32 = @intCast(y1);
        const ex: i32 = @intCast(x2);
        const ey: i32 = @intCast(y2);

        while (true) {
            gfx.fb.putPixel(@intCast(cx), @intCast(cy), color);
            if (cx == ex and cy == ey) break;
            const e2 = 2 * err;
            if (e2 > -@as(i32, @intCast(dy))) {
                err -= @as(i32, @intCast(dy));
                cx += sx;
            }
            if (e2 < @as(i32, @intCast(dx))) {
                err += @as(i32, @intCast(dx));
                cy += sy;
            }
        }
    }

    pub fn updateMouse(self: *Desktop, gfx: *Graphics, dx: i32, dy: i32) void {
        var new_x = @as(i32, @intCast(self.mouse_x)) + dx;
        var new_y = @as(i32, @intCast(self.mouse_y)) + dy;

        if (new_x < 0) new_x = 0;
        if (new_y < 0) new_y = 0;
        if (new_x >= self.width) new_x = @intCast(self.width - 1);
        if (new_y >= self.height) new_y = @intCast(self.height - 1);

        self.mouse_x = @intCast(new_x);
        self.mouse_y = @intCast(new_y);

        // Handle dragging
        if (self.dragged_icon_index) |idx| {
            self.icons[idx].x = self.mouse_x - self.drag_offset_x;
            self.icons[idx].y = self.mouse_y - self.drag_offset_y;
        }

        self.draw(gfx);
    }

    pub fn handleMouseRelease(self: *Desktop, gfx: *Graphics) void {
        self.dragged_icon_index = null;
        self.draw(gfx);
    }

    pub fn handleMouseClick(self: *Desktop, gfx: *Graphics, left: bool) void {
        if (left) {
            // Check active window's close button first
            if (self.active_window_index) |idx| {
                if (self.windows[idx]) |*w| {
                    if (w.isCloseButtonClicked(self.mouse_x, self.mouse_y)) {
                        // Close the window
                        self.windows[idx] = null;
                        self.active_window_index = null;
                        // Find next window to activate
                        for (0..self.windows.len) |i| {
                            if (self.windows[i] != null) {
                                self.active_window_index = i;
                                if (self.windows[i]) |*next_w| {
                                    next_w.active = true;
                                }
                                break;
                            }
                        }
                        self.draw(gfx);
                        return;
                    }
                    if (w.contains(self.mouse_x, self.mouse_y)) {
                        return; // Clicked active window (not close button)
                    }
                }
            }

            // Check other windows
            for (0..self.windows.len) |i| {
                if (self.windows[i]) |*w| {
                    if (w.contains(self.mouse_x, self.mouse_y)) {
                        // Bring to front
                        if (self.active_window_index) |old_idx| {
                            if (self.windows[old_idx]) |*old_w| old_w.active = false;
                        }
                        w.active = true;
                        self.active_window_index = i;
                        self.draw(gfx);
                        return;
                    }
                }
            }

            // Check Icons
            for (&self.icons) |*icon| {
                if (icon.contains(self.mouse_x, self.mouse_y)) {
                    // Launch App
                    self.addWindow(icon.app_type, icon.label) catch {};
                    self.draw(gfx);
                    return;
                }
            }
        }
    }

    pub const SystemAction = enum {
        None,
        Shutdown,
        Reboot,
    };

    pub fn handleInput(self: *Desktop, gfx: *Graphics, char: u16) SystemAction {
        // Handle Escape key to close active window
        if (char == 27) { // ESC
            if (self.active_window_index) |idx| {
                self.windows[idx] = null;
                self.active_window_index = null;
                // Find next window to activate
                for (0..self.windows.len) |i| {
                    if (self.windows[i] != null) {
                        self.active_window_index = i;
                        if (self.windows[i]) |*next_w| {
                            next_w.active = true;
                        }
                        break;
                    }
                }
                self.draw(gfx);
            }
            return .None;
        }

        if (self.active_window_index) |idx| {
            if (self.windows[idx]) |*w| {
                if (w.type == .Terminal) {
                    if (w.terminal_state) |*term| {
                        const action = term.handleInput(gfx, char);
                        switch (action) {
                            .Shutdown => return .Shutdown,
                            .Reboot => return .Reboot,
                            .OpenAbout => {
                                self.addWindow(.About, "About NanoOS") catch {};
                                self.draw(gfx);
                            },
                            .OpenColors => {
                                self.addWindow(.ColorTest, "Color Test") catch {};
                                self.draw(gfx);
                            },
                            .OpenCalc => {
                                self.addWindow(.Calculator, "Calculator") catch {};
                                self.draw(gfx);
                            },
                            .OpenEditor => {
                                self.addWindow(.Editor, "Editor") catch {};
                                self.draw(gfx);
                            },
                            .OpenFiles => {
                                self.addWindow(.FileManager, "Files") catch {};
                                self.draw(gfx);
                            },
                            .OpenSettings => {
                                self.addWindow(.Settings, "Settings") catch {};
                                self.draw(gfx);
                            },
                            .Clear => {},
                            .None => {},
                        }
                    }
                } else if (w.type == .FileManager) {
                    if (w.file_manager_state) |*fm| {
                        _ = fm.handleInput(gfx, char);
                        self.draw(gfx);
                    }
                } else if (w.type == .Calculator) {
                    if (w.calculator_state) |*calc| {
                        calc.handleInput(char);
                        self.draw(gfx);
                    }
                } else if (w.type == .Editor) {
                    if (w.editor_state) |*ed| {
                        ed.handleInput(char);
                        self.draw(gfx);
                    }
                } else if (w.type == .Settings) {
                    if (w.settings_state) |*settings| {
                        if (settings.handleInput(char)) |action| {
                            switch (action) {
                                .Shutdown => return .Shutdown,
                                .Restart => return .Reboot,
                                .Sleep => {
                                    // For now, just redraw
                                    self.draw(gfx);
                                },
                                .None => {},
                            }
                        }
                        self.draw(gfx);
                    }
                }
            }
        }
        return .None;
    }
};
