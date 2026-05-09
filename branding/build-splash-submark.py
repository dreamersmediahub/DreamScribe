#!/usr/bin/env python3
"""
Generate an iridescent submark (just the D-mark, no backplate) for the
launch-splash animation. Outputs an asset catalog imageset.
"""

from __future__ import annotations
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent
SRC_SVG = ROOT / "source" / "submark.svg"
OUT_DIR = ROOT / "generated"
ASSETS_DIR = ROOT.parent / "VoiceInk" / "Assets.xcassets" / "DreamersSubmark.imageset"

PRISM_STOPS = [
    (0,   "#5BC3DB"),
    (30,  "#8B7DD0"),
    (55,  "#DB6DB0"),
    (78,  "#DBC470"),
    (100, "#5DC09F"),
]

# Display target: 240pt-ish on screen, 3x retina = 720px+
TARGET_W = 1080  # comfortable headroom; aspect 1493.92 / 1300.41


def build_recolored_svg() -> str:
    src = SRC_SVG.read_text()
    stops_xml = "\n      ".join(
        f'<stop offset="{pct}%" stop-color="{c}"/>' for pct, c in PRISM_STOPS
    )
    defs = f'''<defs>
    <linearGradient id="prism" x1="0%" y1="0%" x2="100%" y2="100%">
      {stops_xml}
    </linearGradient>
    <filter id="glow" x="-25%" y="-25%" width="150%" height="150%">
      <feGaussianBlur stdDeviation="14" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>'''
    src = re.sub(r'(<svg[^>]*>)', r'\1\n  ' + defs, src, count=1)
    # Wrap path with filter via group
    src = re.sub(r'<path\b', '<path fill="url(#prism)"', src)
    src = re.sub(r'(<g[^>]*id="Isolation_Mode"[^>]*>)', r'<g filter="url(#glow)">\1', src, count=1)
    src = re.sub(r'</svg>', r'</g></svg>', src, count=1)
    return src


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    out_svg = OUT_DIR / "submark-iridescent.svg"
    out_svg.write_text(build_recolored_svg())

    # Aspect: 1493.92 / 1300.41 ≈ 1.149
    h_3x = round(TARGET_W * 1300.41 / 1493.92)

    for scale_label, scale in [("@3x", 3), ("@2x", 2), ("", 1)]:
        w = TARGET_W * scale // 3
        h = h_3x * scale // 3
        out = OUT_DIR / f"submark{scale_label}.png"
        subprocess.run(
            ["rsvg-convert", "--width", str(w), "--height", str(h),
             "--output", str(out), str(out_svg)],
            check=True,
        )
        print(f"  rendered {w}x{h} -> {out.name}")
        (ASSETS_DIR / out.name).write_bytes(out.read_bytes())

    contents = {
        "images": [
            {"idiom": "universal", "filename": "submark.png",     "scale": "1x"},
            {"idiom": "universal", "filename": "submark@2x.png",  "scale": "2x"},
            {"idiom": "universal", "filename": "submark@3x.png",  "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (ASSETS_DIR / "Contents.json").write_text(json.dumps(contents, indent=2))
    print(f"  imageset ready at {ASSETS_DIR.relative_to(ROOT.parent)}")


if __name__ == "__main__":
    main()
