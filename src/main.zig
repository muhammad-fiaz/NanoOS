// NanoOS Main Entry Point
// Clean architecture using Kernel and Bootloader modules
const std = @import("std");
const uefi = std.os.uefi;

// Kernel and system modules
const Kernel = @import("kernel/kernel.zig").Kernel;
const Bootloader = @import("boot/bootloader.zig").Bootloader;

// Hardware abstraction
const FrameBuffer = @import("hal/framebuffer.zig").FrameBuffer;
const Color = @import("hal/framebuffer.zig").Color;
const Mouse = @import("hal/mouse.zig").Mouse;
const MouseState = @import("hal/mouse.zig").MouseState;

// GUI components
const Graphics = @import("gui/graphics.zig").Graphics;
const Desktop = @import("gui/desktop.zig").Desktop;

pub fn main() void {
    // =========================================
    // Phase 1: UEFI Initialization
    // =========================================
    const system_table = uefi.system_table;
    const boot_services = system_table.boot_services orelse return;
    const runtime_services = system_table.runtime_services;
    const con_out = system_table.con_out orelse return;
    const con_in = system_table.con_in orelse return;

    // =========================================
    // Phase 2: Bootloader Sequence
    // =========================================
    var bootloader = Bootloader.init(system_table) orelse {
        // Fallback: simple message
        _ = con_out.outputString(&[_:0]u16{ 'B', 'o', 'o', 't', ' ', 'E', 'r', 'r', 'o', 'r', 0 }) catch {};
        return;
    };

    const boot_info = bootloader.runBootSequence();
    if (!boot_info.boot_success) {
        bootloader.printLine("[ERROR] Boot failed!");
        return;
    }

    // =========================================
    // Phase 3: Kernel Initialization
    // =========================================
    var kernel = Kernel.init(boot_services, runtime_services, con_in, con_out);

    // =========================================
    // Phase 4: Graphics Initialization
    // =========================================
    var fb = FrameBuffer.init(boot_services) catch {
        kernel.printBootMessage("ERROR: Failed to initialize graphics\r\n");
        kernel.sleep(3000);
        return;
    };

    var gfx = Graphics.init(&fb);
    gfx.clear(Color.Black);

    // =========================================
    // Phase 5: Loading Screen
    // =========================================
    drawLoadingScreen(&gfx, &kernel);

    // =========================================
    // Phase 6: Desktop Environment Setup
    // =========================================
    var desktop = Desktop.init(fb.width, fb.height);

    // Open welcome terminal
    desktop.addWindow(.Terminal, "Terminal") catch {};

    // =========================================
    // Phase 7: Mouse Initialization
    // =========================================
    var mouse_opt: ?Mouse = null;
    if (Mouse.init(boot_services)) |m| {
        mouse_opt = m;
    } else |_| {
        // Continue without mouse (keyboard only mode)
    }

    // Initial desktop render
    desktop.draw(&gfx);

    // =========================================
    // Phase 8: Main Event Loop
    // =========================================
    var prev_left_button = false;

    while (kernel.is_running) {
        // Update system time/uptime
        kernel.updateUptime();

        // Update desktop time
        var time_buf: [8]u8 = undefined;
        const time_str = kernel.getFormattedTime(&time_buf);
        if (time_str.len >= 5) {
            @memcpy(desktop.current_time_str[0..5], time_str[0..5]);
        }

        // Setup events to wait for
        var events: [2]uefi.Event = undefined;
        var event_count: usize = 1;
        events[0] = con_in.wait_for_key;

        if (mouse_opt) |*m| {
            events[1] = m.protocol.wait_for_input;
            event_count = 2;
        }

        // Wait for any input event
        _ = boot_services.waitForEvent(events[0..event_count]) catch continue;

        // ---- Handle Keyboard Input ----
        if (kernel.pollKeyboard()) |key| {
            const action = desktop.handleInput(&gfx, key.unicode_char);
            switch (action) {
                .Shutdown => {
                    drawShutdownScreen(&gfx, &kernel);
                    kernel.shutdown();
                },
                .Reboot => {
                    drawRestartScreen(&gfx, &kernel);
                    kernel.restart();
                },
                .None => {},
            }
            desktop.draw(&gfx);
        }

        // ---- Handle Mouse Input ----
        if (mouse_opt) |*m| {
            const state = m.poll() catch MouseState{ .x = 0, .y = 0, .left_button = false, .right_button = false };

            // Update mouse position
            if (state.x != 0 or state.y != 0) {
                desktop.updateMouse(&gfx, state.x, state.y);
            }

            // Handle clicks
            if (state.left_button and !prev_left_button) {
                desktop.handleMouseClick(&gfx, true);
            } else if (!state.left_button and prev_left_button) {
                desktop.handleMouseRelease(&gfx);
            }

            prev_left_button = state.left_button;
        }
    }
}

// =========================================
// Boot/Loading Screen Functions
// =========================================

fn drawLoadingScreen(gfx: *Graphics, kernel: *Kernel) void {
    const cx = gfx.fb.width / 2;
    const cy = gfx.fb.height / 2;

    // Dark background with gradient effect
    gfx.drawGradientBackground();

    // Logo
    // Logo
    const logo_img = @import("assets/icons/system/nano_logo.zig");
    const logo_w = 64;
    const logo_h = 64;
    const logo_x_img = cx - (logo_w / 2);
    const logo_y_img = cy - 100;

    gfx.drawSprite(@intCast(logo_x_img), @intCast(logo_y_img), logo_w, logo_h, struct {
        pub fn getPixel(x: u32, y: u32) Color {
            return logo_img.getScaledPixel(x, y, 64, 64);
        }
    }.getPixel);

    const logo = "NanoOS";
    const logo_x = cx - (@as(u32, @intCast(logo.len)) * 4);
    gfx.drawString(logo_x, cy - 20, logo, Color.White, null);

    // Version
    const version = "Version 0.0.0";
    const ver_x = cx - (@as(u32, @intCast(version.len)) * 4);
    gfx.drawString(ver_x, cy - 40, version, Color.Cyan, null);

    // Progress bar background
    const bar_width: u32 = 300;
    const bar_height: u32 = 12;
    const bar_x = cx - (bar_width / 2);
    const bar_y = cy + 20;

    gfx.drawRoundedRectSlow(bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4, 6, Color.DarkGray);
    gfx.drawRoundedRectSlow(bar_x, bar_y, bar_width, bar_height, 4, Color{ .r = 30, .g = 30, .b = 30, .a = 255 });

    // Animated progress bar
    const steps: u32 = 60;
    var i: u32 = 0;
    while (i < steps) : (i += 1) {
        const progress = (i * bar_width) / steps;

        // Blue gradient fill
        const blue_intensity = @as(u8, @intCast(100 + (i * 155 / steps)));
        const fill_color = Color{ .r = 30, .g = 100, .b = blue_intensity, .a = 255 };

        gfx.drawRoundedRectSlow(bar_x, bar_y, progress, bar_height, 4, fill_color);

        // Loading text
        const loading_texts = [_][]const u8{
            "Loading kernel...",
            "Initializing hardware...",
            "Starting services...",
            "Preparing desktop...",
        };
        const text_idx = (i * 4) / steps;
        const loading_text = loading_texts[@min(text_idx, 3)];
        const text_x = cx - (@as(u32, @intCast(loading_text.len)) * 4);

        gfx.drawRect(text_x - 10, bar_y + 25, 200, 12, Color.Black);
        gfx.drawString(text_x, bar_y + 25, loading_text, Color.Gray, null);

        kernel.sleep(30);
    }

    // Final message
    gfx.drawString(cx - 60, bar_y + 50, "Welcome!", Color.Green, null);
    kernel.sleep(500);
}

fn drawShutdownScreen(gfx: *Graphics, kernel: *Kernel) void {
    gfx.clear(Color.Black);

    const cx = gfx.fb.width / 2;
    const cy = gfx.fb.height / 2;

    gfx.drawString(cx - 80, cy - 20, "Shutting down...", Color.White, Color.Black);
    gfx.drawString(cx - 100, cy + 10, "Please wait", Color.Gray, Color.Black);

    // Simple animation
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        gfx.drawRect(cx - 30 + (i * 20), cy + 40, 10, 10, Color.NanoBlue);
        kernel.sleep(200);
    }
}

fn drawRestartScreen(gfx: *Graphics, kernel: *Kernel) void {
    gfx.clear(Color.Black);

    const cx = gfx.fb.width / 2;
    const cy = gfx.fb.height / 2;

    gfx.drawString(cx - 70, cy - 20, "Restarting...", Color.White, Color.Black);
    gfx.drawString(cx - 100, cy + 10, "Please wait", Color.Gray, Color.Black);

    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        gfx.drawRect(cx - 30 + (i * 20), cy + 40, 10, 10, Color{ .r = 255, .g = 160, .b = 0, .a = 255 });
        kernel.sleep(200);
    }
}
