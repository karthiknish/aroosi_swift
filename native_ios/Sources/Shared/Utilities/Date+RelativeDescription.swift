import Foundation

@available(iOS 15.0, *)
private enum RelativeDateFormatterCache {
    static let shared: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}

@available(iOS 15.0, *)
public extension Date {
    func relativeDescription(relativeTo reference: Date = .now,
                             unitsStyle: RelativeDateTimeFormatter.UnitsStyle = .full) -> String {
        let formatter = RelativeDateFormatterCache.shared
        if formatter.unitsStyle != unitsStyle {
            formatter.unitsStyle = unitsStyle
        }
        return formatter.localizedString(for: self, relativeTo: reference)
    }
}
