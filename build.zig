const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for.
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .uefi,
            .abi = .msvc,
        },
    });

    const optimize = b.standardOptimizeOption(.{});

    // Create the root module
    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create the executable using the module
    const exe = b.addExecutable(.{
        .name = "NanoOS",
        .root_module = mod,
    });

    // Install the artifact as EFI/BOOT/BOOTX64.EFI for automatic booting
    const install_step = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = "EFI/BOOT" } },
        .dest_sub_path = "BOOTX64.EFI",
    });
    b.getInstallStep().dependOn(&install_step.step);

    // Convenience step to run in QEMU (optional, but good practice)
    // Note: Running UEFI apps directly via 'zig build run' is tricky without a runner,
    // so we rely on the external script, but we could add a custom step here.
}
