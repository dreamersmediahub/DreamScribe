# AGENTS.md — DreamScribe

DreamScribe is Kyle's owned, private, native Swift macOS dictation app. Forked from [Beingpax/VoiceInk](https://github.com/Beingpax/VoiceInk) (GPL v3) and renamed/rebranded. **No upstream merges** — Kyle maintains this himself; folders, target, class names, and many UserDefaults keys have been renamed (with backward-compat reads), so re-pulling Beingpax/VoiceInk would create thousands of conflicts.

For the broader project context (other workstreams in `dm-whisper/`), see `../CLAUDE.md`. For full delta-vs-upstream, see [CHANGES.md](CHANGES.md).

## Identity

- **App:** DreamScribe — `/Applications/DreamScribe.app`
- **Bundle ID:** `co.dreamersmedia.dreamscribe`
- **Target / scheme / Xcode project:** all named `DreamScribe`
- **Source root:** `DreamScribe/` (was `VoiceInk/` upstream)
- **Origin remote:** `https://github.com/dreamersmediahub/VoiceInk.git` (no `upstream` configured; pushes can only target dreamersmediahub)

## Build, install, run

Daily-driver flow — from this directory:

```bash
make rebuild       # build + install to /Applications + tccutil reset + relaunch
                   # (one sudo password prompt → click Allow on permission dialogs)
```

Granular targets:

| Command | Effect |
|---------|--------|
| `make local` | Build only. Output to `~/Downloads/DreamScribe.app`. Ad-hoc signed with stable designated requirement. |
| `make install` | Quit running app + copy `~/Downloads` build to `/Applications`. |
| `make permissions` | Quit + `sudo tccutil reset` for DreamScribe + relaunch. Use when dictation stops working after a rebuild. |
| `make rebuild` | One-shot: `local` + `install` + `permissions`. |
| `make clean` | Wipe `.local-build/` and `~/DreamScribe-Dependencies/`. |
| `make help` | List all targets. |

## Signing reality (Phase 3g — settled, do not re-litigate)

- Ad-hoc signing only. `CODE_SIGN_IDENTITY = -` in `LocalBuild.xcconfig`.
- Apple's Gatekeeper rejects all non-ad-hoc signed apps without a paid Developer ID ($99/yr) — confirmed by trying to add a self-signed cert with `security add-trusted-cert -p codeSign`. Launch was blocked. `spctl --add` is deprecated.
- Each rebuild's binary hash differs, so macOS TCC may re-prompt for permissions.
- Mitigation: post-build `codesign --requirements '=designated => identifier "co.dreamersmedia.dreamscribe"'` sets a stable bundle-ID-only DR. **Open question** Kyle is testing: does TCC actually respect this and persist trust? If not, `make permissions` is the fallback.
- The `branding/setup-signing-cert.sh` script is kept for the day Kyle gets a Developer ID — currently unused.

## LOCAL_BUILD compile flag

`make local` defines `LOCAL_BUILD` (in `LocalBuild.xcconfig`'s `SWIFT_ACTIVE_COMPILATION_CONDITIONS`).

The codebase uses `#if LOCAL_BUILD` / `#if !LOCAL_BUILD` to gate:
- Trial / license / Polar API code (auto-disabled — `LicenseViewModel.init()` returns `.licensed` immediately under LOCAL_BUILD)
- Sidebar "VoiceInk Pro" tab + PRO badge
- Dashboard Help & Resources / Affiliate sections
- Settings "Restore Clipboard After Paste" toggle
- Sparkle update checks + AnnouncementsService startup
- CloudKit usage (which needs a paid Developer ID anyway)
- Trial banner on dashboard

Don't introduce new `#if !LOCAL_BUILD` blocks unless the gated code clearly only makes sense for upstream/distribution. Usually you want to delete dead code outright.

## Where things live

```
dreamscribe/
├── Makefile                     # canonical build entry point
├── LocalBuild.xcconfig          # signing + bundle ID + LOCAL_BUILD flag
├── DreamScribe.xcodeproj/       # Xcode project (PBXFileSystemSynchronizedRootGroup — file renames auto-sync)
├── DreamScribe/                 # Swift source root
│   ├── DreamScribe.swift        # @main App; splash overlay + identifier migrations wired here
│   ├── CursorPaster.swift       # paste behavior (always paste + always keep on clipboard)
│   ├── Transcription/Engine/
│   │   └── DreamScribeEngine.swift   # central engine class (renamed from VoiceInkEngine)
│   ├── Views/
│   │   ├── ContentView.swift              # sidebar
│   │   ├── LaunchSplashView.swift         # ★ DreamScribe-specific intro animation
│   │   └── Metrics/MetricsContent.swift   # dashboard hero (DREAMERS wordmark)
│   └── Assets.xcassets/
│       ├── AppIcon.appiconset/            # iridescent D mark, 7 sizes
│       ├── AccentColor.colorset/          # ember #D69466
│       ├── DreamersSubmark.imageset/      # ★ splash D mark
│       └── DreamersWordmark.imageset/     # ★ dashboard wordmark
├── DreamScribeTests/
├── DreamScribeUITests/
├── branding/
│   ├── source/                  # SVG + CSS sources from Dreamers brand handoff
│   ├── generated/               # rsvg-convert output (gitignored)
│   ├── build-icon.py            # regenerates AppIcon.appiconset
│   ├── build-wordmark.py        # regenerates DreamersWordmark imageset
│   ├── build-splash-submark.py  # regenerates DreamersSubmark imageset
│   ├── rebrand-strings.py       # idempotent bulk text replacement
│   ├── deep-rename.py           # one-shot folder + pbxproj rename — DON'T re-run, the rename is done
│   └── setup-signing-cert.sh    # creates self-signed cert (kept for Developer ID future)
├── README.md                    # human-friendly intro + daily flow
├── README-upstream.md           # preserved upstream VoiceInk README
├── CHANGES.md                   # full delta vs upstream cf3ebd2
├── CODE-REVIEW.md               # post-Phase-3f review (informational; addressed)
└── AGENTS.md                    # this file
```

## Identifier migrations (already applied — for context)

A one-time migration block at `DreamScribe.swift:VoiceInkApp.init()` (called `runVoiceInkToDreamScribeMigrationIfNeeded()`, gated by `DreamScribeBrandingMigrationCompleted` UserDefault) handles:

- UserDefaults: `VoiceInkHasLaunchedBefore` → `DreamScribeHasLaunchedBefore`, `VoiceInkAffiliatePromotionDismissed` → `DreamScribeAffiliatePromotionDismissed`, `VoiceInkDeviceIdentifier` → `DreamScribeDeviceIdentifier` (read-old-fall-through-then-migrate pattern)
- Window autosave names: `VoiceInkMainWindowFrame` / `VoiceInkHistoryWindowFrame` → `DreamScribe*` equivalents (frame copy on first launch)
- Application Support: `~/Library/Application Support/VoiceInk/CustomSounds/` → `DreamScribe/CustomSounds/` (folder move on first launch)

Logger subsystems / DispatchQueue labels / UI identifiers all read `co.dreamersmedia.dreamscribe` (39 files migrated). Internal env var markers `__VOICEINK_PATH_*__` → `__DREAMSCRIBE_PATH_*__`.

**Untouched on purpose** (see CHANGES.md "NOT changed" section): public env var contracts (`VOICEINK_SYSTEM_PROMPT`, etc. — runtime contract for power-user shell integrations), license-stack UserDefaults keys (dead code under LOCAL_BUILD), the iCloud container ID (CloudKit disabled under LOCAL_BUILD anyway), the keychain `service` identifier (would orphan stored API keys without migration), entitlements file names (`VoiceInk.entitlements` / `VoiceInk.local.entitlements` — file-level only).

## Things to avoid

- **Pulling upstream** — see top of file. Cherry-pick specific commits manually if a fix is truly worth porting.
- **Deleting the upstream license stack files** (`Models/LicenseViewModel.swift`, `Services/LicenseManager.swift`, `Services/PolarService.swift`, `Views/Components/TrialMessageView.swift`, `Views/LicenseView.swift`, `Views/LicenseManagementView.swift`) — they're gated under `#if !LOCAL_BUILD` and never executed; deletion would touch the Xcode project file with no functional benefit.
- **Re-running `branding/deep-rename.py`** — one-shot script that's already been run. Re-running on the renamed tree is a no-op but the script self-detects.
- **Re-pitching deferred work** — `chains` (Phase 3a), `opus encoding` (3b), `Groq failover` (3e), `Sparkle to our repo` (3i) are all deferred for documented reasons. Only revisit if Kyle explicitly asks.
- **Switching away from ad-hoc signing** — the experiment was done, Gatekeeper kills self-signed without Developer ID.
- **Distributing the binary externally** — GPL v3 inherited from upstream. Private personal use only.

## Coding conventions

- Swift / SwiftUI native macOS app. Target macOS 14.4+.
- File renames inside `DreamScribe/` work transparently — the Xcode project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+), so adding/renaming/deleting Swift files doesn't require pbxproj edits.
- Use `os.Logger(subsystem: "co.dreamersmedia.dreamscribe", category: "...")` for new logging.
- New `#if LOCAL_BUILD` gates only when the alternative branch is for upstream/distribution. For private-only features, just write the code — `LOCAL_BUILD` is always defined for our builds.
- For new UserDefaults keys, prefix with `DreamScribe` (e.g. `DreamScribeFooBar`) — matches the post-migration convention.
- For new asset images, name with the `Dreamers` prefix when brand-related (`DreamersWordmark`, `DreamersSubmark` set the precedent), or descriptive otherwise.

## Brand asset regeneration

If the source SVGs in `branding/source/` change:

```bash
cd branding
python3 build-icon.py            # AppIcon.appiconset (7 sizes)
python3 build-wordmark.py        # DreamersWordmark imageset (1x/2x/3x)
python3 build-splash-submark.py  # DreamersSubmark imageset (1x/2x/3x)
```

Requires `librsvg` (`brew install librsvg`).

## Git workflow (Claude-owned, pre-authorized)

Kyle has delegated git management explicitly. Commits and pushes happen autonomously at logical milestones — don't ask permission per commit.

- **Repo:** [dreamersmediahub/DreamScribe](https://github.com/dreamersmediahub/DreamScribe). Origin remote points there. No `upstream` remote — pushes can only target dreamersmediahub.
- **Commit at milestones:** after a feature/refactor lands and builds, after agent task completes, before ending a session. Never leave a session with uncommitted work.
- **Push immediately after commit.** Don't accumulate local commits across sessions.
- **Repo-local email config** (`262704288+dreamersmediahub@users.noreply.github.com`) is set to dodge GitHub's email-privacy push rejection. Don't change it.
- **Commit messages:** 1–2 sentences explaining *why*, then bullet *what* by category. Trailer: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.
- **Never** force-push to main. **Never** rebase published history. **Never** open PRs back to Beingpax/VoiceInk upstream.
- **Don't proactively** set up GitHub Issues / Releases / Actions / branch protection — out of scope unless asked.

## Phase 4 (the only open work)

Daily-drive DreamScribe for 5 consecutive days as primary dictation. Track friction in a `DAILY-LOG.md` if anything emerges. Decide whether to retire SuperWhisper.
