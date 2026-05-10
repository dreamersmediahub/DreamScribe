import Foundation

struct AIEnhancementOutputFilter {
    static func filter(_ text: String) -> String {
        var processedText = text
        if let responseContentRegex = try? NSRegularExpression(pattern: #"(?s)<sw_response_content>(.*?)</sw_response_content>"#) {
            let range = NSRange(processedText.startIndex..., in: processedText)
            processedText = responseContentRegex.stringByReplacingMatches(
                in: processedText,
                options: [],
                range: range,
                withTemplate: "$1"
            )
        }

        let patterns = [
            #"(?s)<thinking>(.*?)</thinking>"#,
            #"(?s)<think>(.*?)</think>"#,
            #"(?s)<reasoning>(.*?)</reasoning>"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(processedText.startIndex..., in: processedText)
                processedText = regex.stringByReplacingMatches(in: processedText, options: [], range: range, withTemplate: "")
            }
        }
        
        return processedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
