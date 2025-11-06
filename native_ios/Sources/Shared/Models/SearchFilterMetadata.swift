import Foundation

public struct SearchFilterMetadata: Equatable {
    public let cities: [String]
    public let interests: [String]
    public let minAge: Int
    public let maxAge: Int

    public init(cities: [String], interests: [String], minAge: Int, maxAge: Int) {
        self.cities = cities
        self.interests = interests
        self.minAge = minAge
        self.maxAge = maxAge
    }

    public var normalizedCities: [String] {
        cities.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    public var normalizedInterests: [String] {
        interests.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    public static var `default`: SearchFilterMetadata {
        SearchFilterMetadata(
            cities: [
                "Kabul",
                "Herat",
                "Mazar-i-Sharif",
                "Kandahar",
                "Nangarhar",
                "Balkh",
                "Kunduz",
                "Ghazni"
            ],
            interests: [
                "Faith",
                "Family",
                "Education",
                "Cooking",
                "Reading",
                "Travel",
                "Community",
                "Volunteering",
                "Sports",
                "Art"
            ],
            minAge: 18,
            maxAge: 70
        )
    }
}
