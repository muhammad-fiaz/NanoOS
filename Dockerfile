# Use a base image with necessary tools
FROM debian:bookworm-slim

# Install dependencies: QEMU, OVMF, curl, xz
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    qemu-system-x86 \
    ovmf \
    && rm -rf /var/lib/apt/lists/*

# Install Zig
# Downloading a recent nightly build (0.14.0-dev which is close to what is likely being used, or master)
# Since 0.15.1 is mentioned, we'll try to fetch a very recent master build.
# We'll use a fixed URL for a recent known good nightly to avoid build breakage.
RUN curl -L https://ziglang.org/builds/zig-linux-x86_64-0.14.0-dev.2341+92212e365.tar.xz -o zig.tar.xz \
    && tar -xf zig.tar.xz \
    && mv zig-linux-x86_64-* /usr/local/zig \
    && rm zig.tar.xz

ENV PATH="/usr/local/zig:${PATH}"

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Build the project
RUN zig build

# Command to run QEMU
# Note: To see the GUI window, you need an X server running on the host and pass the DISPLAY environment variable.
CMD ["sh", "-c", "qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -drive format=raw,file=fat:rw:zig-out -net none -serial stdio"]
