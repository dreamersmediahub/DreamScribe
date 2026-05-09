#!/usr/bin/env python3
"""
Generate an iridescent DREAMERS wordmark PNG and add it to the asset catalog
so MetricsContent.swift can show it as the dashboard hero.
"""

from __future__ import annotations
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent
SRC_SVG = ROOT / "source" / "wordmark.svg"
OUT_DIR = ROOT / "generated"
ASSETS_DIR = ROOT.parent / "VoiceInk" / "Assets.xcassets" / "DreamersWordmark.imageset"

# Match the icon palette
PRISM_STOPS = [
    (0,   "#5BC3DB"),
    (30,  "#8B7DD0"),
    (55,  "#DB6DB0"),
    (78,  "#DBC470"),
    (100, "#5DC09F"),
]

# Render at 3x retina width for the largest expected display (~520pt wide).
TARGET_W = 1560


def build_recolored_svg() -> str:
    src = SRC_SVG.read_text()
    # Wordmark has multiple <path class="cls-1"> elements — give them all the prism fill.
    # Inject defs and a class style. Easier: replace the class definition.
    stops_xml = "\n      ".join(
        f'<stop offset="{pct}%" stop-color="{c}"/>' for pct, c in PRISM_STOPS
    )
    defs = f'''<defs>
    <linearGradient id="prism" x1="0%" y1="0%" x2="100%" y2="100%">
      {stops_xml}
    </linearGradient>
  </defs>'''

    # Insert defs just inside the <svg> element
    src = re.sub(r'(<svg[^>]*>)', r'\1\n  ' + defs, src, count=1)

    # Replace path fills: original is class-based black; force url(#prism)
    src = re.sub(r'<path\b', '<path fill="url(#prism)"', src)

    return src


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    out_svg = OUT_DIR / "wordmark-iridescent.svg"
    out_svg.write_text(build_recolored_svg())

    # Aspect ratio: 1714.15 / 328.32 = 5.22
    height = round(TARGET_W * 328.32 / 1714.15)

    out_png = OUT_DIR / "wordmark@3x.png"
    subprocess.run(
        [
            "rsvg-convert",
            "--width", str(TARGET_W),
            "--height", str(height),
            "--output", str(out_png),
            str(out_svg),
        ],
        check=True,
    )
    print(f"  rendered {TARGET_W}x{height} -> {out_png.name}")

    # Also generate 2x and 1x for the asset catalog
    for scale, suffix in [(2, "@2x"), (1, "")]:
        w = TARGET_W * scale // 3
        h = height * scale // 3
        out = OUT_DIR / f"wordmark{suffix}.png"
        subprocess.run(
            ["rsvg-convert", "--width", str(w), "--height", str(h),
             "--output", str(out), str(out_svg)],
            check=True,
        )
        print(f"  rendered {w}x{h} -> {out.name}")

    # Copy into the asset catalog
    for suffix, fname in [("", "wordmark.png"), ("@2x", "wordmark@2x.png"), ("@3x", "wordmark@3x.png")]:
        src = OUT_DIR / fname
        dst = ASSETS_DIR / fname
        dst.write_bytes(src.read_bytes())

    # Asset catalog manifest
    contents = {
        "images": [
            {"idiom": "universal", "filename": "wordmark.png",     "scale": "1x"},
            {"idiom": "universal", "filename": "wordmark@2x.png",  "scale": "2x"},
            {"idiom": "universal", "filename": "wordmark@3x.png",  "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (ASSETS_DIR / "Contents.json").write_text(json.dumps(contents, indent=2))
    print(f"  imageset ready at {ASSETS_DIR.relative_to(ROOT.parent)}")


if __name__ == "__main__":
    main()
