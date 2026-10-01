import math
import os
from PIL import Image, ImageDraw, ImageFilter

def create_sparkle_polygon(cx, cy, radius, pinch=0.24, num_steps=32):
    """
    Generate polygon vertices approximating the 4-point cubic Bezier sparkle
    defined in ZyloSparklePainter.
    """
    p = radius * pinch
    top = (cx, cy - radius)
    right = (cx + radius, cy)
    bottom = (cx, cy + radius)
    left = (cx - radius, cy)

    # 4 segments with cubic Bezier curves
    segments = [
        # top to right
        (top, (cx + p, cy - p), right),
        # right to bottom
        (right, (cx + p, cy + p), bottom),
        # bottom to left
        (bottom, (cx - p, cy + p), left),
        # left to top
        (left, (cx - p, cy - p), top),
    ]

    points = []
    for start, ctrl, end in segments:
        for i in range(num_steps):
            t = i / float(num_steps)
            # Quadratic Bezier or Cubic with single control
            # B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
            bx = (1 - t)**2 * start[0] + 2 * (1 - t) * t * ctrl[0] + t**2 * end[0]
            by = (1 - t)**2 * start[1] + 2 * (1 - t) * t * ctrl[1] + t**2 * end[1]
            points.append((bx, by))
    return points

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def generate_zylo_icon(size=1024):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # 1. Dark background gradient (#1A1412 to #0C0908)
    bg = Image.new("RGBA", (size, size))
    bg_draw = ImageDraw.Draw(bg)
    c_top = hex_to_rgb("#1C1513")
    c_bot = hex_to_rgb("#090706")
    for y in range(size):
        t = y / float(size)
        c = lerp_color(c_top, c_bot, t)
        bg_draw.line([(0, y), (size, y)], fill=(c[0], c[1], c[2], 255))
    
    # 2. Warm ambient radial glow in the center-left
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    cx = size * 0.46
    cy = size * 0.52
    r_glow = size * 0.55
    glow_color = hex_to_rgb("#FF5722")
    
    for r in range(int(r_glow), 0, -6):
        alpha = int(70 * (1.0 - (r / r_glow)**1.5))
        if alpha > 0:
            glow_draw.ellipse(
                [cx - r, cy - r, cx + r, cy + r],
                fill=(glow_color[0], glow_color[1], glow_color[2], alpha)
            )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=size * 0.08))
    
    # Composite glow on bg
    img = Image.alpha_composite(bg, glow)

    # 3. Ambient bloom specifically for sparkles
    bloom = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bloom_draw = ImageDraw.Draw(bloom)
    r_bloom = size * 0.35
    for r in range(int(r_bloom), 0, -4):
        alpha = int(120 * (1.0 - (r / r_bloom)**1.8))
        if alpha > 0:
            bloom_draw.ellipse(
                [cx - r, cy - r, cx + r, cy + r],
                fill=(255, 107, 53, alpha)
            )
    bloom = bloom.filter(ImageFilter.GaussianBlur(radius=size * 0.06))
    img = Image.alpha_composite(img, bloom)

    # 4. Draw dual sparkles with gradient
    sparkle_mask = Image.new("L", (size, size), 0)
    sparkle_draw = ImageDraw.Draw(sparkle_mask)

    # Main sparkle
    r_main = size * 0.33
    main_poly = create_sparkle_polygon(cx, cy, r_main, pinch=0.24, num_steps=64)
    sparkle_draw.polygon(main_poly, fill=255)

    # Secondary sparkle (offset top-right)
    sec_cx = size * 0.72
    sec_cy = size * 0.28
    r_sec = r_main * 0.36
    sec_poly = create_sparkle_polygon(sec_cx, sec_cy, r_sec, pinch=0.24, num_steps=64)
    sparkle_draw.polygon(sec_poly, fill=255)

    # Anti-alias mask slightly
    sparkle_mask = sparkle_mask.filter(ImageFilter.GaussianBlur(radius=1.2))

    # Sparkle gradient fill: bottom-left (#FF3300) to top-right (#FFA855)
    c1 = hex_to_rgb("#FF2E00")
    c2 = hex_to_rgb("#FF7730")
    c3 = hex_to_rgb("#FFB366")
    sparkle_grad = Image.new("RGBA", (size, size))
    s_draw = ImageDraw.Draw(sparkle_grad)
    for x in range(size):
        for y in range(size):
            # diagonal progression from bottom-left to top-right
            prog = ((x) + (size - y)) / (2.0 * size)
            prog = max(0.0, min(1.0, prog))
            if prog < 0.5:
                c = lerp_color(c1, c2, prog * 2.0)
            else:
                c = lerp_color(c2, c3, (prog - 0.5) * 2.0)
            s_draw.point((x, y), fill=(c[0], c[1], c[2], 255))

    # Apply sparkle mask over img
    img.paste(sparkle_grad, (0, 0), sparkle_mask)

    # Return RGB without alpha (for AppIcon requirement)
    final_icon = Image.new("RGB", (size, size))
    final_icon.paste(img, (0, 0))
    return final_icon

def export_icons():
    print("Generating Zylo 1024x1024 Master Icon...")
    master = generate_zylo_icon(1024)
    
    # Save master
    os.makedirs("assets/branding", exist_ok=True)
    master.save("assets/branding/zylo_icon_1024.png", "PNG")
    print("Saved assets/branding/zylo_icon_1024.png")

    # iOS Icons
    ios_base = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_targets = {
        "Icon-App-1024x1024@1x.png": (1024, 1024),
        "Icon-App-20x20@1x.png": (20, 20),
        "Icon-App-20x20@2x.png": (40, 40),
        "Icon-App-20x20@3x.png": (60, 60),
        "Icon-App-29x29@1x.png": (29, 29),
        "Icon-App-29x29@2x.png": (58, 58),
        "Icon-App-29x29@3x.png": (87, 87),
        "Icon-App-40x40@1x.png": (40, 40),
        "Icon-App-40x40@2x.png": (80, 80),
        "Icon-App-40x40@3x.png": (120, 120),
        "Icon-App-60x60@2x.png": (120, 120),
        "Icon-App-60x60@3x.png": (180, 180),
        "Icon-App-76x76@1x.png": (76, 76),
        "Icon-App-76x76@2x.png": (152, 152),
        "Icon-App-83.5x83.5@2x.png": (167, 167),
    }

    if os.path.exists(ios_base):
        for filename, (w, h) in ios_targets.items():
            out_path = os.path.join(ios_base, filename)
            resized = master.resize((w, h), Image.Resampling.LANCZOS)
            resized.save(out_path, "PNG")
            print(f"Exported iOS icon: {filename} ({w}x{h})")

    # Android Icons
    android_targets = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    }

    for path, (w, h) in android_targets.items():
        if os.path.exists(os.path.dirname(path)):
            resized = master.resize((w, h), Image.Resampling.LANCZOS)
            resized.save(path, "PNG")
            print(f"Exported Android icon: {path} ({w}x{h})")

if __name__ == "__main__":
    export_icons()
