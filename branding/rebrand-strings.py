#!/usr/bin/env python3
"""
Replace user-visible "VoiceInk" strings with "DreamScribe" in source files.

Targeted to specific files + line patterns identified during recon. Avoids:
  - Module / class / identifier references (no spaces, no quotes around)
  - Environment variable names (VOICEINK_* — those are a runtime contract)
  - Logger subsystems (com.prakashjoshipax.voiceink)
  - Bundle identifier / file paths
  - Trial-flow text inside files that don't compile under LOCAL_BUILD anyway
"""

from __future__ import annotations
from pathlib import Path

ROOT = Path(__file__).parent.parent / "VoiceInk"

# (relative file, list-of-(old,new) tuples)
REPLACEMENTS = [
    # Window titles
    ("WindowManager.swift", [
        ('window.title = "VoiceInk"',           'window.title = "DreamScribe"'),
        ('window.title = "VoiceInk Onboarding"', 'window.title = "DreamScribe Onboarding"'),
    ]),
    ("HistoryWindowController.swift", [
        ('"VoiceInk — Transcription History"', '"DreamScribe — Transcription History"'),
    ]),

    # Sidebar header
    ("Views/ContentView.swift", [
        ('Text("VoiceInk")', 'Text("DreamScribe")'),
    ]),

    # Dashboard / metrics
    ("Views/Metrics/MetricsContent.swift", [
        ('Text(" with VoiceInk")', 'Text(" with DreamScribe")'),
        ('detail: "VoiceInk sessions completed"', 'detail: "DreamScribe sessions completed"'),
    ]),
    ("Views/Metrics/MetricsSetupView.swift", [
        ('Text("Welcome to VoiceInk")',          'Text("Welcome to DreamScribe")'),
        ('"Use VoiceInk anywhere with a shortcut."', '"Use DreamScribe anywhere with a shortcut."'),
    ]),

    # Power Mode
    ("PowerMode/PowerModeView.swift", [
        ('"Create first power mode to automate your VoiceInk workflow based on apps/website you are using"',
         '"Create first power mode to automate your DreamScribe workflow based on apps/website you are using"'),
    ]),

    # Permissions
    ("Views/PermissionsView.swift", [
        ('"VoiceInk requires the following permissions to function properly"',
         '"DreamScribe requires the following permissions to function properly"'),
        ('"Set up a keyboard shortcut to use VoiceInk anywhere"',
         '"Set up a keyboard shortcut to use DreamScribe anywhere"'),
        ('"Allow VoiceInk to record your voice for transcription"',
         '"Allow DreamScribe to record your voice for transcription"'),
        ('"Allow VoiceInk to paste transcribed text directly at your cursor position"',
         '"Allow DreamScribe to paste transcribed text directly at your cursor position"'),
        ('"Allow VoiceInk to understand context from your screen for transcript Enhancement"',
         '"Allow DreamScribe to understand context from your screen for transcript Enhancement"'),
    ]),

    # Onboarding
    ("Views/Onboarding/OnboardingPermissionsView.swift", [
        ('"Select the audio input device you want to use with VoiceInk."',
         '"Select the audio input device you want to use with DreamScribe."'),
        ('"Allow VoiceInk to help you type anywhere in your Mac."',
         '"Allow DreamScribe to help you type anywhere in your Mac."'),
        ('"Set up a keyboard shortcut to quickly access VoiceInk from anywhere."',
         '"Set up a keyboard shortcut to quickly access DreamScribe from anywhere."'),
    ]),
    ("Views/Onboarding/OnboardingTutorialView.swift", [
        ('"Let\'s test your VoiceInk setup."', '"Let\'s test your DreamScribe setup."'),
    ]),

    # Settings
    ("Views/Settings/SettingsView.swift", [
        ('"Control how VoiceInk handles your transcription data and audio recordings."',
         '"Control how DreamScribe handles your transcription data and audio recordings."'),
    ]),

    # Dictionary
    ("Views/Dictionary/DictionarySettingsView.swift", [
        ('"Enhance VoiceInk\'s transcription accuracy by teaching it your vocabulary"',
         '"Enhance DreamScribe\'s transcription accuracy by teaching it your vocabulary"'),
    ]),
    ("Views/Dictionary/VocabularyView.swift", [
        ('"Add words to help VoiceInk recognize them properly. (Requires AI enhancement)"',
         '"Add words to help DreamScribe recognize them properly. (Requires AI enhancement)"'),
    ]),
    ("Views/Dictionary/WordReplacementView.swift", [
        # Example "from"/"to" sample — replace with brand
        ('Text("VoiceInk")', 'Text("DreamScribe")'),
    ]),
    ("Views/Dictionary/DictionaryQuickAddPanel.swift", [
        ('prompt: Text("e.g. Prakash, VoiceInk")', 'prompt: Text("e.g. Kyle, DreamScribe")'),
    ]),

    # Import / Export file dialogs
    ("Services/ImportExportService.swift", [
        ('savePanel.title = "Export VoiceInk Settings"',  'savePanel.title = "Export DreamScribe Settings"'),
        ('openPanel.title = "Import VoiceInk Settings"',  'openPanel.title = "Import DreamScribe Settings"'),
    ]),

    # App Intents (Siri / Shortcuts)
    ("AppIntents/DismissMiniRecorderIntent.swift", [
        ('"Dismiss VoiceInk Recorder"',
         '"Dismiss DreamScribe Recorder"'),
        ('"Dismiss the VoiceInk mini recorder and cancel any active recording."',
         '"Dismiss the DreamScribe mini recorder and cancel any active recording."'),
    ]),
    ("AppIntents/ToggleMiniRecorderIntent.swift", [
        ('"Toggle VoiceInk Recorder"',
         '"Toggle DreamScribe Recorder"'),
        ('"Start or stop the VoiceInk mini recorder for voice transcription."',
         '"Start or stop the DreamScribe mini recorder for voice transcription."'),
    ]),
]


def main() -> None:
    total_files_changed = 0
    total_replacements = 0
    for rel, swaps in REPLACEMENTS:
        path = ROOT / rel
        if not path.exists():
            print(f"  SKIP missing: {rel}")
            continue
        text = path.read_text()
        original = text
        local_count = 0
        for old, new in swaps:
            if old not in text:
                print(f"  WARN no match in {rel}: {old[:60]}…")
                continue
            text = text.replace(old, new)
            local_count += 1
        if text != original:
            path.write_text(text)
            total_files_changed += 1
            total_replacements += local_count
            print(f"  edited {rel} ({local_count} replacements)")
    print(f"\n{total_replacements} replacements across {total_files_changed} files.")


if __name__ == "__main__":
    main()
