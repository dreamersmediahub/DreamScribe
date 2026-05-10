import Foundation
import SwiftUI    // Import to ensure we have access to SwiftUI types if needed

enum PredefinedPrompts {
    private static let predefinedPromptsKey = "PredefinedPrompts"
    
    // Static UUIDs for predefined prompts
    static let defaultPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let assistantPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let aiPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let featureIdeasPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    static let emailPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    static let dailyNotePromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
    static let tasksPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
    static let meetingNotesPromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    static let chatMessagePromptId = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!
    
    static var all: [CustomPrompt] {
        // Always return the latest predefined prompts from source code
        createDefaultPrompts()
    }
    
    static func createDefaultPrompts() -> [CustomPrompt] {
        PromptTemplates.all.map { template in
            CustomPrompt(
                id: template.id,
                title: template.title,
                promptText: template.promptText,
                icon: template.icon,
                description: template.description,
                isPredefined: true,
                triggerWords: template.triggerWords,
                useSystemInstructions: template.useSystemInstructions
            )
        }
    }
}
