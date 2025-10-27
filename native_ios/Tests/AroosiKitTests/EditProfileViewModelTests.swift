import XCTest
@testable import AroosiKit

@available(iOS 17, macOS 13, *)
@MainActor
final class EditProfileViewModelTests: XCTestCase {
    func testSaveSuccessUpdatesProfile() async {
        let initial = ProfileSummary(id: "user-1",
                                     displayName: "Aisha",
                                     age: 28,
                                     location: "Seattle",
                                     bio: "Traveler",
                                     interests: ["Travel"])
        let repository = ProfileRepositoryRecorder()
        repository.stubbedProfiles["user-1"] = initial

        let viewModel = EditProfileViewModel(userID: "user-1", profile: initial, profileRepository: repository)
        viewModel.updateDisplayName("Aisha Khan")
        viewModel.updateAge("29")
        viewModel.updateLocation("Portland")
        viewModel.updateBio("Photographer")
        viewModel.updateInterests("Photography, Hiking")

        let result = await viewModel.save()

        XCTAssertTrue(result)
        XCTAssertEqual(repository.updatedProfiles.last?.displayName, "Aisha Khan")
        XCTAssertEqual(repository.updatedProfiles.last?.age, 29)
        XCTAssertEqual(repository.updatedProfiles.last?.interests, ["Photography", "Hiking"])
    }

    func testValidationFailsForEmptyName() async {
        let repository = ProfileRepositoryRecorder()
        let viewModel = EditProfileViewModel(userID: "user-1", profile: nil, profileRepository: repository)
        viewModel.updateDisplayName(" ")

        let result = await viewModel.save()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.form.errorMessage, "Display name is required.")
        XCTAssertTrue(repository.updatedProfiles.isEmpty)
    }

    func testValidationFailsForInvalidAge() async {
        let repository = ProfileRepositoryRecorder()
        let viewModel = EditProfileViewModel(userID: "user-1", profile: nil, profileRepository: repository)
        viewModel.updateDisplayName("Aisha")
        viewModel.updateAge("-5")

        let result = await viewModel.save()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.form.errorMessage, "Age must be a positive number.")
    }
}

@available(iOS 15.0, macOS 12.0, *)
private final class ProfileRepositoryRecorder: ProfileRepository {
    var stubbedProfiles: [String: ProfileSummary] = [:]
    private(set) var updatedProfiles: [ProfileSummary] = []

    func fetchProfile(id: String) async throws -> ProfileSummary {
        if let profile = stubbedProfiles[id] {
            return profile
        }
        throw RepositoryError.notFound
    }

    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func updateProfile(_ profile: ProfileSummary) async throws {
        updatedProfiles.append(profile)
        stubbedProfiles[profile.id] = profile
    }

    func fetchShortlist(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleShortlist(userID: String) async throws -> ShortlistToggleResult {
        ShortlistToggleResult(action: .added)
    }

    func setShortlistNote(userID: String, note: String) async throws {}

    func fetchFavorites(pageSize: Int, after documentID: String?) async throws -> ProfileSearchPage {
        ProfileSearchPage(items: [], nextCursor: nil)
    }

    func toggleFavorite(userID: String) async throws {}
}
