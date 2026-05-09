#!/usr/bin/env python3
"""
Build the DreamScribe app icon set from the Dreamers submark SVG.

Generates a master 1024x1024 SVG (squircle backplate + iridescent prism D)
and rasterizes to the 7 sizes Xcode's AppIcon.appiconset expects.
"""

from __future__ import annotations
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent
SRC_SVG = ROOT / "source" / "submark.svg"
OUT_DIR = ROOT / "generated"
ASSETS_ROOT = ROOT.parent / "DreamScribe" / "Assets.xcassets"
APPICON_DIR = ASSETS_ROOT / "AppIcon.appiconset"

# Approximate sRGB hexes for the OKLCH prism stops in colors_and_type.css.
# Close enough for a 1024px icon; fine-tune visually if needed.
PRISM_STOPS = [
    (0,   "#5BC3DB"),   # cyan
    (30,  "#8B7DD0"),   # violet
    (55,  "#DB6DB0"),   # magenta
    (78,  "#DBC470"),   # lemon
    (100, "#5DC09F"),   # mint
]
INK = "#0a0908"
INK_2 = "#1f1c19"

# macOS HIG: app-icon corner radius ~22.4% of size for the squircle look.
CORNER_RX = 228

ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]


def read_submark_path() -> str:
    text = SRC_SVG.read_text()
    m = re.search(r'<path[^>]*d="([^"]+)"', text)
    if not m:
        raise SystemExit("Could not extract path from submark.svg")
    return m.group(1)


def build_master_svg(submark_path: str) -> str:
    """Construct a 1024x1024 master SVG."""
    # The submark viewBox is 1493.92 x 1300.41. Fit it into a centered 700x700-ish
    # area inside the 1024 frame, leaving comfortable margins.
    target_w = 700
    sw, sh = 1493.92, 1300.41
    scale = target_w / sw                           # ≈ 0.4685
    drawn_w = sw * scale
    drawn_h = sh * scale
    tx = (1024 - drawn_w) / 2
    ty = (1024 - drawn_h) / 2

    stops_xml = "\n      ".join(
        f'<stop offset="{pct}%" stop-color="{c}"/>' for pct, c in PRISM_STOPS
    )

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <linearGradient id="prism" x1="0%" y1="0%" x2="100%" y2="100%">
      {stops_xml}
    </linearGradient>
    <radialGradient id="bg" cx="50%" cy="42%" r="78%">
      <stop offset="0%"  stop-color="{INK_2}"/>
      <stop offset="100%" stop-color="{INK}"/>
    </radialGradient>
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="6" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <rect x="0" y="0" width="1024" height="1024" rx="{CORNER_RX}" ry="{CORNER_RX}" fill="url(#bg)"/>
  <g transform="translate({tx:.2f},{ty:.2f}) scale({scale:.6f})" filter="url(#glow)">
    <path fill="url(#prism)" d="{submark_path}"/>
  </g>
</svg>
'''


def rasterize(master_svg_path: Path, out_path: Path, size: int) -> None:
    if shutil.which("rsvg-convert") is None:
        raise SystemExit("Missing rsvg-convert. Install librsvg with `brew install librsvg`.")
    subprocess.run(
        [
            "rsvg-convert",
            "--width", str(size),
            "--height", str(size),
            "--output", str(out_path),
            str(master_svg_path),
        ],
        check=True,
    )


def main() -> None:
    if not SRC_SVG.exists():
        raise SystemExit(f"Missing source SVG: {SRC_SVG}")
    if not APPICON_DIR.exists():
        raise SystemExit(f"Missing app icon asset catalog: {APPICON_DIR}")

    OUT_DIR.mkdir(exist_ok=True)
    submark_path = read_submark_path()
    master = OUT_DIR / "icon-master.svg"
    master.write_text(build_master_svg(submark_path))
    print(f"wrote {master}")

    for size in ICON_SIZES:
        out = OUT_DIR / f"{size}-mac.png"
        rasterize(master, out, size)
        print(f"  rasterized {size}x{size} -> {out.name}")

    print(f"\ncopying into {APPICON_DIR}/")
    for size in ICON_SIZES:
        src = OUT_DIR / f"{size}-mac.png"
        dst = APPICON_DIR / f"{size}-mac.png"
        shutil.copy2(src, dst)
        print(f"  {dst.name}")

    print("\nDone. Run `make local` to build with the new icon.")


if __name__ == "__main__":
    main()
