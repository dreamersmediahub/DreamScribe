# DreamScribe UI Overhaul Design

Date: 2026-05-09
Workspace: `/Users/dreamers/Documents/DM-CoWork/dm-whisper/dreamscribe/.worktrees/dreamers-ui-overhaul`
Branch: `feature/dreamers-ui-overhaul`

## Summary

DreamScribe will receive a full native macOS UI overhaul using the Dreamers Media mood-board system, not a generic dark editorial theme. The approved direction is **Creator Studio**: an expandable, creator-facing studio tool that still behaves like a fast utility app.

The product identity direction is **DREAMScribe** with the **S/star hinge**:

- `DREAM` carries the Dreamers parent-brand chrome-prism serif DNA.
- `S` belongs to both `DREAMS` and `Scribe`, becoming the product signature.
- The star/glint sits on or near the `S` as the controlled Dreamers mark detail.
- Audio/wave motifs support the UI and motion system but do not replace the Dreamers-led wordmark.

## Goals

- Make DreamScribe feel like a real Dreamers Media product, not a forked app with light rebranding.
- Apply the full Dreamers brand system across the app shell, dashboard, recorder panels, settings, models, history, dictionary, permissions, onboarding, splash, and shared components.
- Preserve native macOS utility: dense, readable, keyboard-friendly, and fast to scan.
- Create a product identity that can expand into future audio and podcast-generation workflows.
- Build a reusable SwiftUI design layer so future screens inherit the brand rather than reimplementing one-off styling.

## Non-Goals

- No podcast-generation feature in this phase.
- No behavior changes to transcription, model management, history storage, permissions, or app settings.
- No new licensing/distribution work.
- No raw image-generation logo as the final product mark. Image generation may be used only for atmospheric texture studies or concept support; production identity assets should be derived from the existing Dreamers vector system.

## Brand Direction

Use the Dreamers Media mood-board system:

- Luminous sky-blue atmosphere, moving from midnight navy through dream blue into periwinkle haze.
- Chrome-prism identity moments with pearl, silver, and restrained cyan/pink/violet refraction.
- Existing Dreamers D/submark and wordmark DNA remain the parent-brand anchor.
- The Dreamers star/glint is consistent and controlled. It appears as a brand signature, not random sparkle decoration.
- Typography combines an elegant editorial serif for brand/display moments, clean native sans for controls, and narrow uppercase labels for metadata.
- Motion feels like a cinematic title sequence: slow prism shifts, soft reveals, glints, and subtle waveform/pulse motion.

Avoid:

- Generic dark audio-app logos.
- Standalone microphone, podcast, waveform, or S logos detached from Dreamers.
- Overly dark 3D HUD styling.
- Purple-gradient SaaS UI.
- Heavy glassmorphism and large rounded cards.
- Decorative sparkles that do not map to the Dreamers star/glint system.

## Identity System

### Primary Product Wordmark

The product lockup should be built around:

```text
DREAMScribe
```

Construction:

- `DREAM` uses the parent Dreamers chrome-prism serif treatment.
- The shared `S` is the hinge: visually more distinctive than the rest of `Scribe`, with a controlled star/glint detail.
- `cribe` can be softer and more signature-like, but must still feel premium and readable at app sizes.

### Parent Brand Placement

Dreamers Media should remain visible but secondary:

- Splash end frame.
- Dashboard/studio footer.
- Settings/About footer.
- Optional sidebar footer or low-emphasis brand mark.

### App Icon Direction

The app icon should start from Dreamers DNA, not a new audio mark:

- Preferred base: Dreamers D/submark form or DREAMScribe S-hinge form.
- The S/star can be the product-signature detail if it remains visibly inside the Dreamers chrome-prism language.
- Audio may appear as a very subtle pulse, horizon line, or light reflection, not the main symbol.
- Final icon assets should be produced deterministically from source vectors/raster scripts and exported through the existing asset pipeline.

## UI Architecture

Add a Dreamers-native design layer rather than scattering colors and gradients through each screen.

Proposed modules:

- `DreamersTheme`: color tokens, gradients, radii, shadows, typography helpers, animation timings.
- `DreamersAtmosphere`: reusable sky-blue background with restrained grain/glow/prism accents and reduced-motion handling.
- `ChromePanel`: low-radius panel/card surface replacing the current 16px frosted glass cards.
- `DreamersSectionHeader`: uppercase mono label plus compact title/subtitle pattern.
- `DREAMScribeLockup`: local product wordmark component for splash, dashboard, sidebar, and previews.
- `DreamersFooterMark`: low-emphasis parent-brand footer component.
- `PrismButtonStyle` and `ChromeIconButtonStyle`: shared button treatments.
- `RecorderSurfaceStyle`: shared visual rules for mini/notch recorder panels.

All new styling should prefer low-radius panels, fine chrome dividers, and controlled prism highlights. Existing native controls should remain native where they are clearer than custom controls.

## Screen Design

### App Shell

Replace the default-feeling sidebar/header with a branded studio shell:

- Sidebar uses DreamScribe/DREAMScribe identity at the top and Dreamers Media footer at the bottom.
- Navigation uses compact rows with icon, label, and subtle prism active state.
- Detail content sits on a Dreamers atmosphere background instead of plain `windowBackgroundColor`.
- Keep the split-view behavior and current tab structure.

### Dashboard

Move from a generic metrics page into a creator studio home:

- Hero uses the DREAMScribe lockup, not only the Dreamers parent wordmark.
- Metrics remain prominent but are presented as editorial studio panels.
- Use sky-blue atmosphere with chrome dividers and restrained glow.
- Include future-safe space for studio updates or future podcast/audio workflows without implementing those workflows now.

### Recorder Panels

Mini and notch recorder surfaces should become the strongest “living product” moment:

- Dark enough for contrast, but with chrome/prism edge light instead of flat black.
- Subtle audio pulse/wave motion is appropriate here.
- Status, prompt, and power-mode controls stay compact and immediately legible.
- Respect reduced motion.

### Settings And Secondary Tabs

Settings, models, history, dictionary, permissions, audio input, enhancement, and power mode should share the same surface language:

- Replace inherited frosted cards with `ChromePanel` where custom panels are already used.
- Preserve native controls such as toggles, segmented pickers, lists, forms, and keyboard shortcut recorders.
- Use section headers, fine dividers, and compact layout rather than oversized marketing panels.
- Keep text dense and functional.

### Onboarding And Splash

Splash should become the first high-confidence brand moment:

- Use DREAMScribe lockup and the S/star hinge.
- Background should be sky-blue/periwinkle atmospheric rather than brown/black ink.
- Reveal animation: D/DREAMScribe mark, star glint, then wordmark settle.

Onboarding should inherit the same background and panel system, but must remain clear and permission-focused.

## Motion

Motion is part of the brand but must not reduce utility:

- One-shot splash reveal.
- Soft hover blooms on primary controls.
- Slow prism shimmer only on brand lockups or active states.
- Recorder pulse/wave animation only while recording/transcribing.
- Support `accessibilityReduceMotion` by disabling shimmer, glints, and continuous pulse.

## Data Flow

The overhaul is presentation-only.

- No model, transcription, history, settings, or service data flow changes.
- Views continue to consume existing environment objects and app storage keys.
- Theme components receive state through normal SwiftUI props.
- Recorder visual state continues to derive from `RecorderStateProvider` and `Recorder`.

## Error Handling

Existing app error handling remains unchanged. UI changes should not hide or reinterpret operational errors.

Visual states to preserve:

- Loading metrics.
- Empty history/metrics states.
- Permission missing states.
- Model download/progress/error states.
- Recorder recording/transcribing/enhancing/idle states.

New brand components should provide sensible fallback rendering if custom images fail to load.

## Testing And Verification

Baseline already verified:

- `make local` passed in the isolated worktree before design work.

Implementation verification should include:

- `make local` after styling work.
- Manual launch from the worktree build output.
- Visual review of: splash, dashboard, sidebar, settings, models, history, dictionary, permissions, onboarding, mini recorder, notch recorder.
- Reduced-motion review for splash/recorder/hover animations.
- Light/dark behavior review if any adaptive system colors remain.
- Text clipping review at the current minimum app size.

## Implementation Phases

1. Create theme primitives and shared Dreamers components.
2. Implement DREAMScribe identity components and update splash/dashboard/sidebar usage.
3. Redesign the app shell and dashboard.
4. Apply shared `ChromePanel`/section/header/button styling across secondary tabs.
5. Redesign mini and notch recorder surfaces.
6. Update app icon/brand asset pipeline from source vectors.
7. Run build and visual QA, then refine clipping, contrast, and reduced-motion issues.

## Implementation Notes

- The final DREAMScribe wordmark needs production treatment from vector/source assets. Browser and imagegen mockups are directional only.
- The S/star hinge should be tested at small sizes before committing it to the app icon.
- The UI should be allowed to feel studio-like, but not so editorial that repeated daily settings/history workflows slow down.
