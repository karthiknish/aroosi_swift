import XCTest
@testable import AroosiKit

final class MatchTests: XCTestCase {
    func testInitFromDictionarySuccess() {
        let lastUpdated = Date(timeIntervalSince1970: 1_700_000_000)
        let data: [String: Any] = [
            "status": "active",
            "lastMessagePreview": "Hey there",
            "lastUpdatedAt": lastUpdated,
            "conversationId": "conversation-1",
            "participants": [
                "userA": ["isInitiator": true],
                "userB": ["isInitiator": false]
            ]
        ]

        let match = Match(id: "match123", data: data)

        XCTAssertNotNil(match)
        XCTAssertEqual(match?.id, "match123")
        XCTAssertEqual(match?.status, .active)
        XCTAssertEqual(match?.lastMessagePreview, "Hey there")
        XCTAssertEqual(match?.participantIDs.sorted(), ["userA", "userB"])
        XCTAssertEqual(match?.participants.first(where: { $0.userID == "userA" })?.isInitiator, true)
        XCTAssertEqual(match?.lastUpdatedAt, lastUpdated)
        XCTAssertEqual(match?.conversationID, "conversation-1")
    }

    func testInitFromDictionaryMissingStatusFails() {
        let data: [String: Any] = [
            "lastUpdatedAt": Date()
        ]

        let match = Match(id: "missingStatus", data: data)
        XCTAssertNil(match)
    }

    func testDictionaryRoundTrip() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let participants = [
            Match.Participant(userID: "userA", isInitiator: true),
            Match.Participant(userID: "userB", isInitiator: false)
        ]
        let original = Match(
            id: "matchABC",
            participants: participants,
            status: .active,
            lastMessagePreview: "Hi",
            lastUpdatedAt: date,
            conversationID: "conversation-abc"
        )

        let dict = original.toDictionary()
        let reconstructed = Match(id: original.id, data: dict)

        XCTAssertNotNil(reconstructed)
        XCTAssertEqual(reconstructed?.id, original.id)
        XCTAssertEqual(reconstructed?.status, original.status)
        XCTAssertEqual(reconstructed?.lastMessagePreview, original.lastMessagePreview)
        XCTAssertEqual(reconstructed?.lastUpdatedAt, original.lastUpdatedAt)
        XCTAssertEqual(reconstructed?.participantIDs.sorted(), original.participantIDs.sorted())
        XCTAssertEqual(reconstructed?.conversationID, original.conversationID)
    }
}
