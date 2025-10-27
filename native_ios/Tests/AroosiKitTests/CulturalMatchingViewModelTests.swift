@testable import AroosiKit
import XCTest

@available(iOS 17, macOS 13, *)
@MainActor
final class CulturalMatchingViewModelTests: XCTestCase {
    func testLoadSuccessPopulatesState() async {
        let repository = CulturalRepositoryStub()
        repository.profile = CulturalProfile(religion: "Islam", religiousPractice: "Practicing", motherTongue: "Urdu")
        repository.recommendations = [
            CulturalRecommendation(id: "user-2",
                                   profile: ProfileSummary(id: "user-2", displayName: "Leila"),
                                   compatibilityScore: 82,
                                   breakdown: .init(religion: 90, language: 70, values: 80, family: 75))
        ]

        let viewModel = CulturalMatchingViewModel(repository: repository)
        viewModel.load(for: "user-1")
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.state.profile)
        XCTAssertEqual(viewModel.state.recommendations.count, 1)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testLoadFailureSetsErrorMessage() async {
        let repository = CulturalRepositoryStub()
        repository.error = RepositoryError.networkFailure

        let viewModel = CulturalMatchingViewModel(repository: repository)
        viewModel.load(for: "user-1")
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.recommendations.isEmpty)
    }

    func testCompatibilityViewModelLoadsReport() async {
        let repository = CulturalRepositoryStub()
        repository.report = CulturalCompatibilityReport(
            overallScore: 78,
            insights: ["Strong shared traditions"],
            dimensions: [
                .init(key: "religion", label: "Religion", score: 85),
                .init(key: "values", label: "Family Values", score: 72)
            ]
        )

        let viewModel = CulturalCompatibilityViewModel(repository: repository)
        viewModel.load(primaryUserID: "user-1", targetUserID: "user-2")
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.state.report?.overallScore, 78)
        XCTAssertFalse(viewModel.state.isLoading)
    }
}

private final class CulturalRepositoryStub: CulturalRepository {
    var profile: CulturalProfile?
    var recommendations: [CulturalRecommendation] = []
    var report: CulturalCompatibilityReport = CulturalCompatibilityReport(overallScore: 0, insights: [], dimensions: [])
    var error: Error?

    func fetchProfile(userID: String?) async throws -> CulturalProfile? {
        if let error { throw error }
        return profile
    }

    func updateProfile(_ profile: CulturalProfile, userID: String?) async throws {}

    func fetchRecommendations(limit: Int) async throws -> [CulturalRecommendation] {
        if let error { throw error }
        return recommendations
    }

    func fetchCompatibilityReport(primaryUserID: String, targetUserID: String) async throws -> CulturalCompatibilityReport {
        if let error { throw error }
        return report
    }
}
