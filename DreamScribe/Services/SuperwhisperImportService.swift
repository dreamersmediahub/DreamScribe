import Foundation
import SwiftData

@MainActor
final class SuperwhisperImportService {
    static let shared = SuperwhisperImportService()

    private let settingsURL = URL(
        fileURLWithPath: "/Users/dreamers/Library/Mobile Documents/com~apple~CloudDocs/Documents/superwhisper/settings/settings.json"
    )
    private let importFlagKey = "SuperwhisperSettingsImported"

    struct SuperwhisperSettings: Codable {
        let vocabulary: [String]
        let replacements: [Replacement]

        struct Replacement: Codable {
            let id: String?
            let original: String
            let `with`: String

            private enum CodingKeys: String, CodingKey {
                case id
                case original
                case `with`
            }
        }
    }

    struct ImportResult {
        enum Status {
            case imported
            case alreadyImported
            case missingSettings
            case decodeFailed
            case saveFailed
        }

        let status: Status
        let insertedVocabularyWords: Int
        let insertedReplacements: Int
        let skippedVocabularyWords: Int
        let skippedReplacements: Int
    }

    private init() {}

    func importIfNeeded(context: ModelContext) -> ImportResult {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: importFlagKey) else {
            return ImportResult(
                status: .alreadyImported,
                insertedVocabularyWords: 0,
                insertedReplacements: 0,
                skippedVocabularyWords: 0,
                skippedReplacements: 0
            )
        }

        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return ImportResult(
                status: .missingSettings,
                insertedVocabularyWords: 0,
                insertedReplacements: 0,
                skippedVocabularyWords: 0,
                skippedReplacements: 0
            )
        }

        do {
            let data = try Data(contentsOf: settingsURL)
            let settings = try JSONDecoder().decode(SuperwhisperSettings.self, from: data)
            let result = Self.importSettings(settings, context: context)
            guard result.status != .saveFailed else { return result }
            defaults.set(true, forKey: importFlagKey)
            return result
        } catch {
            return ImportResult(
                status: .decodeFailed,
                insertedVocabularyWords: 0,
                insertedReplacements: 0,
                skippedVocabularyWords: 0,
                skippedReplacements: 0
            )
        }
    }

    static func importSettings(_ settings: SuperwhisperSettings, context: ModelContext) -> ImportResult {
        let existingVocabularyWords = (try? context.fetch(FetchDescriptor<VocabularyWord>())) ?? []
        let existingReplacements = (try? context.fetch(FetchDescriptor<WordReplacement>())) ?? []

        var insertedVocabularyWords = 0
        var insertedReplacements = 0
        var skippedVocabularyWords = 0
        var skippedReplacements = 0

        var vocabularyLookup = Set(existingVocabularyWords.map { DictionaryService.normalizedVocabularyWord($0.word) })
        for word in settings.vocabulary {
            let normalized = DictionaryService.normalizedVocabularyWord(word)
            guard !normalized.isEmpty else { continue }
            guard !vocabularyLookup.contains(normalized) else {
                skippedVocabularyWords += 1
                continue
            }

            context.insert(VocabularyWord(word: word.trimmingCharacters(in: .whitespacesAndNewlines)))
            vocabularyLookup.insert(normalized)
            insertedVocabularyWords += 1
        }

        var replacementLookup = Set(existingReplacements.flatMap { DictionaryService.replacementTokens(from: $0.originalText) })

        for replacement in settings.replacements {
            let original = replacement.original.trimmingCharacters(in: .whitespacesAndNewlines)
            let replacementText = replacement.with.trimmingCharacters(in: .whitespacesAndNewlines)
            let tokens = DictionaryService.replacementTokens(from: original)

            guard !tokens.isEmpty, !replacementText.isEmpty else { continue }

            let hasConflict = tokens.contains(where: replacementLookup.contains)
            guard !hasConflict else {
                skippedReplacements += 1
                continue
            }

            context.insert(WordReplacement(originalText: original, replacementText: replacementText))
            replacementLookup.formUnion(tokens)
            insertedReplacements += 1
        }

        if insertedVocabularyWords > 0 || insertedReplacements > 0 {
            do {
                try context.save()
            } catch {
                context.rollback()
                return ImportResult(
                    status: .saveFailed,
                    insertedVocabularyWords: 0,
                    insertedReplacements: 0,
                    skippedVocabularyWords: skippedVocabularyWords,
                    skippedReplacements: skippedReplacements
                )
            }
        }

        return ImportResult(
            status: .imported,
            insertedVocabularyWords: insertedVocabularyWords,
            insertedReplacements: insertedReplacements,
            skippedVocabularyWords: skippedVocabularyWords,
            skippedReplacements: skippedReplacements
        )
    }
}
