#!/usr/bin/env python3
"""
Build the generated DREAMScribe wordmark asset catalog.

The source PNG is an image-generation concept approved for this branch. This
script removes the pale matte, crops the logo, and emits retina images for
DreamScribeWordmark.imageset.
"""

from __future__ import annotations
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).parent
SRC_PNG = ROOT / "source" / "dreamscribe-wordmark-generated.png"
OUT_DIR = ROOT / "generated"
ASSETS_ROOT = ROOT.parent / "DreamScribe" / "Assets.xcassets"
ASSETS_DIR = ASSETS_ROOT / "DreamScribeWordmark.imageset"

TARGET_WIDTHS = {
    "": 520,
    "@2x": 1040,
    "@3x": 1560,
}


def matte_to_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    background = rgba.getpixel((0, 0))[:3]
    pixels = rgba.load()
    width, height = rgba.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            distance = ((r - background[0]) ** 2 + (g - background[1]) ** 2 + (b - background[2]) ** 2) ** 0.5

            if distance < 33 and r > 220 and g > 225 and b > 235:
                alpha = 0
            elif distance < 70 and r > 205 and g > 210 and b > 225:
                alpha = int(min(255, max(0, (distance - 33) / 37 * 255)))
            else:
                alpha = a

            pixels[x, y] = (r, g, b, alpha)

    return rgba


def crop_logo(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise SystemExit("No visible logo pixels after matte removal")

    pad = 40
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(image.width, bbox[2] + pad)
    bottom = min(image.height, bbox[3] + pad)
    return image.crop((left, top, right, bottom))


def main() -> None:
    if not SRC_PNG.exists():
        raise SystemExit(f"Missing generated wordmark source: {SRC_PNG}")

    OUT_DIR.mkdir(exist_ok=True)
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    logo = crop_logo(matte_to_alpha(Image.open(SRC_PNG)))
    transparent_source = OUT_DIR / "dreamscribe-wordmark-transparent.png"
    logo.save(transparent_source)
    print(f"  wrote {transparent_source.relative_to(ROOT.parent)}")

    for suffix, target_width in TARGET_WIDTHS.items():
        height = round(logo.height * (target_width / logo.width))
        resized = logo.resize((target_width, height), Image.Resampling.LANCZOS)
        filename = f"dreamscribe-wordmark{suffix}.png"
        out = OUT_DIR / filename
        resized.save(out)
        shutil.copy2(out, ASSETS_DIR / filename)
        print(f"  rendered {target_width}x{height} -> {filename}")

    contents = {
        "images": [
            {"idiom": "universal", "filename": "dreamscribe-wordmark.png", "scale": "1x"},
            {"idiom": "universal", "filename": "dreamscribe-wordmark@2x.png", "scale": "2x"},
            {"idiom": "universal", "filename": "dreamscribe-wordmark@3x.png", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (ASSETS_DIR / "Contents.json").write_text(json.dumps(contents, indent=2))
    print(f"  imageset ready at {ASSETS_DIR.relative_to(ROOT.parent)}")


if __name__ == "__main__":
    main()
