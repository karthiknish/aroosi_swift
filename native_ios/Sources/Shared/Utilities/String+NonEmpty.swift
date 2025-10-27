import Foundation

extension String {
    /// Returns the trimmed string when it contains characters, otherwise nil.
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
