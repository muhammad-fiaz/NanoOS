# NanoOS

A 64-bit UEFI-only operating system written in Zig.

## Requirements

- **Zig**: Version 0.15.x or later (Master branch recommended).
- **QEMU**: For emulation and testing.
- **Docker**: For containerized building and running (optional but recommended).

## Building & Running

### Using Docker (Recommended)

1.  **Build the Docker Image**:

    ```bash
    docker build -t nanoos .
    ```

2.  **Run with QEMU**:
    - **Linux**:
      ```bash
      docker run -it --rm -v $(pwd):/app -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix nanoos
      ```
    - **Windows (PowerShell)**:
      - Requires an X Server (like VcXsrv) running on Windows.
      - Set Display number to 0.
      ```powershell
      docker run -it --rm -v ${PWD}:/app -e DISPLAY=host.docker.internal:0.0 nanoos
      ```

### Running Locally on Windows

1.  **Prerequisites**:

    - **Zig**: Installed and in PATH.
    - **QEMU**: Installed and in PATH (or `C:\Program Files\qemu`).
    - **OVMF**: `OVMF.fd` file placed in the project directory.

2.  **Run**:
    - **PowerShell**: `.\scripts\run_local.ps1`
    - **CMD**: `.\scripts\run.bat`
    - **Linux**: `./scripts/run.sh`

### Manual Build

1.  **Build**:

    ```bash
    zig build
    ```

2.  **Run in QEMU**:
    Ensure `qemu-system-x86_64` and `OVMF.fd` are in your PATH or current directory.
    ```bash
    qemu-system-x86_64 -bios OVMF.fd -drive format=raw,file=fat:rw:zig-out -net none -serial stdio
    ```

## Architecture

NanoOS uses a layered architecture:

1.  **UEFI Layer**: The OS boots as a UEFI application. It uses UEFI Boot Services to locate hardware (Graphics, Input).
2.  **HAL (Hardware Abstraction Layer)**: Wraps raw UEFI protocols into easy-to-use Zig structs (e.g., `FrameBuffer`).
3.  **GUI Engine**: Provides high-level drawing capabilities on top of the HAL.
4.  **Kernel/Desktop**: The main loop that manages the UI and handles user input.

## Features

- **UEFI Boot**: Boots directly from firmware.
- **Graphics**: High-resolution framebuffer with 32-bit color.
- **Desktop**: Simple window manager with a Taskbar, Icons, and Windows.
- **Apps**: Terminal, File Manager, Calculator, Editor, Sound Recorder.
- **Input**: Mouse and Keyboard support.
