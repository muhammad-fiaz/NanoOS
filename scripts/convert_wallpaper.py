#!/usr/bin/env python3
"""
Convert wallpaper image to Zig-compatible raw pixel data.
This generates a .zig file with embedded pixel data.
"""

try:
    from PIL import Image
    import sys
    import os
except ImportError:
    print("Error: PIL (Pillow) not installed. Install with: pip install Pillow")
    sys.exit(1)

def convert_image_to_zig(input_path, output_path, max_width=1920, max_height=1080):
    """Convert image to Zig array format."""
    
    # Load image
    img = Image.open(input_path)
    
    # Resize to fit common resolutions while maintaining aspect ratio
    img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)
    
    # Convert to RGB
    img = img.convert('RGB')
    
    width, height = img.size
    pixels = img.load()
    
    # Generate Zig code
    zig_code = f"""// Auto-generated wallpaper data
// Source: {os.path.basename(input_path)}
// Resolution: {width}x{height}

const Color = @import("../hal/framebuffer.zig").Color;

pub const WALLPAPER_WIDTH: u32 = {width};
pub const WALLPAPER_HEIGHT: u32 = {height};

// Compressed color palette (to reduce binary size)
const palette = [_]Color{{
"""
    
    # Create a color palette to reduce data size
    colors_used = set()
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            colors_used.add((r, g, b))
    
    # If too many unique colors, quantize
    if len(colors_used) > 256:
        img = img.quantize(colors=256)
        img = img.convert('RGB')
        pixels = img.load()
        colors_used = set()
        for y in range(height):
            for x in range(width):
                r, g, b = pixels[x, y]
                colors_used.add((r, g, b))
    
    # Build palette
    color_to_index = {}
    for idx, (r, g, b) in enumerate(sorted(colors_used)):
        zig_code += f"    Color{{ .r = {r}, .g = {g}, .b = {b} }},\n"
        color_to_index[(r, g, b)] = idx
    
    zig_code += "};\n\n"
    
    # Generate pixel indices (much smaller than full RGB data)
    zig_code += "// Pixel data as palette indices\n"
    zig_code += "const pixel_data = [_]u8{\n"
    
    for y in range(height):
        zig_code += "    "
        for x in range(width):
            r, g, b = pixels[x, y]
            idx = color_to_index[(r, g, b)]
            zig_code += f"{idx},"
        zig_code += "\n"
    
    zig_code += "};\n\n"
    
    # Add getter function
    zig_code += """
pub fn getPixel(x: u32, y: u32) Color {
    if (x >= WALLPAPER_WIDTH or y >= WALLPAPER_HEIGHT) {
        return Color{ .r = 0, .g = 0, .b = 0 };
    }
    const idx = y * WALLPAPER_WIDTH + x;
    const palette_idx = pixel_data[idx];
    return palette[palette_idx];
}

pub fn getScaledPixel(x: u32, y: u32, target_width: u32, target_height: u32) Color {
    // Scale coordinates
    const src_x = (x * WALLPAPER_WIDTH) / target_width;
    const src_y = (y * WALLPAPER_HEIGHT) / target_height;
    return getPixel(src_x, src_y);
}
"""
    
    # Write to file
    with open(output_path, 'w') as f:
        f.write(zig_code)
    
    print(f"✓ Converted {input_path}")
    print(f"  Resolution: {width}x{height}")
    print(f"  Colors: {len(colors_used)}")
    print(f"  Output: {output_path}")
    print(f"  Size: {os.path.getsize(output_path) / 1024:.1f} KB")

if __name__ == "__main__":
    input_file = "assets/wallpapers/wallpaper1.jpeg"
    output_file = "src/gui/wallpaper_data.zig"
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found")
        sys.exit(1)
    
    convert_image_to_zig(input_file, output_file)
