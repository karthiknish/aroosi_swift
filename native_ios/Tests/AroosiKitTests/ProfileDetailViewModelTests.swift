import XCTest
@testable import AroosiKit

@available(iOS 17, macOS 13, *)
@MainActor
final class ProfileDetailViewModelTests: XCTestCase {
    func testLoadSuccessPopulatesDetail() async {
        let repository = MockProfileRepository(detail: .fixture())
        let safetyRepository = MockSafetyRepository(status: SafetyStatus())
        let viewModel = ProfileDetailViewModel(profileID: "profile-1",
                                               repository: repository,
                                               safetyRepository: safetyRepository)

        await viewModel.loadIfNeeded()

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.detail)
        XCTAssertEqual(viewModel.state.detail?.summary.displayName, "Amina")
        XCTAssertEqual(viewModel.state.detail?.interests, ["Travel", "Art"])
        XCTAssertEqual(viewModel.state.safetyStatus, SafetyStatus())
    }

    func testToggleFavoriteFlipsState() async {
        let repository = MockProfileRepository(detail: .fixture(isFavorite: false))
        let safetyRepository = MockSafetyRepository(status: SafetyStatus())
        let viewModel = ProfileDetailViewModel(profileID: "profile-1",
                                               repository: repository,
                                               safetyRepository: safetyRepository)

        await viewModel.loadIfNeeded()
        await viewModel.toggleFavorite()

        XCTAssertTrue(viewModel.state.detail?.isFavorite ?? false)
        XCTAssertEqual(repository.favoriteToggles, 1)
    }

    func testToggleShortlistUpdatesAction() async {
        let repository = MockProfileRepository(detail: .fixture(isShortlisted: false), shortlistResult: .init(action: .added))
        let safetyRepository = MockSafetyRepository(status: SafetyStatus())
        let viewModel = ProfileDetailViewModel(profileID: "profile-1",
                                               repository: repository,
                                               safetyRepository: safetyRepository)

        await viewModel.loadIfNeeded()
        await viewModel.toggleShortlist()

        XCTAssertTrue(viewModel.state.detail?.isShortlisted ?? false)
        XCTAssertEqual(repository.shortlistToggles, 1)
    }

    func testBlockUserUpdatesStatusAndInfoMessage() async {
        let repository = MockProfileRepository(detail: .fixture())
        let safetyRepository = MockSafetyRepository(status: SafetyStatus())
        let viewModel = ProfileDetailViewModel(profileID: "profile-1",
                                               repository: repository,
                                               safetyRepository: safetyRepository)

        await viewModel.loadIfNeeded()
        await viewModel.blockUser()

        XCTAssertTrue(viewModel.state.safetyStatus.isBlocked)
        XCTAssertFalse(viewModel.state.safetyStatus.canInteract)
        XCTAssertEqual(viewModel.state.infoMessage, "You won't receive messages from this member anymore.")
        XCTAssertEqual(safetyRepository.blockCalls, ["profile-1"])
    }

    func testUnblockUserClearsStatus() async {
        let repository = MockProfileRepository(detail: .fixture())
        let safetyRepository = MockSafetyRepository(status: SafetyStatus(isBlocked: true, isBlockedBy: false, canInteract: false))
        let viewModel = ProfileDetailViewModel(profileID: "profile-1",
                                               repository: repository,
                                               safetyRepository: safetyRepository)

        await viewModel.loadIfNeeded()
        await viewModel.unblockUser()

        XCTAssertFalse(viewModel.state.safetyStatus.isBlocked)
        XCTAssertTrue(viewModel.state.safetyStatus.canInteract)
        XCTAssertEqual(viewModel.state.infoMessage, "This member has been unblocked.")
        XCTAssertEqual(safetyRepository.unblockCalls, ["profile-1"])
    }

    func testReportUserSetsInfoMessage() async {
        let repository = MockProfileRepository(detail: .fixture())
        let safetyRepository = MockSafetyRepository(status: SafetyStatus())
        let viewModel = ProfileDetailViewModel(profileID: "profile-1",
                                               repository: repository,
                                               safetyRepository: safetyRepository)

        await viewModel.loadIfNeeded()
        await viewModel.reportUser(reason: "Spam", details: "Suspicious messages")

        XCTAssertEqual(safetyRepository.reportCalls.count, 1)
        XCTAssertEqual(safetyRepository.reportCalls.first?.reason, "Spam")
        XCTAssertEqual(viewModel.state.infoMessage, "Thank you for letting us know. Our safety team will review.")
    }
}

@available(iOS 17, macOS 13, *)
private final class MockProfileRepository: ProfileRepository {
    var detail: ProfileDetail
    var shortlistResult: ShortlistToggleResult
    var favoriteToggles = 0
    var shortlistToggles = 0

    init(detail: ProfileDetail, shortlistResult: ShortlistToggleResult = .init(action: .removed)) {
        self.detail = detail
        self.shortlistResult = shortlistResult
    }

    func fetchProfile(id: String) async throws -> ProfileSummary {
        detail.summary
    }

    func fetchProfileDetail(id: String) async throws -> ProfileDetail {
        detail
    }

    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func updateProfile(_ profile: ProfileSummary) async throws {}

    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        shortlistToggles += 1
        if shortlistResult.action == .added {
            detail.isShortlisted = true
        } else {
            detail.isShortlisted = false
        }
        return shortlistResult
    }

    func setShortlistNote(userID: String, note: String) async throws {}

    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleFavorite(userID: String) async throws {
        favoriteToggles += 1
        detail.isFavorite.toggle()
    }
}

@available(iOS 17, macOS 13, *)
private final class MockSafetyRepository: SafetyRepository {
    var status: SafetyStatus
    var blockCalls: [String] = []
    var unblockCalls: [String] = []
    var reportCalls: [(userID: String, reason: String, details: String?)] = []

    init(status: SafetyStatus) {
        self.status = status
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] { [] }

    func block(userID: String) async throws {
        blockCalls.append(userID)
    }

    func unblock(userID: String) async throws {
        unblockCalls.append(userID)
    }

    func report(userID: String, reason: String, details: String?) async throws {
        reportCalls.append((userID, reason, details))
    }

    func status(for userID: String) async throws -> SafetyStatus {
        status
    }

    func fetchSubmittedReports() async throws -> [SafetyReport] { [] }
}

@available(iOS 17, macOS 13, *)
private extension ProfileDetail {
    static func fixture(isFavorite: Bool = false,
                        isShortlisted: Bool = false) -> ProfileDetail {
        let summary = ProfileSummary(
            id: "profile-1",
            displayName: "Amina",
            age: 27,
            location: "Seattle",
            bio: "World traveler and art enthusiast",
            avatarURL: URL(string: "https://example.com/avatar.jpg"),
            interests: ["Travel", "Art"]
        )

        return ProfileDetail(
            summary: summary,
            about: "I love discovering new cultures and cuisines.",
            headline: "Cultural explorer",
            gallery: [URL(string: "https://example.com/photo1.jpg")!],
            interests: summary.interests,
            languages: ["English", "Dari"],
            motherTongue: "Dari",
            education: "Masters in International Relations",
            occupation: "Program Manager",
            culturalProfile: CulturalProfileDetail(
                religion: "islam",
                religiousPractice: "moderately_practicing",
                languages: ["English", "Dari"],
                familyValues: "mixed",
                marriageViews: "arranged_marriage",
                familyApprovalImportance: "very_important",
                cultureImportance: 7
            ),
            preferences: MatchPreferencesDetail(minAge: 25, maxAge: 35, location: "Seattle"),
            familyBackground: "Raised in a close-knit family with strong cultural roots.",
            personalityTraits: ["Empathetic", "Adventurous"],
            isFavorite: isFavorite,
            isShortlisted: isShortlisted
        )
    }
}
