import Foundation

@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
public enum QuickPickAction: String {
    case like
    case skip
}

@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
public struct QuickPickRecommendation: Identifiable, Equatable {
    public let id: String
    public let profile: ProfileSummary
    public let createdAt: Date?

    public init(id: String, profile: ProfileSummary, createdAt: Date? = nil) {
        self.id = id
        self.profile = profile
        self.createdAt = createdAt
    }
}

@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
public protocol QuickPicksRepository {
    func fetchQuickPicks(dayKey: String?) async throws -> [QuickPickRecommendation]
    func act(on userID: String, action: QuickPickAction) async throws
    func fetchCompatibilityScore(for userID: String) async throws -> Int
}

@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
public final class RemoteQuickPicksRepository: QuickPicksRepository {
    private let client: HTTPClientProtocol
    private let decoder: JSONDecoder
    private let cache: CacheStore?
    private let logger = Logger.shared

    public init(client: HTTPClientProtocol? = nil,
                decoder: JSONDecoder = JSONDecoder(),
                cache: CacheStore? = nil) throws {
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
        configuredDecoder.dateDecodingStrategy = .iso8601WithMilliseconds
        self.decoder = configuredDecoder
        if let cache {
            self.cache = cache
        } else {
            #if os(iOS)
            self.cache = DiskCacheStore(name: "quick-picks", expiration: 60 * 15)
            #else
            self.cache = nil
            #endif
        }
    }

    public func fetchQuickPicks(dayKey: String?) async throws -> [QuickPickRecommendation] {
        var queryItems: [URLQueryItem] = []
        if let dayKey, !dayKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems = [URLQueryItem(name: "day", value: dayKey)]
        }

        let request = HTTPRequest(path: "/engagement/quick-picks",
                                   method: .get,
                                   queryItems: queryItems)
        let cacheKey = cacheKey(for: dayKey)

        do {
            let (data, _) = try await client.data(for: request)
            cache?.setValue(data, forKey: cacheKey)
            let envelope = try decoder.decode(QuickPicksEnvelope.self, from: data)
            return envelope.recommendations()
        } catch let error as HTTPClientError {
            if let data = error.responseData {
                logger.error("Quick picks request failed with status error: \(String(decoding: data, as: UTF8.self))")
            }
            if let cachedData = cache?.value(forKey: cacheKey),
               let envelope = try? decoder.decode(QuickPicksEnvelope.self, from: cachedData) {
                logger.info("Returning cached quick picks due to network error: \(error.localizedDescription)")
                return envelope.recommendations()
            }
            throw error
        } catch {
            logger.error("Failed to decode quick picks: \(error.localizedDescription)")
            if let cachedData = cache?.value(forKey: cacheKey),
               let envelope = try? decoder.decode(QuickPicksEnvelope.self, from: cachedData) {
                logger.info("Returning cached quick picks due to decoding error: \(error.localizedDescription)")
                return envelope.recommendations()
            }
            throw error
        }
    }

    public func act(on userID: String, action: QuickPickAction) async throws {
        guard let body = try? JSONEncoder().encode(ActionPayload(toUserId: userID, action: action.rawValue)) else {
            throw RepositoryError.invalidData
        }

        let request = HTTPRequest(path: "/engagement/quick-picks",
                                   method: .post,
                                   headers: ["Content-Type": "application/json"],
                                   body: body)

        _ = try await client.data(for: request)
        cache?.removeAll()
    }

    private func cacheKey(for dayKey: String?) -> String {
        let trimmed = dayKey?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed?.isEmpty == false ? "day_\(trimmed!)" : "default"
    }

    public func fetchCompatibilityScore(for userID: String) async throws -> Int {
        let request = HTTPRequest(path: "/compatibility/\(userID)")
        do {
            let (data, _) = try await client.data(for: request)
            let response = try decoder.decode(CompatibilityEnvelope.self, from: data)
            return response.score ?? 0
        } catch {
            logger.error("Failed to fetch compatibility score for \(userID): \(error.localizedDescription)")
            throw error
        }
    }

    private struct ActionPayload: Encodable {
        let toUserId: String
        let action: String

        enum CodingKeys: String, CodingKey {
            case toUserId = "toUserId"
            case action
        }
    }
}

@available(iOS 17.0, macOS 10.15, macCatalyst 13.0, *)
private struct QuickPicksEnvelope: Decodable {
    struct DataContainer: Decodable {
        let profiles: [QuickPickItem]?
    }

    struct QuickPickItem: Decodable {
        struct ProfilePayload: Decodable {
            let fullName: String?
            let displayName: String?
            let profileImageUrls: [String]?
            let avatarUrl: String?
            let city: String?
            let location: String?
            let interests: [String]?
            let dateOfBirth: String?

            enum CodingKeys: String, CodingKey {
                case fullName
                case displayName
                case profileImageUrls
                case avatarUrl
                case city
                case location
                case interests
                case dateOfBirth
            }
        }

        let userId: String?
        let id: String?
        let profile: ProfilePayload?
        let createdAt: Int?
        let profileImageUrls: [String]?
        let avatarUrl: String?
        let city: String?
        let dateOfBirth: String?

        enum CodingKeys: String, CodingKey {
            case userId
            case id
            case profile
            case createdAt
            case profileImageUrls
            case avatarUrl
            case city
            case dateOfBirth
        }

        func toRecommendation() -> QuickPickRecommendation? {
            let identifier = userId ?? id
            guard let identifier, !identifier.isEmpty else { return nil }

            let payload = profile
            let displayName = payload?.fullName ?? payload?.displayName ?? ""
            let avatar = payload?.profileImageUrls?.first
                ?? profileImageUrls?.first
                ?? payload?.avatarUrl
                ?? avatarUrl

            let mapped = ProfileSummary(
                id: identifier,
                displayName: displayName.isEmpty ? "Member" : displayName,
                age: Self.computeAge(from: payload?.dateOfBirth ?? dateOfBirth),
                location: payload?.city ?? city ?? payload?.location,
                bio: nil,
                avatarURL: avatar.flatMap(URL.init(string:)),
                interests: payload?.interests ?? []
            )

            let createdAtDate: Date?
            if let createdAt {
                createdAtDate = Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000)
            } else {
                createdAtDate = nil
            }

            return QuickPickRecommendation(id: identifier, profile: mapped, createdAt: createdAtDate)
        }

        private static func computeAge(from dateString: String?) -> Int? {
            guard let value = dateString, !value.isEmpty else { return nil }
            let formats = ["yyyy-MM-dd", "yyyy/MM/dd", "yyyy-MM-dd'T'HH:mm:ssXXXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"]
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")

            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: value) {
                    return date.age
                }
            }
            return nil
        }
    }

    let success: Bool?
    let data: DataContainer?

    func recommendations() -> [QuickPickRecommendation] {
        guard success != false else { return [] }
        return data?.profiles?.compactMap { $0.toRecommendation() } ?? []
    }
}

@available(iOS 17.0.0, *)
private struct CompatibilityEnvelope: Decodable {
    struct DataContainer: Decodable {
        let score: Int?
    }

    let success: Bool?
    let data: DataContainer?

    var score: Int? {
        guard success != false else { return nil }
        return data?.score
    }
}

private extension DateFormatter {
    static let iso8601Milliseconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private extension Date {
    var age: Int {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self, to: now)
        return max(components.year ?? 0, 0)
    }
}

@available(iOS 17.0.0, *)
private extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithMilliseconds: JSONDecoder.DateDecodingStrategy {
        .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = DateFormatter.iso8601Milliseconds.date(from: value) {
                return date
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(value)")
        }
    }
}
