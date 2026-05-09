import AppIntents
import Foundation
import AppKit

struct DismissMiniRecorderIntent: AppIntent {
    static var title: LocalizedStringResource = "Dismiss DreamScribe Recorder"
    static var description = IntentDescription("Dismiss the DreamScribe mini recorder and cancel any active recording.")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .dismissMiniRecorder, object: nil)
        
        let dialog = IntentDialog(stringLiteral: "DreamScribe recorder dismissed")
        return .result(dialog: dialog)
    }
}
