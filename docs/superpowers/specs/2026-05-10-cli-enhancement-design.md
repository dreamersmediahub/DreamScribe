# CLI Enhancement Design

## Goal

DreamScribe should support AI enhancement through authenticated local command-line tools as a first-class alternative to API keys. The feature must preserve the existing enhancement flow: transcription, dictionary/vocabulary support, word replacements, prompt detection, history metadata, and paste behavior should work the same whether the selected provider is an API provider, Ollama, or Local CLI.

## Existing Context

The current branch already includes a partial `Local CLI` provider:

- `AIProvider.localCLI` exists and does not require an API key.
- `LocalCLIService` runs a shell command with prompt data in environment variables and stdin.
- `AIEnhancementService` already routes Local CLI output through `AIEnhancementOutputFilter`.
- `APIKeyManagementView` exposes a command template and timeout field.

The missing work is product hardening: more provider templates, DreamScribe naming, a test command path, clearer UI state, better output filtering, stronger prompt presets, and preservation of dictionary behavior.

## Superwhisper Findings

Superwhisper is installed at `/Applications/superwhisper.app`, bundle id `com.superduper.superwhisper`, version `2.13.1`.

User settings were found at `/Users/dreamers/Library/Mobile Documents/com~apple~CloudDocs/Documents/superwhisper/settings/settings.json`.

Relevant settings:

- `vocabulary` is empty.
- `replacements` contains one entry: `Chrissy` -> `Krissy`.
- Saved modes are `Super`, `Voice to text`, `Note`, `Meeting`, and `Mail`.

Superwhisper's useful behavior is its conservative cleanup prompt style:

- Preserve the original message.
- Only make changes when confident.
- Use vocabulary/names as spelling context only.
- Remove filler words and obvious stutters without changing intent.
- Apply self-corrections.
- Convert spoken URL/email formats.
- Avoid inventing content.

DreamScribe should merge those ideas into its current cleanup behavior, not replace the working DreamScribe behavior. DreamScribe already does a good job of paragraphing, list formatting, cleanup, and preserving spoken intent. The implementation should keep that structure as the base and add Superwhisper's conservatism, filler discipline, self-correction handling, and dictionary caution on top.

## Feature Design

### Local CLI Provider

The Local CLI provider remains an `AIProvider` option. It should provide templates for:

- Codex CLI
- Claude CLI
- Gemini CLI
- Custom shell command

DreamScribe exposes prompt values through both DreamScribe-native and legacy env names:

- `DREAMSCRIBE_SYSTEM_PROMPT`
- `DREAMSCRIBE_USER_PROMPT`
- `DREAMSCRIBE_FULL_PROMPT`
- `VOICEINK_SYSTEM_PROMPT`
- `VOICEINK_USER_PROMPT`
- `VOICEINK_FULL_PROMPT`

Legacy names remain for compatibility with existing saved commands; user-facing UI should describe the DreamScribe names.

Each CLI template must be non-interactive and must return only the model's final answer on stdout. The service should continue writing the full prompt to stdin as a fallback.

### CLI Readiness And Testing

Local CLI should not be considered ready just because the command field is non-empty. The settings UI should expose a "Test CLI" action that runs the configured command with a small deterministic prompt and reports:

- success with a short sample output,
- command not found,
- timeout,
- non-zero exit status with stderr,
- empty output.

This avoids users discovering CLI auth or PATH problems only after dictating.

### Prompt Presets

Predefined prompts should include:

- Clean Dictation
- Ask AI
- AI Prompt
- Feature Ideas
- Email
- Daily Note
- Tasks
- Meeting Notes
- Chat Message

All presets except Ask AI use the transcription-enhancer system wrapper. Ask AI uses a standalone assistant system prompt and is allowed to answer the transcript.

Trigger words should be deliberate phrases so prompt detection does not accidentally fire during normal dictation.

### Dictionary And Replacement Preservation

Existing DreamScribe dictionary behavior remains the source of truth:

- `VocabularyWord` entries continue to feed transcription providers and AI enhancement context.
- `WordReplacement` entries continue to apply after transcription.
- Custom vocabulary in the AI system prompt remains spelling guidance only, not instruction content.

Add a small Superwhisper import/migration helper that imports readable Superwhisper settings once:

- import vocabulary entries if present,
- import replacements if present,
- skip duplicates,
- preserve user-created DreamScribe entries,
- record a UserDefaults flag after a successful import attempt.

Based on the current Superwhisper settings, this imports `Chrissy` -> `Krissy` and no vocabulary words.

### Cleanup And Filtering

Improve filler cleanup with a richer default filler list and safer whitespace/punctuation normalization. This must not flatten DreamScribe's current paragraphing/list behavior. The AI prompt should keep the existing paragraph/list rules and add instructions to remove filler phrases such as "um", "uh", "you know", "I guess", and excessive "like" only when they are discourse filler, while preserving meaningful uses.

AI output filtering should strip common wrapper tags such as `<sw_response_content>` as well as existing reasoning tags. This makes DreamScribe robust when adapting Superwhisper-style prompts or CLI tools that return wrapper tags.

## Testing

Validation must include:

- unit-level checks for CLI prompt construction, env names, output tag filtering, and Superwhisper settings parsing,
- `git diff --check`,
- `make local`,
- `make install`,
- live app QA in `/Applications/DreamScribe.app` covering Enhancement settings, Local CLI templates, prompt grid, dictionary view, and a CLI test for each installed command available on the machine.
