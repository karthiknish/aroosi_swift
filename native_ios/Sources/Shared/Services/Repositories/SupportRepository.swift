import Foundation

@available(iOS 17.0.0, *)
public struct SupportContactRequest: Equatable {
    public enum Category: String, CaseIterable {
        case general = "General"
        case technical = "Technical"
        case safety = "Safety"
    }

    public var email: String?
    public var subject: String?
    public var category: Category
    public var message: String
    public var metadata: [String: String]?

    public init(email: String? = nil,
                subject: String? = nil,
                category: Category = .general,
                message: String,
                metadata: [String: String]? = nil) {
        self.email = email
        self.subject = subject
        self.category = category
        self.message = message
        self.metadata = metadata
    }
}

@available(iOS 17.0.0, *)
public protocol SupportRepository {
    func submitContact(_ request: SupportContactRequest) async throws -> Bool
}

#if os(iOS)
#if canImport(FirebaseFirestore)
@available(iOS 17.0.0, macOS 12.0, *)
public final class RemoteSupportRepository: SupportRepository {
    private let client: HTTPClientProtocol
    private let logger = Logger.shared

    public init(client: HTTPClientProtocol? = nil) {
        if let client {
            self.client = client
        } else {
            self.client = try! DefaultHTTPClient()
        }
    }

    public func submitContact(_ request: SupportContactRequest) async throws -> Bool {
        let payloads = buildPayloads(from: request)
        for payload in payloads {
            for path in endpoints {
                do {
                    let body = try JSONSerialization.data(withJSONObject: payload, options: [])
                    let httpRequest = HTTPRequest(
                        path: path,
                        method: .post,
                        headers: ["Content-Type": "application/json"],
                        body: body
                    )
                    let (_, response) = try await client.data(for: httpRequest)
                    if (200..<300).contains(response.statusCode) {
                        return true
                    }
                } catch {
                    if #available(iOS 15.0, macOS 12.0, *), let cancellationError = error as? CancellationError {
                        throw cancellationError
                    }
                    logger.error("Support request to \(path) failed: \(error.localizedDescription)")
                }
            }
        }
        return false
    }

    private var endpoints: [String] {
        [
            "/support/contact",
            "/support",
            "/help/contact",
            "/contact"
        ]
    }

    private func buildPayloads(from request: SupportContactRequest) -> [[String: Any]] {
        var payloads: [[String: Any]] = []
        let metadata = request.metadata ?? [:]

        payloads.append([
            "email": request.email ?? "",
            "subject": request.subject ?? "",
            "category": request.category.rawValue,
            "message": request.message,
            "metadata": metadata
        ].filteringEmptyStrings())

        payloads.append([
            "from": request.email ?? "",
            "title": request.subject ?? "",
            "type": request.category.rawValue,
            "body": request.message,
            "meta": metadata
        ].filteringEmptyStrings())

        payloads.append([
            "userEmail": request.email ?? "",
            "topic": request.subject ?? "",
            "topicCategory": request.category.rawValue,
            "description": request.message,
            "extra": metadata
        ].filteringEmptyStrings())

        return payloads
    }
}

private extension Dictionary where Key == String, Value == Any {
    func filteringEmptyStrings() -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self {
            if let string = value as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    result[key] = trimmed
                }
            } else if let dictionary = value as? [String: Any], !dictionary.isEmpty {
                result[key] = dictionary
            } else if let anyValue = value as? [String], !anyValue.isEmpty {
                result[key] = anyValue
            } else if !(value is String) {
                result[key] = value
            }
        }
        return result
    }
}
#else
@available(iOS 17.0.0, *)
public final class RemoteSupportRepository: SupportRepository {
    public init() {}
    public func submitContact(_ request: SupportContactRequest) async throws -> Bool { false }
}
#endif
#else
@available(iOS 17.0.0, *)
public final class RemoteSupportRepository: SupportRepository {
    public init() {}
    public func submitContact(_ request: SupportContactRequest) async throws -> Bool { false }
}
#endif
