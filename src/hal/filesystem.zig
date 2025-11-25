const std = @import("std");
const uefi = std.os.uefi;

pub const FileEntry = struct {
    name: [256]u8,
    size: u64,
    is_directory: bool,
};

pub const FileSystem = struct {
    root: *uefi.protocol.File,

    pub fn init(boot_services: *uefi.tables.BootServices) !FileSystem {
        const fs_opt = boot_services.locateProtocol(uefi.protocol.SimpleFileSystem, null) catch return error.FSNotFound;
        const fs = fs_opt orelse return error.FSNotFound;

        var root: *uefi.protocol.File = undefined;
        const status = fs.openVolume(&root);
        if (status != .Success) return error.OpenVolumeFailed;

        return FileSystem{ .root = root };
    }

    // A simple iterator would be nice, but for now just a list function
    // We'll pass a buffer to fill
    pub fn listDir(self: *FileSystem, dir_path: []const u8, out_entries: []FileEntry) !usize {
        _ = self;
        _ = dir_path;
        _ = out_entries;
        // Implementing full directory traversal is complex in UEFI (Open, Read loop, Close)
        // For MVP, we'll just return 0 entries or implement root listing later.
        return 0;
    }
};
