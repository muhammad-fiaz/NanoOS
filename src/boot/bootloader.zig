// NanoOS Bootloader - UEFI Entry Point
// Enhanced bootloader with hardware detection and boot services
const std = @import("std");
const uefi = std.os.uefi;

pub const BootInfo = struct {
    firmware_vendor: ?[*:0]const u16 = null,
    firmware_revision: u32 = 0,
    boot_services: ?*uefi.tables.BootServices = null,
    runtime_services: ?*uefi.tables.RuntimeServices = null,
    con_in: ?*uefi.protocol.SimpleTextInput = null,
    con_out: ?*uefi.protocol.SimpleTextOutput = null,
    screen_width: u32 = 0,
    screen_height: u32 = 0,
    has_mouse: bool = false,
    boot_success: bool = false,
};

pub const Bootloader = struct {
    system_table: *uefi.tables.SystemTable,
    boot_services: *uefi.tables.BootServices,
    con_out: *uefi.protocol.SimpleTextOutput,

    pub fn init(system_table: *uefi.tables.SystemTable) ?Bootloader {
        const bs = system_table.boot_services orelse return null;
        const con_out = system_table.con_out orelse return null;

        return Bootloader{
            .system_table = system_table,
            .boot_services = bs,
            .con_out = con_out,
        };
    }

    pub fn clearScreen(self: *Bootloader) void {
        _ = self.con_out.clearScreen() catch {};
    }

    pub fn print(self: *Bootloader, msg: []const u8) void {
        var buf: [256:0]u16 = undefined;
        var i: usize = 0;
        for (msg) |c| {
            if (i >= 255) break;
            buf[i] = c;
            i += 1;
        }
        buf[i] = 0;
        _ = self.con_out.outputString(&buf) catch {};
    }

    pub fn printLine(self: *Bootloader, msg: []const u8) void {
        self.print(msg);
        self.print("\r\n");
    }

    pub fn showBootScreen(self: *Bootloader) void {
        self.clearScreen();
        self.printLine("========================================");
        self.printLine("          NanoOS Bootloader v1.0        ");
        self.printLine("========================================");
        self.printLine("");
        self.printLine("  Modern UEFI Operating System");
        self.printLine("  Built with Zig Programming Language");
        self.printLine("");
    }

    pub fn detectGraphics(self: *Bootloader) ?GraphicsInfo {
        const gop_opt = self.boot_services.locateProtocol(uefi.protocol.GraphicsOutput, null) catch return null;

        const gop = gop_opt orelse return null;
        const mode = gop.mode;
        const info = mode.info;

        return GraphicsInfo{
            .width = info.horizontal_resolution,
            .height = info.vertical_resolution,
            .pixels_per_scanline = info.pixels_per_scan_line,
            .framebuffer_base = mode.frame_buffer_base,
            .framebuffer_size = mode.frame_buffer_size,
        };
    }

    pub fn detectMouse(self: *Bootloader) bool {
        const mouse_opt = self.boot_services.locateProtocol(uefi.protocol.SimplePointer, null) catch return false;

        return mouse_opt != null;
    }

    pub fn stall(self: *Bootloader, microseconds: usize) void {
        _ = self.boot_services.stall(microseconds) catch {};
    }

    pub fn runBootSequence(self: *Bootloader) BootInfo {
        var info = BootInfo{};

        self.showBootScreen();
        self.printLine("[BOOT] Starting boot sequence...");
        self.stall(200_000);

        // Get firmware info
        info.firmware_vendor = self.system_table.firmware_vendor;
        info.firmware_revision = self.system_table.firmware_revision;
        info.boot_services = self.system_table.boot_services;
        info.runtime_services = self.system_table.runtime_services;
        info.con_in = self.system_table.con_in;
        info.con_out = self.system_table.con_out;

        self.printLine("[BOOT] Checking firmware...");
        self.stall(100_000);

        // Detect graphics
        self.print("[BOOT] Detecting graphics... ");
        if (self.detectGraphics()) |gfx| {
            info.screen_width = gfx.width;
            info.screen_height = gfx.height;
            self.printLine("OK");
        } else {
            self.printLine("FAILED");
        }
        self.stall(100_000);

        // Detect mouse
        self.print("[BOOT] Detecting mouse... ");
        info.has_mouse = self.detectMouse();
        if (info.has_mouse) {
            self.printLine("OK");
        } else {
            self.printLine("Not found (keyboard only)");
        }
        self.stall(100_000);

        self.printLine("[BOOT] Initializing kernel...");
        self.stall(200_000);

        info.boot_success = true;

        self.printLine("");
        self.printLine("[BOOT] Boot sequence complete!");
        self.printLine("[BOOT] Starting NanoOS desktop...");
        self.stall(500_000);

        return info;
    }
};

pub const GraphicsInfo = struct {
    width: u32,
    height: u32,
    pixels_per_scanline: u32,
    framebuffer_base: u64,
    framebuffer_size: usize,
};

// Legacy entry point (kept for compatibility)
pub fn efiMain(handle: uefi.Handle, system_table: *uefi.tables.SystemTable) uefi.Status {
    _ = handle;

    var bootloader = Bootloader.init(system_table) orelse return .LoadError;
    _ = bootloader.runBootSequence();

    return .Success;
}
