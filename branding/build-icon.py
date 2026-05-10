#!/usr/bin/env python3
"""
Build the DreamScribe macOS app icon from the generated standalone S/star asset.

The source image is generated as a complete icon composition, so this script only
normalizes it into the app catalog sizes. It intentionally does not crop the
wordmark; the product icon is its own asset.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).parent
SRC_PNG = ROOT / "source" / "dreamscribe-icon-generated.png"
OUT_DIR = ROOT / "generated"
ASSETS_ROOT = ROOT.parent / "DreamScribe" / "Assets.xcassets"
APPICON_DIR = ASSETS_ROOT / "AppIcon.appiconset"

ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]


def square_crop(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    width, height = image.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    return image.crop((left, top, left + side, top + side))


def build_master_icon() -> Image.Image:
    if not SRC_PNG.exists():
        raise SystemExit(f"Missing generated app icon source: {SRC_PNG}")

    return square_crop(Image.open(SRC_PNG)).resize((1024, 1024), Image.Resampling.LANCZOS)


def main() -> None:
    if not APPICON_DIR.exists():
        raise SystemExit(f"Missing app icon asset catalog: {APPICON_DIR}")

    OUT_DIR.mkdir(exist_ok=True)
    master = build_master_icon()
    master_path = OUT_DIR / "icon-master.png"
    master.save(master_path)
    print(f"wrote {master_path}")

    for size in ICON_SIZES:
        out = OUT_DIR / f"{size}-mac.png"
        master.resize((size, size), Image.Resampling.LANCZOS).save(out)
        shutil.copy2(out, APPICON_DIR / out.name)
        print(f"  rendered {size}x{size} -> {out.name}")

    print("\nDone. Run `make local` to build with the new icon.")


if __name__ == "__main__":
    main()
