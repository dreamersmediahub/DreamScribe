# DreamScribe UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved Creator Studio full-app redesign with the DREAMScribe S/star hinge identity.

**Architecture:** Add a shared Dreamers design layer first, then update independent UI surfaces against those components. The coding phase is split into disjoint work areas so parallel workers can safely implement shell/dashboard, recorder surfaces, and secondary screens without editing the same files.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, AppKit-backed macOS panels, Xcode project with PBX file-system synchronized root group, existing `make local` build flow.

---

## Source Documents

- Design spec: `docs/superpowers/specs/2026-05-09-dreamscribe-ui-overhaul-design.md`
- Brand system: `/Users/dreamers/Documents/Codex/dreamers-media-brand-system/dreamers-media-design-tokens.json`
- Brand guidelines: `/Users/dreamers/Documents/Codex/dreamers-media-brand-system/dreamers-media-brand-guidelines.md`
- Current worktree: `/Users/dreamers/Documents/DM-CoWork/dm-whisper/dreamscribe/.worktrees/dreamers-ui-overhaul`

## File Ownership

### Controller-Owned Foundation

- Create: `DreamScribe/Views/Branding/DreamersTheme.swift`
- Create: `DreamScribe/Views/Branding/DreamersBrandComponents.swift`
- Modify: `DreamScribe/Views/Common/CardBackground.swift`

### Worker A: Shell, Splash, Dashboard

- Modify: `DreamScribe/Views/ContentView.swift`
- Modify: `DreamScribe/Views/LaunchSplashView.swift`
- Modify: `DreamScribe/Views/Metrics/MetricsContent.swift`
- Modify: `DreamScribe/Views/Metrics/MetricCard.swift`

### Worker B: Recorder Surfaces

- Modify: `DreamScribe/Views/Recorder/MiniRecorderView.swift`
- Modify: `DreamScribe/Views/Recorder/NotchRecorderView.swift`
- Modify: `DreamScribe/Views/Recorder/RecorderComponents.swift`
- Modify: `DreamScribe/Views/Recorder/AudioVisualizerView.swift`

### Worker C: Secondary Screens

- Modify: `DreamScribe/Views/AudioTranscribeView.swift`
- Modify: `DreamScribe/Views/AI Models/ModelManagementView.swift`
- Modify: `DreamScribe/Views/History/InlineHistoryView.swift`
- Modify: `DreamScribe/Views/Dictionary/DictionarySettingsView.swift`
- Modify: `DreamScribe/Views/PermissionsView.swift`
- Modify: `DreamScribe/Views/EnhancementSettingsView.swift`
- Modify: `DreamScribe/PowerMode/PowerModeView.swift`

### Worker D: Asset Pipeline and Icon Direction

- Modify: `branding/source/dreamers-tokens.css`
- Modify: `branding/build-icon.py`
- Modify: `branding/build-wordmark.py`
- Modify: `branding/build-splash-submark.py`
- Create if useful: `branding/source/dreamscribe-wordmark.svg`
- Create if useful: `branding/build-dreamscribe-wordmark.py`
- Modify generated assets only through scripts.

## Task 1: Foundation Theme And Brand Components

**Files:**
- Create: `DreamScribe/Views/Branding/DreamersTheme.swift`
- Create: `DreamScribe/Views/Branding/DreamersBrandComponents.swift`
- Modify: `DreamScribe/Views/Common/CardBackground.swift`

- [ ] **Step 1: Create the Dreamers theme tokens**

Create `DreamScribe/Views/Branding/DreamersTheme.swift` with `enum DreamersTheme` containing the exact brand colors from the design tokens, low radii, atmosphere gradients, chrome/prism gradients, and shared animation constants.

- [ ] **Step 2: Create reusable brand components**

Create `DreamScribe/Views/Branding/DreamersBrandComponents.swift` with `DreamersAtmosphere`, `DREAMScribeLockup`, `DreamersFooterMark`, `DreamersSectionHeader`, `ChromePanel`, `ChromeIconButtonStyle`, and `PrismButtonStyle`.

- [ ] **Step 3: Replace legacy card constants**

Update `DreamScribe/Views/Common/CardBackground.swift` so existing model cards inherit 8px chrome-panel styling instead of 16px frosted glass. Keep the `CardBackground` API intact.

- [ ] **Step 4: Build**

Run: `make local`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

Commit message:

```bash
git commit -m "Add Dreamers design foundation"
```

## Task 2: Shell, Splash, And Dashboard

**Files:**
- Modify: `DreamScribe/Views/ContentView.swift`
- Modify: `DreamScribe/Views/LaunchSplashView.swift`
- Modify: `DreamScribe/Views/Metrics/MetricsContent.swift`
- Modify: `DreamScribe/Views/Metrics/MetricCard.swift`

- [ ] **Step 1: Update the sidebar shell**

Use `DreamersAtmosphere`, `DREAMScribeLockup`, and `DreamersFooterMark` in `ContentView`. Preserve `NavigationSplitView`, `ViewType`, selection behavior, notification navigation, and `powerModeUIFlag`.

- [ ] **Step 2: Update splash**

Use the sky-blue atmosphere and DREAMScribe identity. Keep the existing `onComplete` timing contract and a simple two-stage reveal.

- [ ] **Step 3: Update dashboard**

Make `MetricsContent` a Creator Studio dashboard: DREAMScribe hero, chrome metrics panels, future-safe studio note space, and Dreamers Media footer. Preserve metric loading and calculations.

- [ ] **Step 4: Update metric cards**

Use `ChromePanel`, low-radius icon containers, and Dreamers prism accent colors. Preserve the current `MetricCard` initializer.

- [ ] **Step 5: Build**

Run: `make local`

Expected: `** BUILD SUCCEEDED **`

## Task 3: Recorder Surfaces

**Files:**
- Modify: `DreamScribe/Views/Recorder/MiniRecorderView.swift`
- Modify: `DreamScribe/Views/Recorder/NotchRecorderView.swift`
- Modify: `DreamScribe/Views/Recorder/RecorderComponents.swift`
- Modify: `DreamScribe/Views/Recorder/AudioVisualizerView.swift`

- [ ] **Step 1: Update mini recorder**

Replace flat black with a Dreamers chrome/prism recorder surface. Preserve dimensions, live transcript expansion, controls, and `windowManager.isVisible` behavior.

- [ ] **Step 2: Update notch recorder**

Apply the same surface styling to the notch pill while preserving `NotchShape`, screen geometry, display states, and animations.

- [ ] **Step 3: Update recorder controls**

Style status, prompt, power-mode, and visualizer pieces with Dreamers colors and reduced-motion-safe pulse behavior. Do not change recording state semantics.

- [ ] **Step 4: Build**

Run: `make local`

Expected: `** BUILD SUCCEEDED **`

## Task 4: Secondary Screens

**Files:**
- Modify: `DreamScribe/Views/AudioTranscribeView.swift`
- Modify: `DreamScribe/Views/AI Models/ModelManagementView.swift`
- Modify: `DreamScribe/Views/History/InlineHistoryView.swift`
- Modify: `DreamScribe/Views/Dictionary/DictionarySettingsView.swift`
- Modify: `DreamScribe/Views/PermissionsView.swift`
- Modify: `DreamScribe/Views/EnhancementSettingsView.swift`
- Modify: `DreamScribe/PowerMode/PowerModeView.swift`

- [ ] **Step 1: Apply atmosphere backgrounds**

Replace root `controlBackgroundColor` fills with `DreamersAtmosphere` where the screen owns its own root background.

- [ ] **Step 2: Replace custom cards**

Use `ChromePanel` and `DreamersSectionHeader` on major custom panels and empty states. Preserve native `Form`, `Toggle`, `Picker`, `KeyboardShortcuts.Recorder`, list, and alert behavior.

- [ ] **Step 3: Update action styling**

Apply `PrismButtonStyle` only to primary actions and `ChromeIconButtonStyle` to icon buttons where it improves consistency. Keep destructive buttons visibly destructive.

- [ ] **Step 4: Build**

Run: `make local`

Expected: `** BUILD SUCCEEDED **`

## Task 5: Brand Asset Pipeline

**Files:**
- Modify: `branding/source/dreamers-tokens.css`
- Modify: `branding/build-icon.py`
- Modify: `branding/build-wordmark.py`
- Modify: `branding/build-splash-submark.py`
- Create if useful: `branding/source/dreamscribe-wordmark.svg`
- Create if useful: `branding/build-dreamscribe-wordmark.py`

- [ ] **Step 1: Inspect existing scripts**

Read the current branding scripts and keep their dependencies and output paths intact.

- [ ] **Step 2: Add DREAMScribe asset source**

Add a source asset for the DREAMScribe wordmark direction if it can be done with deterministic SVG. Use the S/star hinge direction from the spec.

- [ ] **Step 3: Regenerate assets**

Run relevant scripts from `branding/` and confirm generated assets land in `DreamScribe/Assets.xcassets`.

- [ ] **Step 4: Build**

Run: `make local`

Expected: `** BUILD SUCCEEDED **`

## Task 6: Final Integration And Verification

**Files:**
- Any files touched by prior tasks.

- [ ] **Step 1: Review git diff**

Run: `git diff --stat` and inspect touched files for accidental generated noise or unrelated changes.

- [ ] **Step 2: Full build**

Run: `make local`

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Launch local app**

Run: `open ~/Downloads/DreamScribe.app`

Expected: app opens and shows the redesigned splash and main shell.

- [ ] **Step 4: Manual visual QA**

Check splash, dashboard, sidebar, settings, models, history, dictionary, permissions, audio transcribe, enhancement, power mode, mini recorder, and notch recorder for clipping, unreadable contrast, layout jumps, and broken controls.

- [ ] **Step 5: Commit and push**

Commit all integrated implementation work and push `feature/dreamers-ui-overhaul`.
