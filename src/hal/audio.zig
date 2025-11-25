const std = @import("std");
const uefi = std.os.uefi;

pub const Audio = struct {
    pub fn init(boot_services: *uefi.tables.BootServices) !Audio {
        _ = boot_services;
        // UEFI Audio IO Protocol is not standard in all firmwares.
        // We return an error to indicate no audio, or we could implement a beep.
        // For now, just a stub.
        return error.NoAudioHardware;
    }

    pub fn beep(self: *Audio) void {
        _ = self;
    }
};
