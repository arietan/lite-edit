#!/usr/bin/env python3
"""Generate LiteEdit app icon — a clean, modern text-editor icon."""
from PIL import Image, ImageDraw, ImageFont
import subprocess, os, tempfile, struct

SIZE = 1024
R = 180  # corner radius

def rounded_rect_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask

def draw_icon():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Background: dark Monokai gradient
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=R, fill=(39, 40, 34))

    # Subtle inner shadow / border
    d.rounded_rectangle([3, 3, SIZE - 4, SIZE - 4], radius=R - 2, outline=(60, 62, 52), width=2)

    # Title bar area
    d.rounded_rectangle([0, 0, SIZE - 1, 140], radius=R, fill=(28, 29, 24))
    d.rectangle([0, 100, SIZE - 1, 140], fill=(28, 29, 24))

    # Three traffic-light dots
    dot_y = 70
    for i, color in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse([60 + i * 56, dot_y - 14, 60 + i * 56 + 28, dot_y + 14], fill=color)

    # Tab indicators on title bar
    # Active tab
    d.rounded_rectangle([320, 30, 560, 120], radius=12, fill=(39, 40, 34))
    d.rectangle([320, 100, 560, 120], fill=(39, 40, 34))
    # Accent bar on active tab
    d.rectangle([320, 30, 560, 36], fill=(249, 38, 114))

    # Inactive tab hint
    d.rounded_rectangle([580, 30, 760, 120], radius=12, fill=(34, 35, 30))
    d.rectangle([580, 100, 760, 120], fill=(34, 35, 30))

    # Code lines (Monokai-style syntax colors)
    lines = [
        [(120, 220, (249, 38, 114), "fn"),   (180, 220, (166, 226, 46), "main"),  (310, 220, (248, 248, 242), "() {")],
        [(160, 290, (249, 38, 114), "let"),   (240, 290, (248, 248, 242), "msg ="), (390, 290, (230, 219, 116), '"Hello"')],
        [(160, 360, (102, 217, 239), "print"), (290, 360, (248, 248, 242), "(msg)")],
        [(160, 430, (249, 38, 114), "for"),   (240, 430, (248, 248, 242), "i"),     (280, 430, (249, 38, 114), "in"),
         (330, 430, (174, 129, 255), "0"), (360, 430, (248, 248, 242), ".."), (390, 430, (174, 129, 255), "10")],
        [(200, 500, (248, 248, 242), "run(i)")],
        [(160, 570, (248, 248, 242), "}")],
        [(120, 640, (248, 248, 242), "}")],
    ]

    # Line numbers
    line_nums = ["1", "2", "3", "4", "5", "6", "7"]
    try:
        mono = ImageFont.truetype("/System/Library/Fonts/SFMono-Regular.otf", 52)
        mono_bold = ImageFont.truetype("/System/Library/Fonts/SFMono-Bold.otf", 52)
    except OSError:
        try:
            mono = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 52)
            mono_bold = mono
        except OSError:
            mono = ImageFont.load_default()
            mono_bold = mono

    gutter_color = (144, 144, 138)
    for i, num in enumerate(line_nums):
        y = 220 + i * 70
        d.text((55, y), num, fill=gutter_color, font=mono, anchor="ra")

    # Gutter separator
    d.line([(75, 190), (75, 700)], fill=(46, 47, 41), width=2)

    # Code tokens
    for line in lines:
        for x, y, color, text in line:
            f = mono_bold if color == (249, 38, 114) or color == (166, 226, 46) else mono
            d.text((x, y), text, fill=color, font=f)

    # Cursor blink line
    d.rectangle([290, 280, 294, 320], fill=(248, 248, 242))

    # "LE" watermark subtle in bottom-right
    try:
        brand = ImageFont.truetype("/System/Library/Fonts/SFMono-Bold.otf", 120)
    except OSError:
        brand = mono
    d.text((SIZE - 60, SIZE - 60), "LE", fill=(60, 62, 52), font=brand, anchor="rb")

    # Apply rounded mask
    mask = rounded_rect_mask(SIZE, R)
    img.putalpha(mask)
    return img


def create_icns(img, output_path):
    """Create .icns from a PIL image using iconutil."""
    tmpdir = tempfile.mkdtemp()
    iconset = os.path.join(tmpdir, "LiteEdit.iconset")
    os.makedirs(iconset)

    sizes = [16, 32, 64, 128, 256, 512, 1024]
    for s in sizes:
        resized = img.resize((s, s), Image.LANCZOS)
        resized.save(os.path.join(iconset, f"icon_{s}x{s}.png"))
        if s <= 512:
            double = img.resize((s * 2, s * 2), Image.LANCZOS)
            double.save(os.path.join(iconset, f"icon_{s}x{s}@2x.png"))

    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", output_path], check=True)
    subprocess.run(["rm", "-rf", tmpdir])
    print(f"Created {output_path}")


if __name__ == "__main__":
    icon = draw_icon()
    icon.save("/tmp/liteedit_icon_preview.png")

    icns_path = os.path.join(os.path.dirname(__file__), "LiteEdit.icns")
    create_icns(icon, icns_path)
