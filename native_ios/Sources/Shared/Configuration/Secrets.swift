import Foundation

public struct Secrets: Equatable {
    public let values: [String: String]

    public init(values: [String: String] = [:]) {
        self.values = values
    }

    public subscript(key: String) -> String? {
        values[key]
    }

    public func string(for key: String) -> String? {
        values[key]
    }

    public func bool(for key: String) -> Bool? {
        guard let value = values[key] else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            return nil
        }
    }
}

public protocol SecretsLoading {
    func load() throws -> Secrets
}

public enum SecretsLoaderError: Error, Equatable {
    case fileNotFound(URL)
    case unreadableFile(URL)
}

@available(iOS 17.0.0, *)
public struct DotenvSecretsLoader: SecretsLoading {
    private enum Constants {
        static let envFileOverride = "AROOSI_ENV_FILE"
        static let envInlineOverride = "AROOSI_ENV_INLINE"
    }

    private let fileURL: URL?
    private let environment: [String: String]
    private let fileManager: FileManager

    public init(fileURL: URL? = nil,
                environment: [String: String] = ProcessInfo.processInfo.environment,
                fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.environment = environment
        self.fileManager = fileManager
    }

    public func load() throws -> Secrets {
        var values: [String: String] = [:]

        if let inline = environment[Constants.envInlineOverride], !inline.isEmpty {
            values.merge(parse(content: inline)) { _, new in new }
        }

        if let url = try resolveFileURL() {
            let data = try readFile(at: url)
            values.merge(parse(content: data)) { _, new in new }
        }

        values.merge(environment) { current, _ in current }
        return Secrets(values: values)
    }

    private func resolveFileURL() throws -> URL? {
        if let explicit = fileURL {
            if fileManager.fileExists(atPath: explicit.path) {
                return explicit
            }
            throw SecretsLoaderError.fileNotFound(explicit)
        }

        if let overridePath = environment[Constants.envFileOverride], !overridePath.isEmpty {
            let overrideURL = URL(fileURLWithPath: overridePath)
            if fileManager.fileExists(atPath: overrideURL.path) {
                return overrideURL
            }
            throw SecretsLoaderError.fileNotFound(overrideURL)
        }

#if SWIFT_PACKAGE
        if let bundleURL = Bundle.module.url(forResource: "App", withExtension: "env") {
            return bundleURL
        }
#endif

        if let bundleURL = Bundle.main.url(forResource: "App", withExtension: "env") {
            return bundleURL
        }

        return nil
    }

    private func readFile(at url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw SecretsLoaderError.unreadableFile(url)
        }
    }

    private func parse(content: String) -> [String: String] {
        var parsed: [String: String] = [:]

        content.split(whereSeparator: { $0.isNewline }).forEach { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { return }

            let components = splitKeyValue(from: line)
            guard let key = components.key else { return }
            guard let value = components.value else {
                parsed[key] = ""
                return
            }
            parsed[key] = value
        }

        return parsed
    }

    private func splitKeyValue(from line: String) -> (key: String?, value: String?) {
        guard let equalsIndex = line.firstIndex(of: "=") else {
            return (nil, nil)
        }

        let keyPart = String(line[..<equalsIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let valuePart = String(line[line.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !keyPart.isEmpty else { return (nil, nil) }

        let cleanedValue: String
        if valuePart.hasPrefix("\"") && valuePart.hasSuffix("\"") && valuePart.count >= 2 {
            cleanedValue = String(valuePart.dropFirst().dropLast())
        } else if let hashIndex = valuePart.firstIndex(of: "#") {
            let trimmed = String(valuePart[..<hashIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            cleanedValue = trimmed
        } else {
            cleanedValue = valuePart
        }

        return (keyPart, cleanedValue)
    }
}
