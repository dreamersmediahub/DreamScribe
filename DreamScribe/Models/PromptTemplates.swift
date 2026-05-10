import Foundation

struct TemplatePrompt: Identifiable {
    let id: UUID
    let title: String
    let promptText: String
    let icon: PromptIcon
    let description: String
    let triggerWords: [String]
    let useSystemInstructions: Bool
    
    func toCustomPrompt(id: UUID = UUID()) -> CustomPrompt {
        CustomPrompt(
            id: id,
            title: title,
            promptText: promptText,
            icon: icon,
            description: description,
            isPredefined: false,
            triggerWords: triggerWords,
            useSystemInstructions: useSystemInstructions
        )
    }
}

enum PromptTemplates {
    static var all: [TemplatePrompt] {
        createTemplatePrompts()
    }
    
    
    static func createTemplatePrompts() -> [TemplatePrompt] {
        [
            TemplatePrompt(
                id: PredefinedPrompts.defaultPromptId,
                title: "Clean Dictation",
                promptText: """
                    - Clean up the <TRANSCRIPT> for clarity and natural flow while preserving meaning, tone, and intent.
                    - Keep the original paragraphing and list structure when it already reads well; improve it only when the transcript clearly needs it.
                    - Fix grammar, spelling, punctuation, and capitalization only when you are confident the correction is right.
                    - Apply self-corrections and restarts by removing the mistaken wording and keeping the corrected version.
                    - Remove filler words, stutters, and repeated fragments only when they are clearly filler.
                    - Respect spoken formatting cues like "new line" and "new paragraph."
                    - Automatically format lists when the transcript clearly indicates steps, counts, or items.
                    - Apply smart formatting for numbers, dates, times, measurements, abbreviations, emails, URLs, and other spoken details.
                    - Keep the original intent and nuance.
                    - Never invent, summarize, explain, or expand the message.
                    - Output only the cleaned text.
                    """,
                icon: "checkmark.seal.fill",
                description: "Conservative cleanup for plain dictation",
                triggerWords: ["clean dictation", "dictation cleanup", "clean this dictation"],
                useSystemInstructions: true
            ),
            TemplatePrompt(
                id: PredefinedPrompts.assistantPromptId,
                title: "Ask AI",
                promptText: AIPrompts.assistantMode,
                icon: "bubble.left.and.bubble.right.fill",
                description: "Direct answers for spoken questions",
                triggerWords: ["ask ai", "ai answer", "talk to ai"],
                useSystemInstructions: false
            ),
            
            TemplatePrompt(
                id: PredefinedPrompts.aiPromptId,
                title: "AI Prompt",
                promptText: """
                    - Turn the transcript into a polished prompt for an AI assistant.
                    - Keep the user's intent, constraints, and desired outcome explicit.
                    - Add structure only when it is obvious from the transcript or context.
                    - Keep it concise, specific, and ready to paste.
                    - Never invent requirements or examples.
                    - Output only the prompt text.
                    """,
                icon: "curlybraces",
                description: "Turns dictation into a ready-to-use AI prompt",
                triggerWords: ["ai prompt", "draft ai prompt", "prompt for ai"],
                useSystemInstructions: true
            ),
            TemplatePrompt(
                id: PredefinedPrompts.featureIdeasPromptId,
                title: "Feature Ideas",
                promptText: """
                    - Organize the transcript into concrete feature ideas.
                    - Preserve the user's intent and group related ideas together.
                    - Prefer practical, actionable wording over vague brainstorming language.
                    - Surface benefits, risks, and follow-up questions only when they are implied by the transcript.
                    - Keep the output concise and well structured.
                    - Do not invent roadmap details or product context.
                    - Output only the feature ideas.
                    """,
                icon: "lightbulb.fill",
                description: "Structures product and feature brainstorming",
                triggerWords: ["feature ideas", "product ideas", "brainstorm features"],
                useSystemInstructions: true
            ),
            TemplatePrompt(
                id: PredefinedPrompts.emailPromptId,
                title: "Email",
                promptText: """
                    - Rewrite the transcript as a complete email with a greeting, body, and closing.
                    - Match the tone implied by the transcript, but keep it clear and professional enough to send.
                    - Keep names, dates, facts, requests, and action items intact.
                    - Use paragraphs and lists where they help readability.
                    - Do not invent new details or claims.
                    - Output only the email body.
                    """,
                icon: "envelope.fill",
                description: "Drafts a sendable email from dictation",
                triggerWords: ["email draft", "compose email", "write email"],
                useSystemInstructions: true
            ),
            TemplatePrompt(
                id: PredefinedPrompts.dailyNotePromptId,
                title: "Daily Note",
                promptText: """
                    - Turn the transcript into a concise daily note.
                    - Keep the original facts, names, dates, and follow-ups.
                    - Organize the note into short sections only when the transcript suggests them.
                    - Use clean paragraphs and bullets for readability.
                    - Do not invent context, mood, or extra details.
                    - Output only the note text.
                    """,
                icon: "calendar",
                description: "Turns dictation into a daily note",
                triggerWords: ["daily note", "journal note", "daily journal"],
                useSystemInstructions: true
            ),
            TemplatePrompt(
                id: PredefinedPrompts.tasksPromptId,
                title: "Tasks",
                promptText: """
                    - Extract actionable tasks from the transcript.
                    - Keep each task concrete, short, and easy to scan.
                    - Preserve owners, due dates, priorities, and dependencies when they are spoken.
                    - Group related tasks together when that improves clarity.
                    - Do not add tasks that were not stated or clearly implied.
                    - Output only the task list.
                    """,
                icon: "checkmark.circle.fill",
                description: "Converts speech into actionable tasks",
                triggerWords: ["task list", "to-do list", "capture tasks"],
                useSystemInstructions: true
            ),
            TemplatePrompt(
                id: PredefinedPrompts.meetingNotesPromptId,
                title: "Meeting Notes",
                promptText: """
                    - Organize the transcript into structured meeting notes.
                    - Preserve decisions, action items, blockers, and key discussion points.
                    - Use short headings or bullets only when they help readability.
                    - Keep the notes factual and avoid inventing meeting context.
                    - Output only the meeting notes.
                    """,
                icon: "person.2.fill",
                description: "Structures spoken notes into meeting notes",
                triggerWords: ["meeting notes", "meeting summary", "meeting minutes"],
                useSystemInstructions: true
            ),
            TemplatePrompt(
                id: PredefinedPrompts.chatMessagePromptId,
                title: "Chat Message",
                promptText: """
                    - Rewrite the transcript as a short chat message.
                    - Keep it casual, natural, and concise.
                    - Preserve the original tone, but do not add greetings or sign-offs.
                    - Keep emojis and emotive language only if they are already present.
                    - Output only the chat message.
                    """,
                icon: "message.fill",
                description: "Formats dictation as a natural chat message",
                triggerWords: ["chat message", "slack message", "message draft"],
                useSystemInstructions: true
            )
        ]
    }
}
