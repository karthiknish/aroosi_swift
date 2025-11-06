import Foundation

@available(iOS 17.0.0, *)
public protocol CulturalRepository {
    func fetchProfile(userID: String?) async throws -> CulturalProfile?
    func updateProfile(_ profile: CulturalProfile, userID: String?) async throws
    func fetchRecommendations(limit: Int) async throws -> [CulturalRecommendation]
    func fetchCompatibilityReport(primaryUserID: String, targetUserID: String) async throws -> CulturalCompatibilityReport
}

@available(iOS 17.0.0, *)
public final class RemoteCulturalRepository: CulturalRepository {
    private let client: HTTPClientProtocol
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = Logger.shared

    public init(client: HTTPClientProtocol? = nil,
                decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder()) throws {
        if let client {
            self.client = client
        } else {
            #if os(iOS)
            self.client = try DefaultHTTPClient()
            #else
            if #available(macOS 12.0, *) {
                self.client = try DefaultHTTPClient()
            } else {
                throw RepositoryError.unsupportedPlatform
            }
            #endif
        }

        let configuredDecoder = decoder
        configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = configuredDecoder

        let configuredEncoder = encoder
        configuredEncoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = configuredEncoder
    }

    public func fetchProfile(userID: String?) async throws -> CulturalProfile? {
        let path: String
        if let userID, !userID.isEmpty {
            path = "/cultural/profile/\(userID)"
        } else {
            path = "/cultural/profile/me"
        }

        let request = HTTPRequest(path: path)

        do {
            let (data, _) = try await client.data(for: request)
            let envelope = try decoder.decode(CulturalProfileEnvelope.self, from: data)
            guard envelope.success != false else { return nil }
            if let payload = envelope.culturalProfile {
                return payload.toModel()
            }
            return nil
        } catch let error as HTTPClientError {
            if let data = error.responseData {
                logger.error("Cultural profile request failed: \(String(decoding: data, as: UTF8.self))")
            }
            throw error
        } catch {
            logger.error("Failed to decode cultural profile: \(error.localizedDescription)")
            throw error
        }
    }

    public func updateProfile(_ profile: CulturalProfile, userID: String?) async throws {
        let path: String
        if let userID, !userID.isEmpty {
            path = "/cultural/profile/\(userID)"
        } else {
            path = "/cultural/profile/me"
        }

        let payload = CulturalProfilePayload(from: profile)
        let body = try encoder.encode(payload)
        let request = HTTPRequest(path: path,
                                   method: .put,
                                   headers: ["Content-Type": "application/json"],
                                   body: body)
        do {
            _ = try await client.data(for: request)
        } catch let error as HTTPClientError {
            if let data = error.responseData {
                logger.error("Cultural profile update failed: \(String(decoding: data, as: UTF8.self))")
            }
            throw error
        }
    }

    public func fetchRecommendations(limit: Int) async throws -> [CulturalRecommendation] {
        var query: [URLQueryItem] = []
        if limit > 0 {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        let request = HTTPRequest(path: "/cultural/recommendations",
                                   queryItems: query)
        do {
            let (data, _) = try await client.data(for: request)
            let envelope = try decoder.decode(CulturalRecommendationsEnvelope.self, from: data)
            guard envelope.success != false else { return [] }
            return envelope.recommendations?.compactMap { $0.toModel() } ?? []
        } catch let error as HTTPClientError {
            if let data = error.responseData {
                logger.error("Cultural recommendations request failed: \(String(decoding: data, as: UTF8.self))")
            }
            throw error
        } catch {
            logger.error("Failed to decode cultural recommendations: \(error.localizedDescription)")
            throw error
        }
    }

    public func fetchCompatibilityReport(primaryUserID: String, targetUserID: String) async throws -> CulturalCompatibilityReport {
        let request = HTTPRequest(path: "/cultural/compatibility/\(primaryUserID)/\(targetUserID)")

        do {
            let (data, _) = try await client.data(for: request)
            let envelope = try decoder.decode(CulturalCompatibilityEnvelope.self, from: data)
            guard envelope.success != false else {
                throw RepositoryError.unknown
            }
            return envelope.toModel()
        } catch let error as HTTPClientError {
            if let data = error.responseData {
                logger.error("Cultural compatibility request failed: \(String(decoding: data, as: UTF8.self))")
            }
            throw error
        } catch {
            logger.error("Failed to decode cultural compatibility: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 17.0.0, *)
private struct CulturalProfileEnvelope: Decodable {
    let success: Bool?
    let culturalProfile: CulturalProfilePayload?
}

@available(iOS 17.0.0, *)
private struct CulturalProfilePayload: Codable {
    let religion: String?
    let religiousPractice: String?
    let motherTongue: String?
    let languages: [String]?
    let familyValues: String?
    let marriageViews: String?
    let traditionalValues: String?
    let familyApprovalImportance: String?
    let religionImportance: Int?
    let cultureImportance: Int?
    let familyBackground: String?
    let ethnicity: String?

    init(from profile: CulturalProfile) {
        self.religion = profile.religion
        self.religiousPractice = profile.religiousPractice
        self.motherTongue = profile.motherTongue
        self.languages = profile.languages
        self.familyValues = profile.familyValues
        self.marriageViews = profile.marriageViews
        self.traditionalValues = profile.traditionalValues
        self.familyApprovalImportance = profile.familyApprovalImportance
        self.religionImportance = profile.religionImportance
        self.cultureImportance = profile.cultureImportance
        self.familyBackground = profile.familyBackground
        self.ethnicity = profile.ethnicity
    }

    func toModel() -> CulturalProfile {
        CulturalProfile(
            religion: religion,
            religiousPractice: religiousPractice,
            motherTongue: motherTongue,
            languages: languages ?? [],
            familyValues: familyValues,
            marriageViews: marriageViews,
            traditionalValues: traditionalValues,
            familyApprovalImportance: familyApprovalImportance,
            religionImportance: religionImportance ?? 5,
            cultureImportance: cultureImportance ?? 5,
            familyBackground: familyBackground,
            ethnicity: ethnicity
        )
    }
}

@available(iOS 17.0.0, *)
private struct CulturalRecommendationsEnvelope: Decodable {
    let success: Bool?
    let recommendations: [RecommendationPayload]?

    struct RecommendationPayload: Decodable {
        struct ProfilePayload: Decodable {
            let fullName: String?
            let displayName: String?
            let age: Int?
            let city: String?
            let location: String?
            let profileImageUrls: [String]?
            let avatarUrl: String?
            let interests: [String]?
        }

        let userId: String?
        let id: String?
        let compatibilityScore: Int?
        let compatibilityBreakdown: [String: Int]?
        let matchingFactors: [String]?
        let culturalHighlights: [String]?
        let profile: ProfilePayload?
        let profileImageUrls: [String]?
        let avatarUrl: String?
        let fullName: String?
        let age: Int?
        let city: String?

        func toModel() -> CulturalRecommendation? {
            let identifier = userId ?? id
            guard let identifier, !identifier.isEmpty else { return nil }

            let payloadName = profile?.fullName ?? profile?.displayName ?? fullName
            let displayName = payloadName?.nonEmpty ?? "Member"
            let score = compatibilityScore ?? 0

            let avatarString = profile?.profileImageUrls?.first
                ?? profileImageUrls?.first
                ?? profile?.avatarUrl
                ?? avatarUrl

            let summary = ProfileSummary(
                id: identifier,
                displayName: displayName,
                age: profile?.age ?? age,
                location: profile?.city ?? city ?? profile?.location,
                bio: nil,
                avatarURL: avatarString.flatMap(URL.init(string:)),
                interests: profile?.interests ?? []
            )

            let breakdown = computeBreakdown(from: compatibilityBreakdown, score: score)

            return CulturalRecommendation(
                id: identifier,
                profile: summary,
                compatibilityScore: score,
                breakdown: breakdown,
                matchingFactors: matchingFactors ?? [],
                culturalHighlights: culturalHighlights ?? []
            )
        }

        private func computeBreakdown(from values: [String: Int]?, score: Int) -> CulturalRecommendation.CompatibilityBreakdown {
            if let values {
                let religionScore = values["religion"] ?? values["religious"] ?? 0
                let languageScore = values["language"] ?? 0
                let valuesScore = values["values"] ?? values["tradition"] ?? 0
                let familyScore = values["family"] ?? 0
                return CulturalRecommendation.CompatibilityBreakdown(
                    religion: clamp(religionScore),
                    language: clamp(languageScore),
                    values: clamp(valuesScore),
                    family: clamp(familyScore)
                )
            }

            let normalized = max(score, 0)
            let religionScore = Int((Double(normalized) * 0.4).rounded())
            let languageScore = Int((Double(normalized) * 0.2).rounded())
            let valuesScore = Int((Double(normalized) * 0.25).rounded())
            let familyScore = Int((Double(normalized) * 0.15).rounded())

            return CulturalRecommendation.CompatibilityBreakdown(
                religion: clamp(religionScore),
                language: clamp(languageScore),
                values: clamp(valuesScore),
                family: clamp(familyScore)
            )
        }

        private func clamp(_ value: Int) -> Int {
            max(0, min(100, value))
        }
    }
}

@available(iOS 17.0.0, *)
private struct CulturalCompatibilityEnvelope: Decodable {
    let success: Bool?
    let score: Int?
    let insights: [String]?
    let compatibility: [String: CompatibilityDimension]?

    struct CompatibilityDimension: Decodable {
        let label: String?
        let score: Int?
        let description: String?
    }

    func toModel() -> CulturalCompatibilityReport {
        let overall = score ?? 0
        let insightList = insights ?? []
        let dimensions = (compatibility ?? [:]).map { key, value in
            CulturalCompatibilityReport.Dimension(
                key: key,
                label: value.label ?? key.capitalized,
                score: max(0, min(100, value.score ?? 0)),
                description: value.description
            )
        }
        .sorted(by: { $0.score > $1.score })

        return CulturalCompatibilityReport(
            overallScore: max(0, min(100, overall)),
            insights: insightList,
            dimensions: dimensions
        )
    }
}
