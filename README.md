# DreamScribe

Personal-use macOS dictation app for Kyle / Dreamers Media. Forked from [Beingpax/VoiceInk](https://github.com/Beingpax/VoiceInk) (GPL v3) and rebranded + extended.

The upstream `VoiceInk/` source folder name is preserved to avoid Xcode project surgery — only the user-visible identity (app name, icon, bundle ID, dashboard, splash) is rebranded. The build product is `DreamScribe.app` regardless. The original upstream README is preserved as `README-upstream.md`.

## Identity

- **App name:** DreamScribe
- **Bundle ID:** `co.dreamersmedia.dreamscribe`
- **Brand mark:** iridescent prism D on dark squircle (Dreamers submark)
- **Wordmark:** iridescent DREAMERS letter system (shown in launch splash + dashboard hero)
- **Accent color:** ember `#D69466`
- **Surfaces:** ink palette (`#0a0908` / `#141210` / `#1f1c19`), cream text (`#f2ede4`)

## Daily flow

```bash
cd dm-whisper/dreamscribe

make rebuild      # build + install to /Applications + tccutil reset + relaunch
                  # (one-shot daily-driver flow; asks for sudo password once)
```

After running `make rebuild`, click **Allow** on each macOS permission prompt that fires (Microphone, Accessibility, Input Monitoring).

If your rebuild doesn't change permission-relevant code paths, you may not need a TCC reset — try `make local && make install` first; if dictation works, skip `make permissions`.

### Available targets

| Command | What it does |
|---------|--------------|
| `make local` | Build only. Output to `~/Downloads/DreamScribe.app`. Ad-hoc signed with stable designated requirement. |
| `make install` | Quit running DreamScribe + copy `~/Downloads` build to `/Applications`. |
| `make permissions` | Quit + `sudo tccutil reset` + relaunch. Use if dictation stops working after a rebuild. Asks for sudo password once. |
| `make rebuild` | One-shot: `local` + `install` + `permissions`. The daily-driver flow. |
| `make help` | List all targets. |

### Build internals

The Makefile invokes Xcode with `LocalBuild.xcconfig` overrides:
- `CODE_SIGN_IDENTITY = -` (ad-hoc — Apple's Gatekeeper rejects all non-ad-hoc local builds without a paid Developer ID)
- `PRODUCT_BUNDLE_IDENTIFIER = co.dreamersmedia.dreamscribe`
- `INFOPLIST_KEY_CFBundleDisplayName = DreamScribe`
- `SWIFT_ACTIVE_COMPILATION_CONDITIONS = ... LOCAL_BUILD`

The Xcode target itself produces `DreamScribe.app` directly (no post-build rename needed since the target was renamed during Phase 3h refactor).

After Xcode finishes, the Makefile re-codesigns ad-hoc with a stable designated requirement:

```bash
codesign --force --deep --sign - \
  --identifier "co.dreamersmedia.dreamscribe" \
  --requirements '=designated => identifier "co.dreamersmedia.dreamscribe"'
```

This bundle-ID-only DR (instead of the default cdhash-keyed DR) **may** let TCC trust the new build's identity across rebuilds even though the binary hash changes. Untested across multiple rebuilds — if it works, `make permissions` becomes optional after the first grant.

The `LOCAL_BUILD` Swift compile flag (defined by `make local` only, not by `make build` or upstream Xcode opens) short-circuits the upstream Polar trial / license enforcement (`LicenseViewModel.init()` returns `.licensed` directly) and hides the sidebar Pro tab, Help & Resources, and Affiliate sections.

## Customizations vs upstream

See [CHANGES.md](CHANGES.md) for the full delta. Categories:

1. **Brand identity** — app icon, dashboard wordmark, accent color, support email
2. **User-visible text** — every "VoiceInk" → "DreamScribe" in surfaces Kyle uses (windows, settings, onboarding)
3. **Trial / Pro UI hidden** under `#if !LOCAL_BUILD`
4. **Paste behavior** — `CursorPaster` always leaves the transcript on the clipboard AND always posts ⌘V; previously the clipboard restore wiped the transcript and an Accessibility role check skipped paste in apps like VS Code
5. **Launch splash** — new `LaunchSplashView` overlays the window for ~2.5s on every launch (submark glow → wordmark cross-fade → fade out)

## Repo layout (the parts that matter)

```
dreamscribe/
├── Makefile                    # canonical build; `make rebuild` is the daily-driver target
├── LocalBuild.xcconfig         # ad-hoc signing + DreamScribe bundle ID + display name
├── DreamScribe.xcodeproj/      # Xcode project
├── DreamScribe/                # Swift source root
│   ├── DreamScribe.swift       # @main App entry; splash overlay + identifier migrations wired here
│   ├── CursorPaster.swift      # paste/clipboard behavior (always paste + always keep on clipboard)
│   ├── Transcription/Engine/
│   │   └── DreamScribeEngine.swift  # central engine class (renamed from VoiceInkEngine)
│   ├── Views/
│   │   ├── ContentView.swift           # sidebar (Pro tab gated under !LOCAL_BUILD)
│   │   ├── LaunchSplashView.swift      # ★ new — splash intro animation
│   │   └── Metrics/MetricsContent.swift # dashboard hero (DREAMERS wordmark)
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/         # iridescent D mark, all sizes
│   │   ├── AccentColor.colorset/       # ember (#D69466)
│   │   ├── DreamersSubmark.imageset/   # ★ new (splash D mark with glow)
│   │   └── DreamersWordmark.imageset/  # ★ new (dashboard wordmark)
│   └── …
├── DreamScribeTests/
├── DreamScribeUITests/
├── branding/
│   ├── source/                  # SVG + CSS sources from Dreamers brand handoff
│   ├── generated/               # rsvg-convert output (gitignored)
│   ├── build-icon.py            # generates AppIcon.appiconset
│   ├── build-wordmark.py        # generates DreamersWordmark imageset
│   ├── build-splash-submark.py  # generates DreamersSubmark imageset
│   ├── rebrand-strings.py       # bulk text replacement (idempotent re-run)
│   ├── deep-rename.py           # one-shot folder + pbxproj rename (don't re-run; the rename is done)
│   └── setup-signing-cert.sh    # creates self-signed cert (kept for future Developer ID swap)
├── README.md                    # this file
├── README-upstream.md           # preserved upstream VoiceInk README
├── CHANGES.md                   # full delta vs upstream commit cf3ebd2
└── CODE-REVIEW.md               # post-Phase-3f review (informational; mostly resolved)
```

## Brand asset regeneration

If the source SVGs change, regenerate icons + image sets:

```bash
cd branding
python3 build-icon.py            # AppIcon.appiconset (7 sizes)
python3 build-wordmark.py        # DreamersWordmark imageset (1x/2x/3x)
python3 build-splash-submark.py  # DreamersSubmark imageset (1x/2x/3x)
```

Requires `librsvg` (Homebrew). Source SVGs live in `branding/source/`.

## One-time signing setup

Before the first build, run the cert-setup script — it creates a self-signed code-signing cert in your login keychain so every `make local` signs with the same identity. macOS's TCC keys permissions on (bundle ID + designated requirement), so a stable identity means **permissions persist across rebuilds**.

```bash
bash branding/setup-signing-cert.sh
```

The script will:
- Generate a 4096-bit RSA cert with the `codeSigning` extended key usage (10-year validity)
- Import it into `~/Library/Keychains/login.keychain-db`
- Trust it locally for code signing
- Grant `codesign` non-interactive access to the private key

You will be asked for your macOS user password (for the trust step) and your keychain password (typically empty / same as login). After the script succeeds, verify with:

```bash
security find-identity -v -p codesigning | grep "DreamScribe Self-Signed"
```

`make local` runs `cert-check` automatically and refuses to build if the cert is missing, with instructions to run the setup script.

## Permissions reset — only when switching identities

The first build that uses the new self-signed cert (instead of the prior ad-hoc) will trigger fresh TCC prompts because the designated requirement changes. Run this once after the first rebuild on the new identity:

```bash
for srv in Microphone Accessibility ListenEvent PostEvent ScreenCapture; do
  sudo tccutil reset $srv co.dreamersmedia.dreamscribe
done
```

Quit + relaunch DreamScribe → click Allow on each prompt. **Subsequent rebuilds keep the trust** — no more re-grant dance.

## License

GPL v3 (inherited from VoiceInk upstream). Personal/private use only — no distribution.

## Origin & maintenance posture

GitHub remote: `https://github.com/dreamersmediahub/VoiceInk.git` (the user's fork of Beingpax/VoiceInk). No `upstream` remote configured; `git push` can only target dreamersmediahub. Renaming the GitHub repo to `DreamScribe` is a one-click GitHub action — auto-redirect keeps the local origin URL working.

Kyle is maintaining this codebase fully; **no upstream merges**. The folder structure, target name, class names, and many UserDefaults keys have been renamed (see `CHANGES.md` Phase 3h). Re-pulling from Beingpax/VoiceInk would create thousands of conflicts. If a specific upstream commit is worth porting, cherry-pick the diff manually.
