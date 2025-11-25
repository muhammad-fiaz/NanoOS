const std = @import("std");
const uefi = std.os.uefi;

pub const MouseState = struct {
    x: i32,
    y: i32,
    left_button: bool,
    right_button: bool,
};

pub const Mouse = struct {
    protocol: *uefi.protocol.SimplePointer,
    state: MouseState,

    pub fn init(boot_services: *uefi.tables.BootServices) !Mouse {

        // Try to locate the protocol
        // Note: In Zig 0.15 dev, locateProtocol might return the pointer directly or via void*
        // We'll use the generic version if available or the void* one.
        // Based on previous errors, locateProtocol returns a wrapper or we use the void* one.
        // Let's try the void* approach which is safer across versions if we cast.

        const ptr_proto_opt = boot_services.locateProtocol(uefi.protocol.SimplePointer, null) catch return error.MouseNotFound;
        const ptr_proto = ptr_proto_opt orelse return error.MouseNotFound;

        const mouse = Mouse{
            .protocol = ptr_proto,
            .state = MouseState{ .x = 0, .y = 0, .left_button = false, .right_button = false },
        };

        // Reset device
        _ = mouse.protocol.reset(true) catch {};

        return mouse;
    }

    pub fn poll(self: *Mouse) !MouseState {
        const state = self.protocol.getState() catch return MouseState{ .x = 0, .y = 0, .left_button = false, .right_button = false };
        if (true) { // Success implicit
            const dx = @as(i32, @intCast(state.relative_movement_x));
            const dy = @as(i32, @intCast(state.relative_movement_y));
            self.state.x += dx;
            self.state.y += dy;
            self.state.left_button = state.left_button;
            self.state.right_button = state.right_button;

            return MouseState{ .x = dx, .y = dy, .left_button = state.left_button, .right_button = state.right_button };
        }
        return MouseState{ .x = 0, .y = 0, .left_button = false, .right_button = false };
    }
};
