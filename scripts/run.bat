@echo off
echo Building NanoOS...
zig build
if %errorlevel% neq 0 exit /b %errorlevel%

if not exist zig-out\EFI\BOOT mkdir zig-out\EFI\BOOT
copy /Y zig-out\bin\NanoOS.efi zig-out\EFI\BOOT\BOOTX64.EFI >nul

set BIOS_PATH=OVMF.fd
if not exist %BIOS_PATH% (
    echo OVMF.fd not found in current directory.
    echo Please download it and place it here.
    exit /b 1
)

echo Starting QEMU...
qemu-system-x86_64 -drive if=pflash,format=raw,readonly=on,file=%BIOS_PATH% -drive format=raw,file=fat:rw:zig-out -net none -serial stdio
