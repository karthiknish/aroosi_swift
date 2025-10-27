import XCTest
import Foundation
@testable import AroosiKit

// MARK: - XCTestCase Extensions

extension XCTestCase {
    
    /// Wait for an async condition to be true with timeout
    func waitForAsyncCondition(
        condition: @escaping () async -> Bool,
        timeout: TimeInterval = 5.0,
        description: String = "Async condition"
    ) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        XCTFail("Condition '\(description)' not met within \(timeout) seconds")
    }
    
    /// Create expectation for async operations
    func createAsyncExpectation(description: String = "Async operation") -> XCTestExpectation {
        return expectation(description: description)
    }
    
    /// Fulfill expectation after async operation
    func fulfillAsync<T>(
        expectation: XCTestExpectation,
        operation: @escaping () async throws -> T
    ) async rethrows -> T {
        let result = try await operation()
        expectation.fulfill()
        return result
    }
    
    /// Assert that two arrays are equal regardless of order
    func assertArraysEqual<T: Equatable>(
        _ array1: [T],
        _ array2: [T],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(array1.sorted(), array2.sorted(), file: file, line: line)
    }
    
    /// Assert that a date is within a specified range
    func assertDate(
        _ date: Date,
        isWithin range: ClosedRange<Date>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(range.contains(date), "Date \(date) is not within range \(range)", file: file, line: line)
    }
    
    /// Assert that a date is within specified seconds of now
    func assertDateIsRecent(
        _ date: Date,
        withinSeconds seconds: TimeInterval = 5.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let now = Date()
        let range = now.addingTimeInterval(-seconds)...now.addingTimeInterval(seconds)
        assertDate(date, isWithin: range, file: file, line: line)
    }
}

// MARK: - Model Extensions for Testing

extension UserProfile {
    func matches(_ other: UserProfile) -> Bool {
        return id == other.id &&
               displayName == other.displayName &&
               email == other.email &&
               avatarURL == other.avatarURL
    }
}

extension ProfileSummary {
    func matches(_ other: ProfileSummary) -> Bool {
        return id == other.id &&
               displayName == other.displayName &&
               age == other.age &&
               location == other.location &&
               bio == other.bio &&
               interests.sorted() == other.interests.sorted()
    }
}

extension ChatMessage {
    func matches(_ other: ChatMessage) -> Bool {
        return id == other.id &&
               conversationID == other.conversationID &&
               authorID == other.authorID &&
               text == other.text &&
               sentAt == other.sentAt
    }
    
    func isFromCurrentUser(currentUserID: String) -> Bool {
        return authorID == currentUserID
    }
    
    func sentAtFormatted() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sentAt)
    }
}

extension Match {
    func hasParticipant(userID: String) -> Bool {
        return participants.contains { $0.userID == userID }
    }
    
    func getCounterpartUserID(for userID: String) -> String? {
        return participants.first { $0.userID != userID }?.userID
    }
}

extension DashboardInfo {
    func hasUnreadMessages() -> Bool {
        return unreadMessagesCount > 0
    }
    
    func hasActiveMatches() -> Bool {
        return activeMatchesCount > 0
    }
}

extension UserSettings {
    func isNotificationsEnabled() -> Bool {
        return pushNotificationsEnabled || emailNotificationsEnabled
    }
}

extension FamilyApprovalRequest {
    func isPending() -> Bool {
        return status == .pending
    }
    
    func isApproved() -> Bool {
        return status == .approved
    }
    
    func isRejected() -> Bool {
        return status == .rejected
    }
}

extension CompatibilityReport {
    func getCategoryScore(_ category: String) -> Int? {
        return categoryScores[category]
    }
    
    func hasHighCompatibility() -> Bool {
        return overallScore >= 80
    }
}

// MARK: - Mock Result Helpers

enum MockResult<T> {
    case success(T)
    case failure(Error)
    
    var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

// MARK: - Test Utilities

class TestUtilities {
    
    /// Create a temporary directory for test files
    static func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }
    
    /// Clean up temporary directory
    static func cleanupTempDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// Generate random string for testing
    static func randomString(length: Int = 10) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Generate random email for testing
    static func randomEmail() -> String {
        return "\(randomString())@example.com"
    }
    
    /// Generate random phone number for testing
    static func randomPhoneNumber() -> String {
        return "+1\(String(format: "%03d", Int.random(in: 100...999)))\(String(format: "%03d", Int.random(in: 100...999)))\(String(format: "%04d", Int.random(in: 1000...9999)))"
    }
    
    /// Create test image data
    static func createTestImageData(size: CGSize = CGSize(width: 100, height: 100)) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
    
    /// Measure execution time of an operation
    static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeInterval = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeInterval)
    }
    
    /// Measure execution time of an async operation
    static func measureTime<T>(operation: () async throws -> T) async rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let timeInterval = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeInterval)
    }
}

// MARK: - Performance Testing Helpers

extension XCTestCase {
    
    /// Measure performance of a block
    func measurePerformance(
        block: () throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) rethrows {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTStorageMetric(), XCTMemoryMetric()], block: {
            try block()
        })
    }
    
    /// Measure async performance
    func measureAsyncPerformance(
        block: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async rethrows {
        let expectation = expectation(description: "Async performance measurement")
        
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTStorageMetric(), XCTMemoryMetric()]) {
            Task {
                try! await block()
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
}

// MARK: - Assertion Helpers

extension XCTestCase {
    
    /// Assert that an async operation throws a specific error
    func assertThrowsError<T>(
        _ expression: @autoclosure () async throws -> T,
        _ errorHandler: (_ error: Error) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error but none was thrown", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
    
    /// Assert that an async operation doesn't throw
    func assertNoThrow<T>(
        _ expression: @autoclosure () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
        } catch {
            XCTFail("Unexpected error thrown: \(error)", file: file, line: line)
        }
    }
    
    /// Assert that two arrays contain the same elements (order doesn't matter)
    func assertContainsSameElements<T: Equatable>(
        _ array1: [T],
        _ array2: [T],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(array1.count, array2.count, "Arrays have different counts", file: file, line: line)
        for element in array1 {
            XCTAssertTrue(array2.contains(element), "Array 2 doesn't contain element: \(element)", file: file, line: line)
        }
    }
}

// MARK: - Memory Management Helpers

extension XCTestCase {
    
    /// Test for memory leaks in a block
    func testForMemoryLeaks(
        block: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        weak var weakReference: AnyObject?
        
        autoreleasepool {
            let object = NSObject()
            weakReference = object
            block()
        }
        
        XCTAssertNil(weakReference, "Memory leak detected", file: file, line: line)
    }
    
    /// Test for memory leaks in async block
    func testForMemoryLeaks(
        block: () async -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        weak var weakReference: AnyObject?
        
        await autoreleasepool {
            let object = NSObject()
            weakReference = object
            await block()
        }
        
        XCTAssertNil(weakReference, "Memory leak detected", file: file, line: line)
    }
}
