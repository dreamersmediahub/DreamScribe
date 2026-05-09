#!/usr/bin/env python3
"""
Deep rename: VoiceInk → DreamScribe across folders, Xcode project, and scheme.

This is a one-shot refactor for moving from a forked-VoiceInk identity to a
standalone DreamScribe identity. After this runs, the build artifact name,
target names, scheme, and source folder all read DreamScribe.

NOT idempotent — only runs successfully on the un-renamed tree.
"""

from __future__ import annotations
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

# ---- Step 1: folder + project moves ----
RENAMES = [
    ("VoiceInk",            "DreamScribe"),
    ("VoiceInkTests",       "DreamScribeTests"),
    ("VoiceInkUITests",     "DreamScribeUITests"),
    ("VoiceInk.xcodeproj",  "DreamScribe.xcodeproj"),
]


def step1_move_folders() -> None:
    print("==> Renaming folders…")
    for old, new in RENAMES:
        src = ROOT / old
        dst = ROOT / new
        if dst.exists():
            print(f"  SKIP {old} -> {new} (destination already exists)")
            continue
        if not src.exists():
            print(f"  SKIP {old} -> {new} (source not present; already renamed?)")
            continue
        src.rename(dst)
        print(f"  mv {old} -> {new}")


# ---- Step 2: surgical pbxproj edits ----
PBXPROJ_REPLACEMENTS = [
    # File references for built products (line comments + path attributes)
    ("/* VoiceInk.app */",        "/* DreamScribe.app */"),
    ("/* VoiceInkTests.xctest */", "/* DreamScribeTests.xctest */"),
    ("/* VoiceInkUITests.xctest */", "/* DreamScribeUITests.xctest */"),
    ("path = VoiceInk.app;",      "path = DreamScribe.app;"),
    ("path = VoiceInkTests.xctest;",  "path = DreamScribeTests.xctest;"),
    ("path = VoiceInkUITests.xctest;", "path = DreamScribeUITests.xctest;"),

    # Group folder paths
    ("path = VoiceInk;",          "path = DreamScribe;"),
    ("path = VoiceInkTests;",     "path = DreamScribeTests;"),
    ("path = VoiceInkUITests;",   "path = DreamScribeUITests;"),

    # Target names
    ("name = VoiceInk;",          "name = DreamScribe;"),
    ("name = VoiceInkTests;",     "name = DreamScribeTests;"),
    ("name = VoiceInkUITests;",   "name = DreamScribeUITests;"),

    # productName
    ("productName = VoiceInk;",       "productName = DreamScribe;"),
    ("productName = VoiceInkTests;",  "productName = DreamScribeTests;"),
    ("productName = VoiceInkUITests;", "productName = DreamScribeUITests;"),

    # Build settings — entitlements + Info.plist live inside the renamed source folder
    ("CODE_SIGN_ENTITLEMENTS = VoiceInk/VoiceInk.entitlements;",
     "CODE_SIGN_ENTITLEMENTS = DreamScribe/VoiceInk.entitlements;"),
    ("CODE_SIGN_ENTITLEMENTS = VoiceInk/VoiceInk.local.entitlements;",
     "CODE_SIGN_ENTITLEMENTS = DreamScribe/VoiceInk.local.entitlements;"),
    ("INFOPLIST_FILE = VoiceInk/Info.plist;",
     "INFOPLIST_FILE = DreamScribe/Info.plist;"),

    # SwiftUI Preview content asset path
    ('DEVELOPMENT_ASSET_PATHS = "\\"VoiceInk/Preview Content\\"";',
     'DEVELOPMENT_ASSET_PATHS = "\\"DreamScribe/Preview Content\\"";'),

    # TEST_HOST: $(BUILT_PRODUCTS_DIR)/VoiceInk.app/.../VoiceInk
    ('TEST_HOST = "$(BUILT_PRODUCTS_DIR)/VoiceInk.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/VoiceInk";',
     'TEST_HOST = "$(BUILT_PRODUCTS_DIR)/DreamScribe.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DreamScribe";'),
]


def step2_patch_pbxproj() -> None:
    print("==> Patching pbxproj…")
    pbxproj = ROOT / "DreamScribe.xcodeproj" / "project.pbxproj"
    if not pbxproj.exists():
        sys.exit(f"ERROR: {pbxproj} does not exist (folder rename failed?)")

    text = pbxproj.read_text()
    total = 0
    for old, new in PBXPROJ_REPLACEMENTS:
        n = text.count(old)
        if n == 0:
            print(f"  SKIP no match: {old[:60]}")
            continue
        text = text.replace(old, new)
        total += n
        print(f"  ✓ {n}x  {old[:70]}")
    pbxproj.write_text(text)
    print(f"  → {total} replacements")


# ---- Step 3: rename + patch scheme ----
def step3_rename_scheme() -> None:
    print("==> Renaming scheme…")
    schemes_dir = ROOT / "DreamScribe.xcodeproj" / "xcshareddata" / "xcschemes"
    old = schemes_dir / "VoiceInk.xcscheme"
    new = schemes_dir / "DreamScribe.xcscheme"
    if not old.exists():
        if new.exists():
            print(f"  SKIP scheme already renamed")
            return
        print(f"  WARN no scheme at {old}")
        return
    old.rename(new)
    print(f"  mv VoiceInk.xcscheme -> DreamScribe.xcscheme")

    # Patch the scheme content. Schemes reference target by BlueprintName and
    # by the produced .app's BuildableName.
    text = new.read_text()
    replacements = [
        ('BlueprintName = "VoiceInk"',          'BlueprintName = "DreamScribe"'),
        ('BlueprintName = "VoiceInkTests"',     'BlueprintName = "DreamScribeTests"'),
        ('BlueprintName = "VoiceInkUITests"',   'BlueprintName = "DreamScribeUITests"'),
        ('BuildableName = "VoiceInk.app"',      'BuildableName = "DreamScribe.app"'),
        ('BuildableName = "VoiceInkTests.xctest"',  'BuildableName = "DreamScribeTests.xctest"'),
        ('BuildableName = "VoiceInkUITests.xctest"', 'BuildableName = "DreamScribeUITests.xctest"'),
        # Container refs — without these xcodebuild errors with
        # "Scheme is not currently configured for the build action".
        ('container:VoiceInk.xcodeproj', 'container:DreamScribe.xcodeproj'),
    ]
    for o, n in replacements:
        c = text.count(o)
        if c:
            text = text.replace(o, n)
            print(f"  ✓ {c}x  {o[:60]}")
    new.write_text(text)


# ---- Step 4: workspace data ----
def step4_patch_workspace() -> None:
    ws = ROOT / "DreamScribe.xcodeproj" / "project.xcworkspace" / "contents.xcworkspacedata"
    if not ws.exists():
        return
    text = ws.read_text()
    # Workspace usually references the .xcodeproj by name relative to itself.
    # Self-reference; should already be fine but check.
    if "VoiceInk.xcodeproj" in text:
        text = text.replace("VoiceInk.xcodeproj", "DreamScribe.xcodeproj")
        ws.write_text(text)
        print("==> Patched workspace contents.xcworkspacedata")


def main() -> None:
    if not (ROOT / "VoiceInk.xcodeproj").exists() and (ROOT / "DreamScribe.xcodeproj").exists():
        print("Already renamed — nothing to do.")
        return
    step1_move_folders()
    step2_patch_pbxproj()
    step3_rename_scheme()
    step4_patch_workspace()
    print("\n✓ Deep rename complete. Now run: make local")


if __name__ == "__main__":
    main()
