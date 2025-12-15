#!/usr/bin/env python3
"""
Generate HeadsUp app icon at all required sizes
"""

from PIL import Image, ImageDraw
import os

def create_gradient_background(size):
    """Create a blue-purple gradient background"""
    image = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(image)

    # Create gradient from blue to purple
    for y in range(size):
        # Calculate color interpolation
        ratio = y / size
        r = int(0 + (90 - 0) * ratio)      # 0 -> 90
        g = int(122 + (87 - 122) * ratio)   # 122 -> 87
        b = int(255 + (214 - 255) * ratio)  # 255 -> 214

        draw.line([(0, y), (size, y)], fill=(r, g, b))

    return image

def draw_rounded_rectangle(draw, bounds, radius, fill):
    """Draw a rounded rectangle"""
    x1, y1, x2, y2 = bounds
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    draw.pieslice([x1, y1, x1 + 2*radius, y1 + 2*radius], 180, 270, fill=fill)
    draw.pieslice([x2 - 2*radius, y1, x2, y1 + 2*radius], 270, 360, fill=fill)
    draw.pieslice([x1, y2 - 2*radius, x1 + 2*radius, y2], 90, 180, fill=fill)
    draw.pieslice([x2 - 2*radius, y2 - 2*radius, x2, y2], 0, 90, fill=fill)

def generate_icon(size):
    """Generate the HeadsUp icon at specified size"""
    # Create base image with gradient
    image = create_gradient_background(size)
    draw = ImageDraw.Draw(image)

    # Calculate proportional sizes
    cal_size = int(size * 0.65)
    cal_x = (size - cal_size) // 2
    cal_y = (size - cal_size) // 2
    radius = int(size * 0.12)

    # Draw calendar background (white rectangle with rounded corners)
    draw_rounded_rectangle(
        draw,
        [cal_x, cal_y, cal_x + cal_size, cal_y + cal_size],
        radius,
        (245, 245, 245)  # Off-white
    )

    # Draw calendar header (red bar at top)
    header_height = int(size * 0.12)
    header_radius = int(size * 0.05)
    draw_rounded_rectangle(
        draw,
        [cal_x, cal_y, cal_x + cal_size, cal_y + header_height],
        header_radius,
        (255, 69, 58)  # Red
    )

    # Draw calendar grid (simplified)
    grid_start_y = cal_y + header_height + int(size * 0.08)
    grid_spacing = int(size * 0.08)
    dot_size = int(size * 0.04)

    for row in range(3):
        for col in range(4):
            x = cal_x + int(size * 0.1) + col * grid_spacing
            y = grid_start_y + row * int(size * 0.06)
            # Highlight one dot in blue, others in gray
            color = (0, 122, 255) if (row == 1 and col == 1) else (200, 200, 200)
            draw.ellipse([x, y, x + dot_size, y + dot_size], fill=color)

    # Draw notification bell circle (orange background)
    bell_size = int(size * 0.35)
    bell_x = int(size * 0.55)
    bell_y = int(size * 0.55)

    # Shadow for bell
    shadow_offset = int(size * 0.02)
    draw.ellipse(
        [bell_x + shadow_offset, bell_y + shadow_offset,
         bell_x + bell_size + shadow_offset, bell_y + bell_size + shadow_offset],
        fill=(0, 0, 0, 50)
    )

    # Orange circle
    draw.ellipse(
        [bell_x, bell_y, bell_x + bell_size, bell_y + bell_size],
        fill=(255, 149, 0)  # Orange
    )

    # Draw simple bell shape (triangle + rectangle)
    bell_inner_size = int(size * 0.15)
    bell_center_x = bell_x + bell_size // 2
    bell_center_y = bell_y + bell_size // 2

    # Bell body (trapezoid)
    bell_width = int(bell_inner_size * 0.8)
    bell_height = int(bell_inner_size * 0.9)
    bell_top = bell_center_y - bell_height // 3

    points = [
        (bell_center_x - bell_width // 3, bell_top),
        (bell_center_x + bell_width // 3, bell_top),
        (bell_center_x + bell_width // 2, bell_top + bell_height),
        (bell_center_x - bell_width // 2, bell_top + bell_height)
    ]
    draw.polygon(points, fill=(255, 255, 255))

    # Bell clapper (small circle)
    clapper_size = int(size * 0.02)
    draw.ellipse(
        [bell_center_x - clapper_size, bell_top + bell_height - clapper_size,
         bell_center_x + clapper_size, bell_top + bell_height + clapper_size],
        fill=(255, 255, 255)
    )

    # Notification badge (red dot in top-right)
    badge_size = int(size * 0.08)
    badge_x = bell_x + bell_size - badge_size // 2
    badge_y = bell_y - badge_size // 4

    # White border
    draw.ellipse(
        [badge_x - 2, badge_y - 2, badge_x + badge_size + 2, badge_y + badge_size + 2],
        fill=(255, 255, 255)
    )
    # Red badge
    draw.ellipse(
        [badge_x, badge_y, badge_x + badge_size, badge_y + badge_size],
        fill=(255, 59, 48)  # Red
    )

    return image

def main():
    # Icon sizes needed for macOS app
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    # Output directory
    output_dir = "HeadsUp/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)

    print("🎨 Generating HeadsUp app icons...")
    print(f"📁 Output directory: {output_dir}\n")

    for size, filename in sizes:
        icon = generate_icon(size)
        filepath = os.path.join(output_dir, filename)
        icon.save(filepath, "PNG")
        print(f"✓ Generated: {filename} ({size}×{size})")

    print("\n✅ All icons generated successfully!")
    print(f"📦 Icons saved to: {output_dir}/")

if __name__ == "__main__":
    main()
