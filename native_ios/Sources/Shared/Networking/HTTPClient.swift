import Foundation

@available(iOS 17.0.0, *)
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

@available(iOS 17.0.0, *)
public struct HTTPRequest {
    public var path: String
    public var method: HTTPMethod
    public var queryItems: [URLQueryItem]
    public var headers: [String: String]
    public var body: Data?

    public init(path: String,
                method: HTTPMethod = .get,
                queryItems: [URLQueryItem] = [],
                headers: [String: String] = [:],
                body: Data? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}

@available(iOS 17.0.0, *)
public enum HTTPClientError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case statusCode(Int, Data)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Failed to create a valid URL for request: \(value)"
        case .invalidResponse:
            return "Response was not a valid HTTP response."
        case .statusCode(let code, _):
            return "Request failed with status code \(code)."
        }
    }

    var responseData: Data? {
        if case let .statusCode(_, data) = self { return data }
        return nil
    }
}

@available(iOS 17.0.0, *)
public protocol HTTPClientProtocol {
    func data(for request: HTTPRequest) async throws -> (Data, HTTPURLResponse)
}

@available(iOS 17.0.0, *)
public final class DefaultHTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let environment: EnvironmentConfig

    public init(session: URLSession = .shared,
                configProvider: AppConfigProviding = DefaultAppConfigProvider()) throws {
        self.session = session
        self.environment = try configProvider.load().environment
    }

    public func data(for request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = try buildURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HTTPClientError.statusCode(httpResponse.statusCode, data)
        }

        return (data, httpResponse)
    }

    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        guard var components = URLComponents(url: environment.apiBaseURL, resolvingAgainstBaseURL: false) else {
            throw HTTPClientError.invalidURL(environment.apiBaseURL.absoluteString)
        }

        let normalizedPath: String
        if request.path.hasPrefix("/") {
            normalizedPath = environment.apiBaseURL.path + request.path
        } else if environment.apiBaseURL.path.hasSuffix("/") {
            normalizedPath = environment.apiBaseURL.path + request.path
        } else {
            normalizedPath = environment.apiBaseURL.path + "/" + request.path
        }

        components.path = normalizedPath
        components.queryItems = request.queryItems.isEmpty ? nil : request.queryItems

        guard let url = components.url else {
            throw HTTPClientError.invalidURL(components.string ?? request.path)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        var headers = request.headers
        headers["Accept"] = headers["Accept"] ?? "application/json"
        if request.body != nil {
            headers["Content-Type"] = headers["Content-Type"] ?? "application/json"
        }

        headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }
}
