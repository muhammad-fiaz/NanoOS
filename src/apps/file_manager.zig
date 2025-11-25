const std = @import("std");
const Graphics = @import("../gui/graphics.zig").Graphics;
const Color = @import("../hal/framebuffer.zig").Color;

// ==================== File Entry Types ====================

pub const FileType = enum {
    Directory,
    TextFile,
    SystemFile,
    Executable,
    Image,
    Archive,
    Unknown,
};

pub const FileEntry = struct {
    name: [64]u8,
    name_len: usize,
    file_type: FileType,
    size_bytes: u64,
    is_hidden: bool,
    is_readonly: bool,

    pub fn getName(self: *const FileEntry) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn create(name: []const u8, file_type: FileType, size: u64) FileEntry {
        var entry = FileEntry{
            .name = undefined,
            .name_len = @min(name.len, 64),
            .file_type = file_type,
            .size_bytes = size,
            .is_hidden = false,
            .is_readonly = false,
        };
        @memcpy(entry.name[0..entry.name_len], name[0..entry.name_len]);
        return entry;
    }
};

// ==================== File Manager Actions ====================

pub const FileAction = enum {
    None,
    OpenFile,
    OpenDirectory,
    CreateFile,
    CreateFolder,
    Delete,
    Rename,
    ViewRecycleBin,
    RestoreFromBin,
    EmptyRecycleBin,
    Refresh,
    GoUp,
    CopyFile,
    CutFile,
    PasteFile,
};

// ==================== Main File Manager ====================

pub const FileManager = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,

    // Current directory state
    current_path: [256]u8 = undefined,
    path_len: usize = 0,

    // File list
    files: [32]FileEntry = undefined,
    file_count: usize = 0,
    selected_index: usize = 0,
    scroll_offset: usize = 0,
    max_visible: usize = 12,

    // Recycle bin
    recycle_bin: [16]FileEntry = undefined,
    recycle_count: usize = 0,

    // Operation mode
    mode: FileManagerMode = .Browse,
    input_buffer: [64]u8 = undefined,
    input_len: usize = 0,

    // Clipboard
    clipboard: ?FileEntry = null,
    clipboard_cut: bool = false,

    // View settings
    show_hidden: bool = false,
    show_details: bool = true,

    pub const FileManagerMode = enum {
        Browse,
        CreateFile,
        CreateFolder,
        Rename,
        Delete,
        RecycleBin,
    };

    pub fn init(x: u32, y: u32, w: u32, h: u32) FileManager {
        var fm = FileManager{
            .x = x,
            .y = y,
            .width = w,
            .height = h,
        };

        // Set initial path
        const home_path = "/home/user/";
        @memcpy(fm.current_path[0..home_path.len], home_path);
        fm.path_len = home_path.len;

        // Populate with sample files
        fm.populateSampleFiles();

        return fm;
    }

    fn populateSampleFiles(self: *FileManager) void {
        self.file_count = 0;

        // Parent directory
        self.addFile("..", .Directory, 0);

        // Sample directories
        self.addFile("Documents", .Directory, 0);
        self.addFile("Pictures", .Directory, 0);
        self.addFile("Downloads", .Directory, 0);
        self.addFile("System", .Directory, 0);

        // Sample files
        self.addFile("readme.txt", .TextFile, 1024);
        self.addFile("kernel.zig", .SystemFile, 8192);
        self.addFile("boot.efi", .Executable, 32768);
        self.addFile("config.json", .TextFile, 512);
        self.addFile("wallpaper.bmp", .Image, 2097152);
        self.addFile("notes.txt", .TextFile, 256);
    }

    fn addFile(self: *FileManager, name: []const u8, file_type: FileType, size: u64) void {
        if (self.file_count < self.files.len) {
            self.files[self.file_count] = FileEntry.create(name, file_type, size);
            self.file_count += 1;
        }
    }

    // ==================== Drawing Functions ====================

    pub fn draw(self: *FileManager, gfx: *Graphics) void {
        // Dark background
        gfx.drawRect(self.x, self.y, self.width, self.height, Color{ .r = 25, .g = 25, .b = 30, .a = 255 });

        // Mode-specific drawing
        switch (self.mode) {
            .RecycleBin => self.drawRecycleBin(gfx),
            .CreateFile, .CreateFolder, .Rename => {
                self.drawBrowseMode(gfx);
                self.drawInputDialog(gfx);
            },
            .Delete => {
                self.drawBrowseMode(gfx);
                self.drawDeleteConfirm(gfx);
            },
            .Browse => self.drawBrowseMode(gfx),
        }
    }

    fn drawBrowseMode(self: *FileManager, gfx: *Graphics) void {
        const content_x = self.x + 8;
        var content_y = self.y + 8;

        // Header
        gfx.drawString(content_x, content_y, "File Manager", Color.NanoAccent, Color{ .r = 25, .g = 25, .b = 30, .a = 255 });
        content_y += 16;

        // Current path
        gfx.drawString(content_x, content_y, self.current_path[0..self.path_len], Color.Gray, Color{ .r = 25, .g = 25, .b = 30, .a = 255 });
        content_y += 14;

        // Toolbar
        self.drawToolbar(gfx, content_x, content_y);
        content_y += 18;

        // Separator
        gfx.drawRect(content_x, content_y, self.width - 16, 1, Color.DarkGray);
        content_y += 6;

        // Column headers
        gfx.drawString(content_x + 4, content_y, "Name", Color.Cyan, Color{ .r = 25, .g = 25, .b = 30, .a = 255 });
        if (self.show_details) {
            gfx.drawString(content_x + 160, content_y, "Type", Color.Cyan, Color{ .r = 25, .g = 25, .b = 30, .a = 255 });
            gfx.drawString(content_x + 230, content_y, "Size", Color.Cyan, Color{ .r = 25, .g = 25, .b = 30, .a = 255 });
        }
        content_y += 14;

        // File list
        self.drawFileList(gfx, content_x, content_y);

        // Status bar
        self.drawStatusBar(gfx);
    }

    fn drawToolbar(_: *FileManager, gfx: *Graphics, x: u32, y: u32) void {
        const bg = Color{ .r = 25, .g = 25, .b = 30, .a = 255 };
        const toolbar_items = [_]struct { key: []const u8, color: Color }{
            .{ .key = "[N]ew", .color = Color.White },
            .{ .key = "[F]older", .color = Color.White },
            .{ .key = "[D]el", .color = Color.Error },
            .{ .key = "[R]en", .color = Color.White },
            .{ .key = "[B]in", .color = Color.Warning },
        };
        var tx = x;

        for (toolbar_items) |item| {
            gfx.drawString(tx, y, item.key, item.color, bg);
            tx += @intCast(item.key.len * 8 + 8);
        }
    }

    fn drawFileList(self: *FileManager, gfx: *Graphics, x: u32, start_y: u32) void {
        var y = start_y;
        var visible_count: usize = 0;
        const bg = Color{ .r = 25, .g = 25, .b = 30, .a = 255 };

        var i: usize = self.scroll_offset;
        while (i < self.file_count and visible_count < self.max_visible) : (i += 1) {
            const file = &self.files[i];
            const is_selected = (i == self.selected_index);

            // Selection highlight
            const row_bg = if (is_selected) Color.NanoBlue else bg;
            if (is_selected) {
                gfx.drawRect(x, y - 1, self.width - 18, 13, row_bg);
            }

            // File icon
            const icon = self.getFileIcon(file.file_type);
            const icon_color = self.getFileColor(file.file_type);
            gfx.drawString(x + 4, y, icon, icon_color, row_bg);

            // File name
            gfx.drawString(x + 30, y, file.getName(), Color.White, row_bg);

            // Details
            if (self.show_details) {
                const type_str = self.getTypeString(file.file_type);
                gfx.drawString(x + 160, y, type_str, Color.Gray, row_bg);

                if (file.file_type != .Directory) {
                    var size_buf: [16]u8 = undefined;
                    const size_str = self.formatSize(file.size_bytes, &size_buf);
                    gfx.drawString(x + 230, y, size_str, Color.Gray, row_bg);
                }
            }

            y += 14;
            visible_count += 1;
        }
    }

    fn drawStatusBar(self: *FileManager, gfx: *Graphics) void {
        const status_y = self.y + self.height - 16;
        const bg = Color{ .r = 25, .g = 25, .b = 30, .a = 255 };

        gfx.drawRect(self.x + 8, status_y - 4, self.width - 16, 1, Color.DarkGray);

        var count_buf: [32]u8 = undefined;
        const count_str = std.fmt.bufPrint(&count_buf, "{d} items", .{self.file_count}) catch "? items";
        gfx.drawString(self.x + 10, status_y, count_str, Color.Gray, bg);

        if (self.recycle_count > 0) {
            var bin_buf: [32]u8 = undefined;
            const bin_str = std.fmt.bufPrint(&bin_buf, "Bin:{d}", .{self.recycle_count}) catch "Bin:?";
            gfx.drawString(self.x + 100, status_y, bin_str, Color.Warning, bg);
        }
    }

    fn drawRecycleBin(self: *FileManager, gfx: *Graphics) void {
        const bg = Color{ .r = 30, .g = 25, .b = 25, .a = 255 };
        gfx.drawRect(self.x, self.y, self.width, self.height, bg);

        const content_x = self.x + 8;
        var content_y = self.y + 8;

        gfx.drawString(content_x, content_y, "Recycle Bin", Color.Warning, bg);
        content_y += 16;

        gfx.drawString(content_x, content_y, "[R]estore [E]mpty [ESC]Back", Color.Gray, bg);
        content_y += 18;

        gfx.drawRect(content_x, content_y, self.width - 16, 1, Color.DarkGray);
        content_y += 8;

        if (self.recycle_count == 0) {
            gfx.drawString(content_x, content_y, "Empty", Color.Gray, bg);
        } else {
            var i: usize = 0;
            while (i < self.recycle_count) : (i += 1) {
                const file = &self.recycle_bin[i];
                const is_selected = (i == self.selected_index);
                const row_bg = if (is_selected) Color{ .r = 80, .g = 50, .b = 50, .a = 255 } else bg;

                if (is_selected) {
                    gfx.drawRect(content_x, content_y - 1, self.width - 18, 13, row_bg);
                }

                gfx.drawString(content_x + 4, content_y, file.getName(), Color.Gray, row_bg);
                content_y += 14;
            }
        }
    }

    fn drawInputDialog(self: *FileManager, gfx: *Graphics) void {
        const dialog_w: u32 = 260;
        const dialog_h: u32 = 70;
        const dialog_x = self.x + (self.width - dialog_w) / 2;
        const dialog_y = self.y + (self.height - dialog_h) / 2;

        const bg = Color{ .r = 35, .g = 35, .b = 45, .a = 255 };
        gfx.drawRect(dialog_x, dialog_y, dialog_w, dialog_h, Color{ .r = 60, .g = 60, .b = 70, .a = 255 });
        gfx.drawRect(dialog_x + 2, dialog_y + 2, dialog_w - 4, dialog_h - 4, bg);

        const title = switch (self.mode) {
            .CreateFile => "New File",
            .CreateFolder => "New Folder",
            .Rename => "Rename",
            else => "Input",
        };
        gfx.drawString(dialog_x + 10, dialog_y + 8, title, Color.NanoAccent, bg);

        // Input field
        gfx.drawRect(dialog_x + 10, dialog_y + 26, dialog_w - 20, 18, Color{ .r = 20, .g = 20, .b = 25, .a = 255 });
        gfx.drawString(dialog_x + 14, dialog_y + 30, self.input_buffer[0..self.input_len], Color.White, Color{ .r = 20, .g = 20, .b = 25, .a = 255 });

        gfx.drawString(dialog_x + 10, dialog_y + 50, "[Enter]OK [ESC]Cancel", Color.Gray, bg);
    }

    fn drawDeleteConfirm(self: *FileManager, gfx: *Graphics) void {
        const dialog_w: u32 = 240;
        const dialog_h: u32 = 70;
        const dialog_x = self.x + (self.width - dialog_w) / 2;
        const dialog_y = self.y + (self.height - dialog_h) / 2;

        const bg = Color{ .r = 50, .g = 30, .b = 30, .a = 255 };
        gfx.drawRect(dialog_x, dialog_y, dialog_w, dialog_h, Color.Error);
        gfx.drawRect(dialog_x + 2, dialog_y + 2, dialog_w - 4, dialog_h - 4, bg);

        gfx.drawString(dialog_x + 10, dialog_y + 8, "Delete?", Color.Error, bg);

        if (self.selected_index < self.file_count) {
            const file = &self.files[self.selected_index];
            gfx.drawString(dialog_x + 10, dialog_y + 26, file.getName(), Color.White, bg);
        }

        gfx.drawString(dialog_x + 10, dialog_y + 50, "[Y]es [N]o", Color.Warning, bg);
    }

    // ==================== Helper Functions ====================

    fn getFileIcon(self: *FileManager, file_type: FileType) []const u8 {
        _ = self;
        return switch (file_type) {
            .Directory => "[D]",
            .TextFile => "[T]",
            .SystemFile => "[S]",
            .Executable => "[X]",
            .Image => "[I]",
            .Archive => "[A]",
            .Unknown => "[?]",
        };
    }

    fn getFileColor(self: *FileManager, file_type: FileType) Color {
        _ = self;
        return switch (file_type) {
            .Directory => Color.Cyan,
            .TextFile => Color.White,
            .SystemFile => Color.Warning,
            .Executable => Color.Success,
            .Image => Color.Magenta,
            .Archive => Color{ .r = 200, .g = 150, .b = 100, .a = 255 },
            .Unknown => Color.Gray,
        };
    }

    fn getTypeString(self: *FileManager, file_type: FileType) []const u8 {
        _ = self;
        return switch (file_type) {
            .Directory => "Folder",
            .TextFile => "Text",
            .SystemFile => "System",
            .Executable => "Exec",
            .Image => "Image",
            .Archive => "Archive",
            .Unknown => "?",
        };
    }

    fn formatSize(self: *FileManager, size: u64, buffer: []u8) []const u8 {
        _ = self;
        if (size < 1024) {
            return std.fmt.bufPrint(buffer, "{d}B", .{size}) catch "?";
        } else if (size < 1024 * 1024) {
            return std.fmt.bufPrint(buffer, "{d}KB", .{size / 1024}) catch "?";
        } else {
            return std.fmt.bufPrint(buffer, "{d}MB", .{size / (1024 * 1024)}) catch "?";
        }
    }

    // ==================== Input Handling ====================

    pub fn handleInput(self: *FileManager, gfx: *Graphics, char: u16) FileAction {
        _ = gfx;

        switch (self.mode) {
            .CreateFile, .CreateFolder, .Rename => return self.handleInputMode(char),
            .Delete => return self.handleDeleteMode(char),
            .RecycleBin => return self.handleRecycleBinMode(char),
            .Browse => return self.handleBrowseMode(char),
        }
    }

    fn handleBrowseMode(self: *FileManager, char: u16) FileAction {
        if (char == 0) return .None;

        switch (char) {
            'w', 'W' => {
                if (self.selected_index > 0) {
                    self.selected_index -= 1;
                    if (self.selected_index < self.scroll_offset) {
                        self.scroll_offset = self.selected_index;
                    }
                }
            },
            's', 'S' => {
                if (self.selected_index < self.file_count -| 1) {
                    self.selected_index += 1;
                    if (self.selected_index >= self.scroll_offset + self.max_visible) {
                        self.scroll_offset += 1;
                    }
                }
            },
            '\r' => {
                if (self.selected_index < self.file_count) {
                    const file = &self.files[self.selected_index];
                    if (file.file_type == .Directory) {
                        return .OpenDirectory;
                    }
                    return .OpenFile;
                }
            },
            'n', 'N' => {
                self.mode = .CreateFile;
                self.input_len = 0;
                return .CreateFile;
            },
            'f', 'F' => {
                self.mode = .CreateFolder;
                self.input_len = 0;
                return .CreateFolder;
            },
            'd', 'D' => {
                if (self.selected_index > 0 and self.selected_index < self.file_count) {
                    self.mode = .Delete;
                    return .Delete;
                }
            },
            'r', 'R' => {
                if (self.selected_index > 0 and self.selected_index < self.file_count) {
                    self.mode = .Rename;
                    const file = &self.files[self.selected_index];
                    const name = file.getName();
                    @memcpy(self.input_buffer[0..name.len], name);
                    self.input_len = name.len;
                    return .Rename;
                }
            },
            'b', 'B' => {
                self.mode = .RecycleBin;
                self.selected_index = 0;
                return .ViewRecycleBin;
            },
            else => {},
        }
        return .None;
    }

    fn handleInputMode(self: *FileManager, char: u16) FileAction {
        switch (char) {
            27 => {
                self.mode = .Browse;
                self.input_len = 0;
            },
            '\r' => {
                if (self.input_len > 0) {
                    const name = self.input_buffer[0..self.input_len];

                    switch (self.mode) {
                        .CreateFile => self.createFile(name, .TextFile),
                        .CreateFolder => self.createFile(name, .Directory),
                        .Rename => self.renameSelected(name),
                        else => {},
                    }

                    self.mode = .Browse;
                    self.input_len = 0;
                }
            },
            8 => {
                if (self.input_len > 0) self.input_len -= 1;
            },
            else => {
                if (char >= 32 and char < 127 and self.input_len < 63) {
                    self.input_buffer[self.input_len] = @intCast(char);
                    self.input_len += 1;
                }
            },
        }
        return .None;
    }

    fn handleDeleteMode(self: *FileManager, char: u16) FileAction {
        switch (char) {
            27 => self.mode = .Browse,
            'y', 'Y' => {
                self.deleteSelected(true);
                self.mode = .Browse;
            },
            'n', 'N' => self.mode = .Browse,
            else => {},
        }
        return .None;
    }

    fn handleRecycleBinMode(self: *FileManager, char: u16) FileAction {
        switch (char) {
            27 => {
                self.mode = .Browse;
                self.selected_index = 0;
            },
            'w', 'W' => {
                if (self.selected_index > 0) self.selected_index -= 1;
            },
            's', 'S' => {
                if (self.selected_index < self.recycle_count -| 1) self.selected_index += 1;
            },
            'r', 'R' => {
                self.restoreFromBin();
                return .RestoreFromBin;
            },
            'e', 'E' => {
                self.recycle_count = 0;
                return .EmptyRecycleBin;
            },
            else => {},
        }
        return .None;
    }

    // ==================== File Operations ====================

    fn createFile(self: *FileManager, name: []const u8, file_type: FileType) void {
        if (self.file_count < self.files.len) {
            self.files[self.file_count] = FileEntry.create(name, file_type, 0);
            self.file_count += 1;
        }
    }

    fn renameSelected(self: *FileManager, new_name: []const u8) void {
        if (self.selected_index > 0 and self.selected_index < self.file_count) {
            var file = &self.files[self.selected_index];
            file.name_len = @min(new_name.len, 64);
            @memcpy(file.name[0..file.name_len], new_name[0..file.name_len]);
        }
    }

    fn deleteSelected(self: *FileManager, to_recycle: bool) void {
        if (self.selected_index > 0 and self.selected_index < self.file_count) {
            if (to_recycle and self.recycle_count < self.recycle_bin.len) {
                self.recycle_bin[self.recycle_count] = self.files[self.selected_index];
                self.recycle_count += 1;
            }

            var i: usize = self.selected_index;
            while (i < self.file_count - 1) : (i += 1) {
                self.files[i] = self.files[i + 1];
            }
            self.file_count -= 1;

            if (self.selected_index >= self.file_count and self.selected_index > 0) {
                self.selected_index -= 1;
            }
        }
    }

    fn restoreFromBin(self: *FileManager) void {
        if (self.selected_index < self.recycle_count and self.file_count < self.files.len) {
            self.files[self.file_count] = self.recycle_bin[self.selected_index];
            self.file_count += 1;

            var i: usize = self.selected_index;
            while (i < self.recycle_count - 1) : (i += 1) {
                self.recycle_bin[i] = self.recycle_bin[i + 1];
            }
            self.recycle_count -= 1;

            if (self.selected_index >= self.recycle_count and self.selected_index > 0) {
                self.selected_index -= 1;
            }
        }
    }
};
