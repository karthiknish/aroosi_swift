import XCTest
@testable import AroosiKit

@available(iOS 15.0, macOS 12.0, *)
final class SecretsLoaderTests: XCTestCase {
    func testLoadsInlineEnvironmentOverride() async throws {
        let inline = "API_KEY=test-key\n# comment\nDEBUG=true"
        let loader = DotenvSecretsLoader(fileURL: nil,
                                         environment: ["AROOSI_ENV_INLINE": inline],
                                         fileManager: .default)

        let secrets = try loader.load()

        XCTAssertEqual(secrets["API_KEY"], "test-key")
        XCTAssertEqual(secrets.bool(for: "DEBUG"), true)
    }

    func testLoadsFromFileWhenSpecified() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let fileURL = tempDirectory.appendingPathComponent(".env")
        try "TOKEN=abc123\nEMPTY_VALUE=\nQUOTED=\"hello world\"".write(to: fileURL, atomically: true, encoding: .utf8)

        let loader = DotenvSecretsLoader(fileURL: fileURL,
                                         environment: [:],
                                         fileManager: .default)

        let secrets = try loader.load()

        XCTAssertEqual(secrets["TOKEN"], "abc123")
        XCTAssertEqual(secrets["EMPTY_VALUE"], "")
        XCTAssertEqual(secrets["QUOTED"], "hello world")
    }

    func testMissingExplicitFileThrows() async throws {
        let fileURL = URL(fileURLWithPath: "/path/to/missing.env")
        let loader = DotenvSecretsLoader(fileURL: fileURL,
                                         environment: [:],
                                         fileManager: .default)

        do {
            _ = try loader.load()
            XCTFail("Expected missing file error")
        } catch SecretsLoaderError.fileNotFound(let url) {
            XCTAssertEqual(url, fileURL)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
