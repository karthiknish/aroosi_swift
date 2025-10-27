@testable import AroosiKit
import XCTest

@available(iOS 17, macOS 13, *)
@MainActor
final class SupportCenterViewModelTests: XCTestCase {
    func testInitializationPrefillsEmail() {
        let user = UserProfile(id: "user-1", displayName: "Aisha", email: "aisha@example.com", avatarURL: nil)
        let repository = MockSupportRepository()
        let viewModel = SupportCenterViewModel(user: user, repository: repository)

        XCTAssertEqual(viewModel.state.email, "aisha@example.com")
        XCTAssertEqual(viewModel.state.category, .general)
        XCTAssertTrue(viewModel.state.includeDiagnostics)
    }

    func testSubmitSuccessClearsMessageAndSetsSuccess() async {
        let user = UserProfile(id: "user-1", displayName: "Aisha", email: nil, avatarURL: nil)
        let repository = MockSupportRepository(result: true)
        let viewModel = SupportCenterViewModel(user: user, repository: repository)

        viewModel.updateMessage("Need help with my account")
        await viewModel.submit()

        XCTAssertEqual(repository.request?.message, "Need help with my account")
        XCTAssertEqual(viewModel.state.successMessage, "Thanks for reaching out. We'll reply via email.")
        XCTAssertTrue(viewModel.state.message.isEmpty)
    }

    func testSubmitFailureShowsError() async {
        let user = UserProfile(id: "user-1", displayName: "Aisha", email: nil, avatarURL: nil)
        let repository = MockSupportRepository(result: false)
        let viewModel = SupportCenterViewModel(user: user, repository: repository)

        viewModel.updateMessage("Need help")
        await viewModel.submit()

        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testInvalidEmailShowsError() async {
        let user = UserProfile(id: "user-1", displayName: "Aisha", email: nil, avatarURL: nil)
        let repository = MockSupportRepository(result: true)
        let viewModel = SupportCenterViewModel(user: user, repository: repository)

        viewModel.updateEmail("invalid-email")
        viewModel.updateMessage("Need help")
        await viewModel.submit()

        XCTAssertEqual(viewModel.state.errorMessage, "Please enter a valid email address.")
        XCTAssertNil(repository.request)
    }
}

@available(iOS 15.0, macOS 12.0, *)
private final class MockSupportRepository: SupportRepository {
    var result: Bool
    var request: SupportContactRequest?

    init(result: Bool = true) {
        self.result = result
    }

    func submitContact(_ request: SupportContactRequest) async throws -> Bool {
        self.request = request
        return result
    }
}
