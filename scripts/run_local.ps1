# NanoOS Local Launcher for Windows

# 1. Build the project
Write-Host "Building NanoOS..."
zig build
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Build failed."
    exit 1 
}

# 2. Setup Directory for QEMU FAT drive
if (-not (Test-Path "zig-out/EFI/BOOT")) {
    New-Item -ItemType Directory -Force -Path "zig-out/EFI/BOOT" | Out-Null
}
# Note: zig build already installs to zig-out/EFI/BOOT/BOOTX64.EFI, so no copy needed

# 3. Find OVMF
$ovmfPaths = @(
    "OVMF.fd",
    "edk2-x86_64-code.fd",
    "C:\Program Files\qemu\share\OVMF.fd",
    "C:\Program Files\qemu\share\edk2-x86_64-code.fd"
)

$biosPath = $null
foreach ($path in $ovmfPaths) {
    if (Test-Path $path) {
        $biosPath = $path
        break
    }
}

if ($null -eq $biosPath) {
    Write-Warning "OVMF.fd not found."
    Write-Warning "Please download OVMF.fd (UEFI firmware) and place it in this directory."
    Write-Warning "Download link: https://www.kraxel.org/repos/jenkins/edk2/"
    # We will try to run anyway, expecting it might fail or user has it elsewhere
    $biosPath = "OVMF.fd"
}

# 4. Find QEMU
$qemu = "qemu-system-x86_64"
# Check if qemu is in PATH
if (Get-Command $qemu -ErrorAction SilentlyContinue) {
    # It's in PATH
}
elseif (Test-Path "C:\Program Files\qemu\qemu-system-x86_64.exe") {
    $qemu = "& 'C:\Program Files\qemu\qemu-system-x86_64.exe'"
}
else {
    Write-Warning "QEMU not found in PATH or standard locations."
    Write-Warning "Please install QEMU and add it to your PATH, or edit this script."
    Write-Warning "Download: https://www.qemu.org/download/#windows"
}

# 5. Run
Write-Host "Starting QEMU with BIOS: $biosPath"
# Using -drive if=pflash is more robust for some OVMF builds than -bios
$runCmd = "$qemu -drive if=pflash,format=raw,readonly=on,file=`"$biosPath`" -drive format=raw,file=fat:rw:zig-out -net none -serial stdio"
Invoke-Expression $runCmd
