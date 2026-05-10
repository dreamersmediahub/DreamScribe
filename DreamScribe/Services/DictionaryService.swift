import SwiftData

enum DictionaryService {
    static func normalizedVocabularyWord(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func replacementTokens(from original: String) -> [String] {
        original
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    static func vocabularyWordExists(_ word: String, in existing: [VocabularyWord]) -> Bool {
        let normalizedWord = normalizedVocabularyWord(word)
        return existing.contains { normalizedVocabularyWord($0.word) == normalizedWord }
    }

    static func replacementExists(original: String, in existing: [WordReplacement]) -> Bool {
        let candidateTokens = replacementTokens(from: original)
        guard !candidateTokens.isEmpty else { return true }

        let existingTokens = Set(existing.flatMap { replacementTokens(from: $0.originalText) })
        return candidateTokens.contains(where: existingTokens.contains)
    }

    // MARK: - Vocabulary

    /// Adds one or more comma-separated words to vocabulary.
    /// Returns an error message string if something went wrong, nil on success.
    @discardableResult
    static func addVocabularyWords(
        _ input: String,
        existing: [VocabularyWord],
        context: ModelContext
    ) -> String? {
        let parts = input
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }

        if parts.count == 1, let word = parts.first {
            if vocabularyWordExists(word, in: existing) {
                return "'\(word)' is already in the vocabulary"
            }
            return insertVocabularyWord(word, context: context)
        }

        var addedWords = Set(existing.map { normalizedVocabularyWord($0.word) })
        var errors = [String]()
        for word in parts {
            let lower = normalizedVocabularyWord(word)
            if !addedWords.contains(lower) {
                if let error = insertVocabularyWord(word, context: context) {
                    errors.append(error)
                }
                addedWords.insert(lower)
            }
        }
        return errors.isEmpty ? nil : errors.joined(separator: "; ")
    }

    @discardableResult
    private static func insertVocabularyWord(_ word: String, context: ModelContext) -> String? {
        let entry = VocabularyWord(word: word)
        context.insert(entry)
        do {
            try context.save()
            return nil
        } catch {
            context.delete(entry)
            return "Failed to add '\(word)': \(error.localizedDescription)"
        }
    }

    // MARK: - Word Replacement

    /// Adds a word replacement entry (original may be comma-separated).
    /// Returns an error message string if something went wrong, nil on success.
    @discardableResult
    static func addWordReplacement(
        original: String,
        replacement: String,
        existing: [WordReplacement],
        context: ModelContext
    ) -> String? {
        let tokens = original
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty, !replacement.isEmpty else { return nil }

        if replacementExists(original: original, in: existing) {
            return "'\(tokens.first ?? original)' already exists in word replacements"
        }

        let entry = WordReplacement(originalText: original, replacementText: replacement)
        context.insert(entry)
        do {
            try context.save()
            return nil
        } catch {
            context.delete(entry)
            return "Failed to add replacement: \(error.localizedDescription)"
        }
    }
}
