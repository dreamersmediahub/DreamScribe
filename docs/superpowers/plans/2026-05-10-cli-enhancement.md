# CLI Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reliable Local CLI enhancement option using Codex, Claude, and Gemini session auth, with stronger DreamScribe prompt presets and Superwhisper-inspired cleanup/import behavior.

**Architecture:** Keep the existing enhancement pipeline and provider enum. Harden `LocalCLIService`, expose test/readiness state through `AIService` and `APIKeyManagementView`, expand prompt definitions, and add a one-shot Superwhisper settings importer that seeds DreamScribe dictionary data without overwriting user entries.

**Tech Stack:** Swift, SwiftUI, SwiftData, Xcode project, shell-based CLI execution, existing DreamScribe services.

---

### Task 1: Local CLI Hardening

**Files:**
- Modify: `DreamScribe/Services/AIEnhancement/LocalCLIService.swift`
- Modify: `DreamScribe/Services/AIEnhancement/AIService.swift`

- [ ] Add `gemini` and `custom` cases to `LocalCLITemplate`.
- [ ] Rename user-facing prompt env documentation to `DREAMSCRIBE_*` while continuing to set legacy `VOICEINK_*` env vars.
- [ ] Update command templates:
  - Codex: use `codex exec --skip-git-repo-check --output-last-message`.
  - Claude: use `claude -p "$DREAMSCRIBE_FULL_PROMPT"`.
  - Gemini: use `gemini -p "$DREAMSCRIBE_FULL_PROMPT"`.
- [ ] Add `LocalCLITestResult` and `testConfiguration()` to run the selected command with a small prompt.
- [ ] Add `localCLIDisplayName` and `testLocalCLIConfiguration()` accessors to `AIService`.
- [ ] Keep existing saved command compatibility.

### Task 2: Local CLI Settings UI

**Files:**
- Modify: `DreamScribe/Views/AI Models/APIKeyManagementView.swift`

- [ ] Replace the bare Local CLI command area with a clearer provider panel.
- [ ] Add template menu entries for Codex, Claude, Gemini, and Custom.
- [ ] Add a "Test CLI" button that displays progress, success output, or a clear error.
- [ ] Update helper text to mention `DREAMSCRIBE_SYSTEM_PROMPT`, `DREAMSCRIBE_USER_PROMPT`, and `DREAMSCRIBE_FULL_PROMPT`.
- [ ] Preserve existing Dreamers visual styling.

### Task 3: Prompt Presets And Superwhisper Cleanup Style

**Files:**
- Modify: `DreamScribe/Models/AIPrompts.swift`
- Modify: `DreamScribe/Models/PromptTemplates.swift`
- Modify: `DreamScribe/Models/PredefinedPrompts.swift`

- [ ] Merge conservative Superwhisper-style cleanup into the existing DreamScribe base instructions without removing DreamScribe's current paragraphing, list formatting, smart formatting, and intent-preservation behavior.
- [ ] Add predefined prompts: Clean Dictation, Ask AI, AI Prompt, Feature Ideas, Email, Daily Note, Tasks, Meeting Notes, Chat Message.
- [ ] Give each prompt a useful icon, description, trigger words, and correct `useSystemInstructions` setting.
- [ ] Keep existing UUIDs stable for Default/Clean Dictation and Assistant/Ask AI to preserve selected prompt references.
- [ ] Ensure prompt detection phrases are specific enough to avoid accidental activation.

### Task 4: Dictionary Import And Output Filtering

**Files:**
- Create: `DreamScribe/Services/SuperwhisperImportService.swift`
- Modify: `DreamScribe/Services/DictionaryService.swift`
- Modify: `DreamScribe/Services/AIEnhancement/AIEnhancementOutputFilter.swift`
- Modify: `DreamScribe/Transcription/Processing/FillerWordManager.swift`
- Modify: `DreamScribe/VoiceInk.swift`

- [ ] Add Codable structs for Superwhisper `settings.json`.
- [ ] Add a one-shot importer that reads `/Users/dreamers/Library/Mobile Documents/com~apple~CloudDocs/Documents/superwhisper/settings/settings.json`.
- [ ] Import vocabulary and replacements, skip duplicates, and record a UserDefaults migration flag.
- [ ] Add an explicit helper to import a `SuperwhisperSettings` value for tests.
- [ ] Strip `<sw_response_content>` wrapper tags from AI output.
- [ ] Add richer default filler words and phrases while preserving user-customized filler lists.
- [ ] Call the importer once after the SwiftData container exists.

### Task 5: Verification

**Files:**
- Modify or create focused tests if the current test target imports cleanly.
- No production files unless fixing verification failures.

- [ ] Run `git diff --check`.
- [ ] Run `make local`.
- [ ] Run `make install`.
- [ ] Launch `/Applications/DreamScribe.app`.
- [ ] QA Enhancement settings, Local CLI provider templates, prompt grid, dictionary replacement import, and dark/light contrast.
- [ ] Run CLI tests for installed `codex`, `claude`, and `gemini` if they can complete non-interactively.
- [ ] Commit and push the completed branch.
