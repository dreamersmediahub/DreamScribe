# DreamScribe — customizations vs upstream

Delta from `Beingpax/VoiceInk` upstream commit `cf3ebd2` ("Refine appcast release notes for 1.76"). All changes apply only to the `make local` build path via the `LOCAL_BUILD` compile flag and `LocalBuild.xcconfig` overrides — `make build` / `make all` would still produce upstream-identical VoiceInk.

## Build / identity

| File | Change |
|------|--------|
| `LocalBuild.xcconfig` | Added `PRODUCT_BUNDLE_IDENTIFIER`, `INFOPLIST_KEY_CFBundleDisplayName` overrides |
| `Makefile` | `local` target renames `VoiceInk.app` → `DreamScribe.app`, renames inner binary, updates `CFBundleExecutable` via PlistBuddy, re-codesigns ad-hoc; `run` target prefers `~/Downloads/DreamScribe.app` and falls back to legacy `VoiceInk.app` |
| `.gitignore` | Added `branding/generated/` (build artifacts; `.local-build/` was already ignored upstream) |

## Brand assets

| File | Change |
|------|--------|
| `VoiceInk/Assets.xcassets/AppIcon.appiconset/*.png` | All 7 sizes regenerated as the iridescent D-submark on a dark squircle backplate |
| `VoiceInk/Assets.xcassets/AccentColor.colorset/Contents.json` | Set to ember `#D69466` (was unset / Xcode default) |
| `VoiceInk/Assets.xcassets/DreamersWordmark.imageset/` | **New.** Iridescent DREAMERS wordmark, 1x/2x/3x |
| `VoiceInk/Assets.xcassets/DreamersSubmark.imageset/` | **New.** Iridescent D submark with glow filter, for splash |
| `branding/` | **New folder.** SVG sources + Python rasterization scripts. See README. |

## User-visible text replacements (≈30 strings across 17 files)

Replaced "VoiceInk" with "DreamScribe" in `Text(...)`, `description:`, window titles, App Intents, file dialog titles, dashboard hero copy, etc. Class names, module references, identifier strings (`com.prakashjoshipax.voiceink` subsystems), env-var prefixes (`VOICEINK_*` — runtime contract), and `import VoiceInk` were left alone. See `branding/rebrand-strings.py` for the explicit replacement table.

| File | Notable replacement |
|------|---------------------|
| `VoiceInk/Views/ContentView.swift` | Sidebar header `Text("DreamScribe")`, `navigationTitle("DreamScribe")` |
| `VoiceInk/WindowManager.swift` | Window titles |
| `VoiceInk/HistoryWindowController.swift` | History window title |
| `VoiceInk/Views/Metrics/MetricsContent.swift` | Hero copy "with DreamScribe" + "DreamScribe sessions completed" + heroSubtitle |
| `VoiceInk/Views/Metrics/MetricsSetupView.swift` | "Welcome to DreamScribe", shortcut copy |
| `VoiceInk/Views/Onboarding/*.swift` | Onboarding permission descriptions, tutorial copy |
| `VoiceInk/Views/PermissionsView.swift` | Permission rationale strings |
| `VoiceInk/Views/Settings/SettingsView.swift` | Privacy section description |
| `VoiceInk/Views/Dictionary/*.swift` | Help text + placeholder example |
| `VoiceInk/Services/ImportExportService.swift` | Save/Open panel titles |
| `VoiceInk/AppIntents/*.swift` | Siri / Shortcuts intent titles + descriptions |
| `VoiceInk/PowerMode/PowerModeView.swift` | Power Mode empty state |

## Dashboard hero

`VoiceInk/Views/Metrics/MetricsContent.swift`:
- Added `Image("DreamersWordmark")` at the top of `heroSection` (iridescent wordmark)
- Replaced `heroGradient` from system `controlAccentColor` (which is now ember orange) to a Dreamers ink-palette dark gradient so the iridescent wordmark has contrast
- `LOCAL_BUILD`-gated removal of `HelpAndResourcesSection()` + `DashboardPromotionsSection(...)` (those sections all linked to upstream tryvoiceink.com docs / affiliate program)

## Sidebar / Pro nav

`VoiceInk/Views/ContentView.swift`:
- `case license = "VoiceInk Pro"` wrapped in `#if !LOCAL_BUILD` (along with its icon, navigation handler, and detail-view destination)
- PRO badge in the sidebar header gated under `#if !LOCAL_BUILD`

The upstream license stack (`Models/LicenseViewModel.swift`, `Services/LicenseManager.swift`, `Services/PolarService.swift`, `Views/Components/TrialMessageView.swift`, `Views/LicenseView.swift`, `Views/LicenseManagementView.swift`) is **not deleted** — it stays compiled but its first action is short-circuited by an existing upstream `#if LOCAL_BUILD` branch in `LicenseViewModel.init()` that sets `licenseState = .licensed` immediately, skipping the trial timer / Polar API entirely. This keeps the diff surface small and the upstream-merge story clean.

## Paste behavior

`VoiceInk/CursorPaster.swift`:
- `startPasteAtCursor(_:)` rewritten:
  - Always sets the clipboard to the transcript (non-transient) — survives auto-paste so it can be re-pasted via ⌘V
  - Always posts the ⌘V keystroke (or AppleScript path) regardless of focus
  - **Removed:** the "snapshot prior clipboard, paste, then restore" flow that wiped the transcript ~0.25s after auto-paste
  - **Removed:** the early `hasFocusedTextElement()` AX-role check that produced false negatives in VS Code, Slack, browser web inputs, and most Electron apps (their text inputs don't expose `AXTextField` / `AXTextArea`)

This means the upstream UserDefault `restoreClipboardAfterPaste` is now ignored. Acceptable trade-off because (a) Kyle prefers transcript persistence over clipboard fidelity, and (b) the keystroke is harmless when no field is focused.

## Launch splash

New file `VoiceInk/Views/LaunchSplashView.swift`:
- ZStack overlay shown for ~2.5s on every app launch
- Phase 1 (1.0s): iridescent submark glows in (scale + opacity transition)
- Phase 2 (1.0s): cross-fade to DREAMERS wordmark (opacity + slide-up transition)
- Phase 3 (0.5s): whole splash fades out
- Calls `onComplete` so the app entry can dismiss it

Wired in `VoiceInk/VoiceInk.swift`:
- `@State private var splashFinished = false`
- `WindowGroup { ZStack { ...existing content... ; if !splashFinished { LaunchSplashView { splashFinished = true } } } }`

## Support email

`VoiceInk/EmailSupport.swift`:
- `supportEmailAddress`: `support@tryvoiceink.com` → `support@dreamersmedia.co`
- `supportEmailSubject`: `VoiceInk Support Request` → `DreamScribe Support Request`
- Removed the "Common Issues" link to `tryvoiceink.com/common-issues` from the email body template

## Phase 3g — Signing identity (attempted stable, reverted to ad-hoc)

We tried switching from per-rebuild ad-hoc signing to a stable self-signed cert (would survive TCC trust across rebuilds). Apple's Gatekeeper rejects all non-ad-hoc signed apps without Apple-issued Developer ID certs ($99/yr Developer Program), even when the self-signed cert is added to the system trust store with `codeSign` policy. macOS shows "DreamScribe cannot be opened because of a problem" at launch. `spctl --add` for per-app whitelisting is also deprecated as of recent macOS.

Reverted to ad-hoc signing — it's the only path that Gatekeeper allows for non-paid local builds. Trade-off: each rebuild produces a different binary hash, so macOS TCC asks for permissions again. ~30 sec re-grant per rebuild, acceptable for personal use.

The setup-signing-cert.sh script and the cert-creation flow are kept in `branding/` for future use if a Developer ID is acquired.

| File | Final state |
|------|-------------|
| `branding/setup-signing-cert.sh` | Kept (fixed openssl 3.x compatibility with `-legacy` PKCS#12 flag). Not currently invoked. |
| `LocalBuild.xcconfig` | `CODE_SIGN_IDENTITY = -` (ad-hoc, working state) |
| `Makefile` | xcodebuild flags `CODE_SIGN_IDENTITY="-"` and `CODE_SIGNING_REQUIRED=NO` |

## Phase 3h — Deep VoiceInk → DreamScribe refactor

Filesystem rename (folder + project) handled by `branding/deep-rename.py`:

| Old | New |
|-----|-----|
| `VoiceInk/` (source root) | `DreamScribe/` |
| `VoiceInkTests/` | `DreamScribeTests/` |
| `VoiceInkUITests/` | `DreamScribeUITests/` |
| `VoiceInk.xcodeproj/` | `DreamScribe.xcodeproj/` |
| `xcshareddata/xcschemes/VoiceInk.xcscheme` | `DreamScribe.xcscheme` |

Plus surgical pbxproj patches: target names, productName, group paths, file references, scheme `BlueprintName` / `BuildableName` / `ReferencedContainer`, `INFOPLIST_FILE`, `CODE_SIGN_ENTITLEMENTS`, `DEVELOPMENT_ASSET_PATHS`, `TEST_HOST`. Makefile updated to use `DreamScribe.xcodeproj` / `-scheme DreamScribe`; the post-build rename + executable rename + `codesign --force` dance removed since the target now produces `DreamScribe.app` directly.

Class rename `VoiceInkEngine` → `DreamScribeEngine` (also `VoiceInkEngineError` → `DreamScribeEngineError`) handled by the parallel cleanup agent — files renamed (`Transcription/Engine/DreamScribeEngine.swift` etc.), all references updated across ~25 files, including `preconditionFailure` strings. The Xcode project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+) so file renames auto-sync — no pbxproj surgery needed for this part.

## Phase 3h follow-up — internal identifier migrations with backward-compat

Ran by the second cleanup agent. All identifiers that surface in logs / state / runtime contracts swapped from VoiceInk to DreamScribe, with on-first-launch migration so existing user state survives the rename.

| Category | Change |
|----------|--------|
| **UserDefaults keys** (with backward-compat reads) | `VoiceInkHasLaunchedBefore` → `DreamScribeHasLaunchedBefore` (LicenseViewModel — read-old-then-migrate); `VoiceInkAffiliatePromotionDismissed` → `DreamScribeAffiliatePromotionDismissed` (UserDefaultsManager); `VoiceInkDeviceIdentifier` → `DreamScribeDeviceIdentifier` (Obfuscator) |
| **Logger / DispatchQueue / identifiers** | `com.prakashjoshipax.voiceink` / `com.VoiceInk` / `com.prakashjoshipax.VoiceInk` → `co.dreamersmedia.dreamscribe` across **39 files** including all `Services/`, `Transcription/`, `PowerMode/`, `Views/`, plus `CursorPaster.swift`, `Recorder.swift`, `WindowManager.swift`, `HistoryWindowController.swift`, `HotkeyManager.swift`, `MenuBarManager.swift`, `CoreAudioRecorder.swift`, `DreamScribe.swift` (was `VoiceInk.swift`) |
| **Window autosave** | `VoiceInkMainWindowFrame` / `VoiceInkHistoryWindowFrame` → `DreamScribeMainWindowFrame` / `DreamScribeHistoryWindowFrame`. One-time migration block copies legacy NSWindow frame UserDefaults values to new keys on first launch |
| **Application Support folder** | `~/Library/Application Support/VoiceInk/CustomSounds` → `DreamScribe/CustomSounds`. Migration block moves the old folder if the new one doesn't exist |
| **Internal env var markers** | `__VOICEINK_PATH_START__` / `__VOICEINK_PATH_END__` → `__DREAMSCRIBE_PATH_START__/END__` in `LocalCLIService.swift` |
| **Migration entry point** | `DreamScribe.swift` (the @main app file) — added `runVoiceInkToDreamScribeMigrationIfNeeded()` called from `init()` after `AppDefaults.registerDefaults()`. Gated by a `DreamScribeBrandingMigrationCompleted` flag so it only runs once |

**Out of scope (intentionally untouched, document only):**
- Filesystem paths inside the app's Application Support directory under `com.prakashjoshipax.VoiceInk`
- iCloud container identifier (in entitlements; LOCAL_BUILD disables CloudKit anyway)
- Keychain `service` identifier (would orphan stored API keys if changed without migration)
- Entitlements file names (`VoiceInk.entitlements` / `VoiceInk.local.entitlements` — file-level, not user-visible)
- Info.plist (no VoiceInk literals there now)
- License-stack UserDefaults keys (`VoiceInkLicenseRequiresActivation`, `VoiceInkActivationsLimit` — entire license stack is dead under `LOCAL_BUILD`)
- Public env var contracts (`VOICEINK_SYSTEM_PROMPT` / `VOICEINK_USER_PROMPT` / `VOICEINK_FULL_PROMPT` — documented runtime contract for power-user shell integrations)

## Code-review follow-ups (post-review fixes)

| Area | Change |
|------|--------|
| `VoiceInk/CursorPaster.swift` | Deleted dead helpers `snapshotClipboard(from:)`, `scheduleClipboardRestore(_:on:)`, and the `ClipboardSnapshot` typealias. Trimmed the rationale comment to one line. |
| `VoiceInk/Views/Settings/SettingsView.swift` | Wrapped the orphaned "Restore Clipboard After Paste" + "Restore Delay" UI in `#if !LOCAL_BUILD` so users don't see a toggle that no longer does anything |
| `Makefile` | PlistBuddy step now exits with a clear error if it fails (previously `\|\| true` swallowed failures, which could leave the bundle un-launchable) |
| `VoiceInk/VoiceInk.swift` | Gated `updaterViewModel.silentlyCheckForUpdates()` and the `CheckForUpdatesView` menu under `#if !LOCAL_BUILD` so the upstream Sparkle appcast doesn't surface VoiceInk-branded update prompts inside DreamScribe |
| `VoiceInk/VoiceInk.swift` | Storage-error alert messages: `VoiceInk` → `DreamScribe` (warning + critical alerts) |
| `VoiceInk/Views/PermissionsView.swift` | Two info-tip strings: Accessibility + Screen Recording rationale `VoiceInk` → `DreamScribe` |
| `VoiceInk/Views/Onboarding/OnboardingPermissionsView.swift` | Screen Recording info-tip in the onboarding flow `VoiceInk` → `DreamScribe` |
| `VoiceInk/AppIntents/DismissMiniRecorderIntent.swift` | Siri spoken response `VoiceInk` → `DreamScribe` |
| `VoiceInk/AppIntents/ToggleMiniRecorderIntent.swift` | Siri spoken response + two error descriptions `VoiceInk` → `DreamScribe` |
| `VoiceInk/Views/MetricsView.swift` | Trial banner `TrialMessageView` calls wrapped in `#if !LOCAL_BUILD` for clarity (functionally dead under LOCAL_BUILD already because `LicenseViewModel` short-circuits to `.licensed`) |

## NOT changed (intentionally)

- The `VoiceInk/` source folder name (renaming would touch every line of `project.pbxproj`)
- The Xcode target name (same reason)
- The Logger subsystem identifiers (`com.prakashjoshipax.voiceink`) — internal only, would invalidate any past log queries
- `VoiceInk-Recordings`, `VoiceInkLicenseRequiresActivation`, `VoiceInkHasLaunchedBefore` UserDefaults keys — runtime contract
- `VOICEINK_SYSTEM_PROMPT` / `VOICEINK_USER_PROMPT` / `VOICEINK_FULL_PROMPT` env var names — runtime contract for power-user shell integrations
- "Learn More" doc links to `tryvoiceink.com/docs/...` deep in settings — they still describe the same feature behavior; can be replaced incrementally if needed

## Git remote

```
origin → https://github.com/dreamersmediahub/VoiceInk.git
```

No `upstream` remote configured. `git push` only goes to dreamersmediahub. To rename the GitHub repo to `DreamScribe`, use the GitHub web UI or `gh repo rename DreamScribe --repo dreamersmediahub/VoiceInk` — the URL auto-redirects so the local origin keeps working.
