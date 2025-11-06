import Foundation

@available(iOS 17.0.0, *)
public protocol SearchMetadataRepository {
    func fetchMetadata() async throws -> SearchFilterMetadata
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreSearchMetadataRepository: SearchMetadataRepository {
    private enum Constants {
        static let candidates: [(collection: String, document: String)] = [
            ("metadata", "search_filters"),
            ("search_metadata", "filters"),
            ("app_metadata", "search_filters"),
            ("meta", "search_filters")
        ]
        static let citiesField = "cities"
        static let interestsField = "interests"
        static let minAgeField = "minAge"
        static let maxAgeField = "maxAge"
        static let ageRangeField = "ageRange"
        static let ageRangeMinField = "min"
        static let ageRangeMaxField = "max"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchMetadata() async throws -> SearchFilterMetadata {
        for candidate in Constants.candidates {
            do {
                let snapshot = try await db.collection(candidate.collection).document(candidate.document).getDocument()
                if snapshot.exists {
                    return makeMetadata(from: snapshot.data() ?? [:])
                }
            } catch {
                logger.info("Failed to fetch search metadata from \(candidate.collection)/\(candidate.document): \(error.localizedDescription)")
                continue
            }
        }

        logger.info("Falling back to default search metadata")
        return .default
    }

    private func makeMetadata(from data: [String: Any]) -> SearchFilterMetadata {
        let cities = data[Constants.citiesField] as? [String] ?? []
        let interests = data[Constants.interestsField] as? [String] ?? []

        var minAge = data[Constants.minAgeField] as? Int
        var maxAge = data[Constants.maxAgeField] as? Int

        if let range = data[Constants.ageRangeField] as? [String: Any] {
            if let min = range[Constants.ageRangeMinField] as? Int { minAge = min }
            if let max = range[Constants.ageRangeMaxField] as? Int { maxAge = max }
        }

        let resolvedMinAge = minAge ?? SearchFilterMetadata.default.minAge
        let resolvedMaxAge = maxAge ?? SearchFilterMetadata.default.maxAge

        let metadata = SearchFilterMetadata(
            cities: cities.isEmpty ? SearchFilterMetadata.default.cities : cities,
            interests: interests.isEmpty ? SearchFilterMetadata.default.interests : interests,
            minAge: resolvedMinAge,
            maxAge: resolvedMaxAge
        )

        return SearchFilterMetadata(
            cities: metadata.normalizedCities,
            interests: metadata.normalizedInterests,
            minAge: max(metadata.minAge, 18),
            maxAge: max(metadata.maxAge, metadata.minAge + 1)
        )
    }
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreSearchMetadataRepository: SearchMetadataRepository {
    public init() {}

    public func fetchMetadata() async throws -> SearchFilterMetadata {
        .default
    }
}
#endif
