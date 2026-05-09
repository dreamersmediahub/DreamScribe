# DreamScribe Code Review (2026-05-09)

Review covers the working-tree delta against upstream commit `cf3ebd2` (Beingpax/VoiceInk @ 1.76).

## Summary

Diff is small, well-scoped, and the brand-identity / `LOCAL_BUILD` gating reads cleanly. Nothing blocking, but a few should-fix items: dead clipboard-restore helpers in `CursorPaster.swift`, a few user-visible "VoiceInk" strings missed by `rebrand-strings.py`, the Sparkle updater still pointing at the upstream appcast under LOCAL_BUILD, and a fragile PlistBuddy step in the Makefile that swallows failures with `|| true`. Splash + onboarding flow brace-balance verified correct. Asset names match imageset folders.

## Blocking issues

None.

## Should-fix issues

1. **`VoiceInk/CursorPaster.swift:9, 45-58, 68-80` — dead code from the paste rewrite.**
   `ClipboardSnapshot` typealias, `snapshotClipboard(from:)`, and `scheduleClipboardRestore(_:on:)` are no longer referenced anywhere (verified via grep). They compile clean but they're unused. Delete them so future readers don't think they're load-bearing. Also delete the now-orphaned `Foundation`-typed `ClipboardSnapshot` line since the only field that used `ClipboardSnapshot` is gone.

2. **`VoiceInk/Views/Settings/SettingsView.swift:22-23, 167-180` (approx) — orphaned UI for "Restore Clipboard After Paste" + "Restore Delay".**
   The toggle and Picker still appear in Settings → Privacy and bind to `restoreClipboardAfterPaste` / `clipboardRestoreDelay`, but `CursorPaster.startPasteAtCursor` ignores both keys now. Either gate the UI under `#if !LOCAL_BUILD` or delete it; otherwise the user can flip a toggle that does nothing. Same applies to `SystemInfoService.swift:58-59` and `BackupImporter.swift:185-189` / `BackupTypes.swift:102-103` / `ImportExportService.swift:189-190`, but those are non-user-visible plumbing — lower priority.

3. **`Makefile:67` — silent PlistBuddy failure.**
   `/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable DreamScribe" "$$HOME/Downloads/DreamScribe.app/Contents/Info.plist" 2>/dev/null || true` swallows any failure. If PlistBuddy fails for any reason (missing plist, locked file, weird ditto state), the app is left with `CFBundleExecutable=VoiceInk` while the Mach-O binary at `Contents/MacOS/` is named `DreamScribe`. macOS will then refuse to launch the bundle ("can't open application because it is damaged"). Replace `|| true` with `|| { echo "ERROR: PlistBuddy failed to update CFBundleExecutable"; exit 1; }`.

4. **`VoiceInk/Info.plist` (`SUFeedURL`) + `VoiceInk/VoiceInk.swift:432-435` — Sparkle updater still aimed at upstream.**
   `SUFeedURL = https://beingpax.github.io/VoiceInk/appcast.xml` is unchanged. `silentlyCheckForUpdates()` runs on every launch (line 306). Under ad-hoc signing the EdDSA verification will likely block the actual install, but the user will still see a "Update Available" notification chrome promoting upstream VoiceInk inside DreamScribe. README claims "No automatic updates" but that's only true for the install step; the *check* still happens. Either:
   - Gate `UpdaterViewModel.init`, the `silentlyCheckForUpdates()` call, and the `CheckForUpdatesView` menu under `#if !LOCAL_BUILD`, or
   - Set `SUEnableAutomaticChecks = false` in a LOCAL_BUILD-only Info.plist override / runtime UserDefault.

5. **Missed "VoiceInk" → "DreamScribe" rebrand in user-visible strings.** All low-impact but the rebrand intent was thorough:
   - `VoiceInk/VoiceInk.swift:76` — "VoiceInk couldn't access its storage location…" alert.
   - `VoiceInk/VoiceInk.swift:297` — "VoiceInk cannot initialize its storage system…" critical alert.
   - `VoiceInk/Views/PermissionsView.swift:261` — Accessibility info-tip "VoiceInk uses Accessibility permissions…"
   - `VoiceInk/Views/PermissionsView.swift:279` — Screen Recording info-tip "VoiceInk captures on-screen text…"
   - `VoiceInk/Views/Onboarding/OnboardingPermissionsView.swift:128` — same Screen Recording info-tip in onboarding flow.
   - `VoiceInk/AppIntents/DismissMiniRecorderIntent.swift:15` — `IntentDialog(stringLiteral: "VoiceInk recorder dismissed")` (Siri spoken response).
   - `VoiceInk/AppIntents/ToggleMiniRecorderIntent.swift:15, 27, 29` — Siri spoken responses ("VoiceInk recorder toggled", "VoiceInk app is not available", "VoiceInk recording service is not available").
   - `VoiceInk/Services/ImportExportService.swift:214` — `nameFieldStringValue = "VoiceInk_Settings_Backup.json"` (default save filename — user-visible, but renaming changes the on-disk contract for backups; safer to leave as-is, just flagging).

   Suggested fix: add these patterns to `branding/rebrand-strings.py` so a re-run is idempotent and complete.

6. **`VoiceInk/Views/MetricsView.swift:23, 37` — "VoiceInk Pro" navigation strings.**
   These are inside `if case .trial / .trialExpired` branches that can never execute under LOCAL_BUILD (because `LicenseViewModel.init()` short-circuits to `.licensed`). Functionally dead, but leaving them creates dead navigation strings that will silently no-op even if a future change re-enables the trial UI. Consider wrapping the `TrialMessageView` calls in `#if !LOCAL_BUILD` for clarity (matches the gating pattern used in `ContentView.swift`).

7. **`CHANGES.md:11` — `.gitignore` claim is inaccurate.**
   CHANGES.md says we added `.local-build/` and `branding/generated/`, but `.local-build/` was already present in upstream `.gitignore` (line 35 in current file). Only `branding/generated/` was actually added.

## Nits

1. **`CursorPaster.swift:34-37` — comment lifespan.** The block-comment now spans 6 lines explaining what was removed. Once the dead helpers are deleted (item 1), trim the comment to a single line: `// Always paste; transcript stays on clipboard for manual fallback.`

2. **`VoiceInk/VoiceInk.swift:278, 358` — indentation/awkward bracketing.** The added `ZStack {` on line 278 is at the same indent level as the `if hasCompletedOnboarding` it now wraps, making it visually look like a sibling rather than a parent. A single-tab indent on the body (lines 279-357) would clarify the structure. Functional, just hard to read on a fresh look.

3. **`LaunchSplashView.swift:55, 63, 68` — magic-number sleep durations.** `1_000_000_000`, `1_000_000_000`, `500_000_000` (= 1.0s, 1.0s, 0.5s) match the cross-fade `duration: 0.7` and fade-out `duration: 0.5` only loosely. Pulling these into named constants (`stage1Hold`, `stage2Hold`, `fadeOut`) would let you tune the splash without re-reading the comment headers. Pure hygiene.

4. **`LaunchSplashView.swift:54` — comment "Hold the submark briefly so the eye can settle on it" is good. The next two phases lack matching narrator comments — would be nice to add for consistency.

5. **`LocalBuild.xcconfig:21` — comment block correctly documents the PRODUCT_NAME hazard. Consider adding a one-liner about target-level overrides being beaten by the `-xcconfig` flag (since the pbxproj still has `INFOPLIST_KEY_CFBundleDisplayName = VoiceInk` at the target level — the override only works because `xcodebuild -xcconfig` is documented as "applied as overrides").

6. **`branding/rebrand-strings.py:135` — `WARN no match in {rel}` print is helpful but exits 0. If a string is missing (e.g. upstream renamed it during a future merge), the rebrand silently misses it. Consider exit-1 on any miss when run with `--strict`, so CI / the rebuild flow can catch drift.

7. **`Makefile:69` — `codesign --force --deep --sign - …` uses `--deep`, which Apple deprecated in favor of signing nested code from inside-out. For ad-hoc on a fresh ditto'd bundle it works, but worth a comment that this is the lazy option.

## Looks good

- **CursorPaster's call surface remained stable.** `startPasteAtCursor`, `pasteAtCursor`, `pasteAtCursorAndWaitUntilPosted` all retain their old signatures. `TranscriptionPipeline.swift:208` (uses `startPasteAtCursor(...).value`) and `LastTranscriptionService.swift:72, 97` (use `pasteAtCursor`) work without modification. No thread-safety issue from the removed `let pasteboard = NSPasteboard.general` capture — the pasteboard was only used for snapshot/restore (now both gone), and `ClipboardManager.setClipboard` and `postPasteCommand` access `NSPasteboard.general` internally.
- **`VoiceInk/VoiceInk.swift:276-359` brace balance.** Counted open/close braces in the `body: some Scene` block: 20 opens / 20 closes. `WindowGroup { ZStack { …onboarding-or-content… ; if !splashFinished { LaunchSplashView … } } }` is structurally correct.
- **`ContentView.swift` switch exhaustiveness.** Both `var icon: String` (lines 24-40) and `detailView(for:)` (lines 178-206) gate `case .license` under `#if !LOCAL_BUILD`. The `ViewType` enum case is also gated, so the switches stay exhaustive in both build paths. Verified by inspection.
- **`ContentView.swift:152-173` notification-routing switch.** Switches on `String`, has a `default: break`, so the `case "VoiceInk Pro"` gating doesn't break exhaustiveness. Even when the case is excluded, the routing fails closed (no navigation, no error).
- **Asset names match.** `Image("DreamersWordmark")` and `Image("DreamersSubmark")` line up exactly with `Assets.xcassets/DreamersWordmark.imageset/` and `DreamersSubmark.imageset/`. PNGs at 1x/2x/3x present in both.
- **`MetricsContent.swift:167-173` hero card.** Wordmark image inserted cleanly; gradient swap from `controlAccentColor` to dark ink palette is correct (the system accent IS now ember orange because of the `AccentColor.colorset` change, so the original gradient would have been an iridescent-on-orange clash).
- **No code-signature validation in our codebase** — verified no calls to `SecStaticCode`, `SecRequirement`, or codesign-related APIs. The Mach-O rename + ad-hoc resign is safe from a self-validation standpoint. Sparkle does have its own EdDSA check on the Info.plist key, but that's an inbound-update guard, not an outbound-trust check.
- **No transcript content is logged.** Verified all `logger.*` calls in `CursorPaster.swift`, `TranscriptionPipeline.swift`, and `LastTranscriptionService.swift`. Only error/notice strings, no transcript bodies.
- **Upstream-merge friction stayed minimal.** All gating uses `#if LOCAL_BUILD` / `#if !LOCAL_BUILD` rather than deletion. Bulk string replacements via `branding/rebrand-strings.py` are exact-match only and conservative — verified by reading the script. No identifier renames, no env-var renames, no logger subsystem changes.
- **`LaunchSplashView` `onComplete` is reachable.** All `Task.sleep` calls use `try?`, so cancellation throws are swallowed and the trailing `onComplete()` always executes. The only failure mode is the parent view going away mid-task, in which case the splash is already gone (irrelevant).

## Notes for future Phase 3 work

1. **Sparkle gating is an immediate prerequisite** for any future "user can ship this internally" branch. Until the upstream feed is replaced or gated, every DreamScribe install will pull update notifications branded as VoiceInk.

2. **The `restoreClipboardAfterPaste` UserDefault is now a phantom contract.** Any future "transformation chains" feature that writes to the clipboard mid-pipeline (e.g., chain step 1 puts intermediate text, step 2 enhances, final step pastes) needs to design without the assumption that the user can restore prior clipboard state. Kyle's preference is documented (transcript persistence > clipboard fidelity), so this is fine — just bake it into chain semantics rather than re-introducing the toggle.

3. **Opus encoding work** lives in the recording layer (`Transcription/Audio/...`) which this review didn't touch. Nothing in the customizations should interfere.

4. **Local Whisper failover** depends on the existing `whisperModelManager` — not affected by anything in this delta. The TCC permissions reset per-build (ad-hoc resign) will continue to be a daily-driver pain point until the README's Phase 3g (stable self-signed cert) lands.

5. **Privacy nit on the always-keep-on-clipboard behavior.** If Kyle ever dictates into a password field (1Password, Keychain, browser login), the transcript stays on the system clipboard indefinitely until overwritten. The old upstream `restoreClipboardAfterPaste` would have wiped it after the restore delay. Mitigation when chains land: a Power Mode profile bound to `1Password.app` / known credential apps could call a "secure paste" path that uses the transient pasteboard flag (`ClipboardManager.setClipboard(text, transient: true)` and skip the always-paste). Not blocking; flagging for design-time consideration.
