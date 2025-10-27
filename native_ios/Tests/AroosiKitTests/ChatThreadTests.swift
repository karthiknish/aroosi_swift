import XCTest
@testable import AroosiKit

final class ChatThreadTests: XCTestCase {
    func testInitFromDictionarySuccess() {
        let lastActivity = Date(timeIntervalSince1970: 1_700_000_100)
        let lastMessageDate = Date(timeIntervalSince1970: 1_700_000_200)
        let data: [String: Any] = [
            "matchID": "match123",
            "participantIDs": ["userA", "userB"],
            "unreadCount": 3,
            "unreadCounts": ["userA": 0, "userB": 3],
            "lastActivityAt": lastActivity,
            "lastMessage": [
                "authorID": "userA",
                "text": "Hello!",
                "sentAt": lastMessageDate
            ]
        ]

        let thread = ChatThread(id: "thread123", data: data)

        guard let thread else {
            XCTFail("Thread should not be nil")
            return
        }

        XCTAssertEqual(thread.id, "thread123")
        XCTAssertEqual(thread.matchID, "match123")
        XCTAssertEqual(thread.participantIDs, ["userA", "userB"])
        XCTAssertEqual(thread.unreadCount, 3)
        XCTAssertEqual(thread.unreadCounts["userB"], 3)
        XCTAssertEqual(thread.unreadCountForUser("userB"), 3)
        XCTAssertEqual(thread.unreadCountForUser("userA"), 0)
        XCTAssertEqual(thread.lastActivityAt, lastActivity)
        XCTAssertEqual(thread.lastMessage?.authorID, "userA")
        XCTAssertEqual(thread.lastMessage?.sentAt, lastMessageDate)
    }

    func testInitFromDictionaryMissingMatchIDFails() {
        let thread = ChatThread(id: "missingMatch", data: [:])
        XCTAssertNil(thread)
    }

    func testDictionaryRoundTrip() {
        let lastActivity = Date(timeIntervalSince1970: 1_700_000_300)
        let lastMessage = ChatThread.LastMessage(
            authorID: "userA",
            text: "Hello",
            sentAt: Date(timeIntervalSince1970: 1_700_000_400)
        )
        let original = ChatThread(
            id: "threadABC",
            matchID: "matchABC",
            participantIDs: ["userA", "userB"],
            lastMessage: lastMessage,
            unreadCount: 5,
            unreadCounts: ["userA": 1, "userB": 4],
            lastActivityAt: lastActivity
        )

        let dict = original.toDictionary()
        let reconstructed = ChatThread(id: original.id, data: dict)

        XCTAssertNotNil(reconstructed)
        XCTAssertEqual(reconstructed, original)
    }
}
