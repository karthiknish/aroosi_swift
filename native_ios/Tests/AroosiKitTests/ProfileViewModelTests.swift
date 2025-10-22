import XCTest
@testable import AroosiKit

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testObserveProfileEmitsProfileFromStream() async {
        let repository = ProfileRepositoryStreamStub()
        let viewModel = ProfileViewModel(profileRepository: repository)
        let profile = ProfileSummary(id: "user-1", displayName: "Aisha", age: 30, location: "Dubai")

        viewModel.observeProfile(for: "user-1")
        await Task.yield()
        repository.send([profile])

        await waitForState(viewModel) { state in
            state.profile == profile && !state.isLoading
        }

        XCTAssertEqual(viewModel.state.profile, profile)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testStreamFailureFallsBackToFetch() async {
        let repository = ProfileRepositoryStreamStub()
        let fallback = ProfileSummary(id: "user-1", displayName: "Aisha")
        repository.fetchProfileHandler = { _ in fallback }
        let viewModel = ProfileViewModel(profileRepository: repository)

        viewModel.observeProfile(for: "user-1")
        await Task.yield()
        repository.fail(with: TestError.failed)

        await waitForState(viewModel) { state in
            state.profile == fallback && !state.isLoading
        }

        XCTAssertEqual(viewModel.state.profile, fallback)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testStreamAndFetchFailureEmitErrorMessage() async {
        let repository = ProfileRepositoryStreamStub()
        repository.fetchProfileHandler = { _ in throw TestError.failed }
        let viewModel = ProfileViewModel(profileRepository: repository)

        viewModel.observeProfile(for: "user-1")
        await Task.yield()
        repository.fail(with: TestError.failed)

        await waitForState(viewModel) { state in
            state.errorMessage != nil && !state.isLoading
        }

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertNil(viewModel.state.profile)
    }

    private func waitForState(_ viewModel: ProfileViewModel,
                              timeout: TimeInterval = 1,
                              predicate: @escaping (ProfileViewModel.State) -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate(viewModel.state) { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for view model state to satisfy predicate")
    }
}

private enum TestError: Error {
    case failed
}

@preconcurrency
private final class ProfileRepositoryStreamStub: ProfileRepository {
    var fetchProfileHandler: (String) async throws -> ProfileSummary = { _ in
        throw RepositoryError.notFound
    }

    private var continuation: AsyncThrowingStream<[ProfileSummary], Error>.Continuation?
    private var pendingProfiles: [[ProfileSummary]] = []
    private var pendingError: Error?

    func fetchProfile(id: String) async throws -> ProfileSummary {
        try await fetchProfileHandler(id)
    }

    func streamProfiles(userIDs: [String]) -> AsyncThrowingStream<[ProfileSummary], Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            for payload in self.pendingProfiles {
                continuation.yield(payload)
            }
            self.pendingProfiles.removeAll()

            if let error = self.pendingError {
                continuation.finish(throwing: error)
                self.pendingError = nil
            }
        }
    }

    func updateProfile(_ profile: ProfileSummary) async throws {}

    func send(_ profiles: [ProfileSummary]) {
        if let continuation {
            continuation.yield(profiles)
        } else {
            pendingProfiles.append(profiles)
        }
    }

    func fail(with error: Error) {
        if let continuation {
            continuation.finish(throwing: error)
        } else {
            pendingError = error
        }
    }
}
