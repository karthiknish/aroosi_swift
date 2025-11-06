@testable import AroosiKit
import XCTest

@available(iOS 17, macOS 13, *)
final class ChatUnreadCounterTests: XCTestCase {
    func testUpdatedCountsResetsSenderAndIncrementsOthers() {
        let existing = ["user-1": 2, "user-2": 0]
        let participants = ["user-1", "user-2", "user-3"]

        let updated = ChatUnreadCounter.updatedCounts(afterSendingFrom: "user-1",
                                                      participants: participants,
                                                      existing: existing)

        XCTAssertEqual(updated["user-1"], 0)
        XCTAssertEqual(updated["user-2"], 1)
        XCTAssertEqual(updated["user-3"], 1)
        XCTAssertNil(updated["user-4"])
    }

    func testUpdatedCountsPrunesStaleParticipants() {
        let existing = ["user-1": 4, "user-legacy": 7]
        let participants = ["user-1", "user-2"]

        let updated = ChatUnreadCounter.updatedCounts(afterSendingFrom: "user-2",
                                                      participants: participants,
                                                      existing: existing)

        XCTAssertNil(updated["user-legacy"])
        XCTAssertEqual(updated["user-1"], 5)
        XCTAssertEqual(updated["user-2"], 0)
    }

    func testClearedCountsResetsOnlySpecifiedUser() {
        let existing = ["user-1": 3, "user-2": 1]
        let cleared = ChatUnreadCounter.clearedCounts(for: "user-2", existing: existing)

        XCTAssertEqual(cleared["user-1"], 3)
        XCTAssertEqual(cleared["user-2"], 0)
    }

    func testTotalUnreadAggregatesCounts() {
        let counts = ["user-1": 2, "user-2": 5, "user-3": 0]
        XCTAssertEqual(ChatUnreadCounter.totalUnread(from: counts), 7)
    }
}
