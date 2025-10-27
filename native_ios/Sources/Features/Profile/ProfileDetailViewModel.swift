import Foundation
import SwiftUI

@available(iOS 17, *)
@MainActor
final class ProfileDetailViewModel: ObservableObject {
    struct State {
        var detail: ProfileDetail?
        var isLoading = false
        var isRefreshing = false
        var errorMessage: String?
        var isUpdatingFavorite = false
        var isUpdatingShortlist = false
        var safetyStatus = SafetyStatus()
        var isPerformingSafetyAction = false
        var infoMessage: String?
    }

    @Published private(set) var state = State()

    private let profileID: String
    private let repository: any ProfileRepository
    private let safetyRepository: SafetyRepository

    init(profileID: String,
         repository: any ProfileRepository,
         safetyRepository: SafetyRepository = FirestoreSafetyRepository()) {
        self.profileID = profileID
        self.repository = repository
        self.safetyRepository = safetyRepository
    }

    func loadIfNeeded() async {
        guard state.detail == nil, !state.isLoading else { return }
        await load(force: false)
    }

    func refresh() async {
        await load(force: true)
    }

    func toggleFavorite() async {
        guard !state.isUpdatingFavorite else { return }
        guard var detail = state.detail else { return }
        state.isUpdatingFavorite = true
        defer { state.isUpdatingFavorite = false }

        do {
            try await repository.toggleFavorite(userID: profileID)
            detail.isFavorite.toggle()
            state.detail = detail
        } catch {
            state.errorMessage = "We couldn't update favorites. Please try again."
        }
    }

    func toggleShortlist() async {
        guard !state.isUpdatingShortlist else { return }
        guard var detail = state.detail else { return }
        state.isUpdatingShortlist = true
        defer { state.isUpdatingShortlist = false }

        do {
            let result = try await repository.toggleShortlist(userID: profileID)
            switch result.action {
            case .added:
                detail.isShortlisted = true
            case .removed:
                detail.isShortlisted = false
            }
            state.detail = detail
        } catch {
            state.errorMessage = "We couldn't update your shortlist right now."
        }
    }

    func blockUser() async {
        guard !state.isPerformingSafetyAction else { return }
        state.isPerformingSafetyAction = true
        state.errorMessage = nil
        state.infoMessage = nil
        defer { state.isPerformingSafetyAction = false }

        do {
            try await safetyRepository.block(userID: profileID)
            state.safetyStatus.isBlocked = true
            state.safetyStatus.canInteract = false
            state.infoMessage = "You won't receive messages from this member anymore."
        } catch {
            state.errorMessage = "We couldn't update safety settings. Please try again."
        }
    }

    func unblockUser() async {
        guard !state.isPerformingSafetyAction else { return }
        state.isPerformingSafetyAction = true
        state.errorMessage = nil
        state.infoMessage = nil
        defer { state.isPerformingSafetyAction = false }

        do {
            try await safetyRepository.unblock(userID: profileID)
            state.safetyStatus.isBlocked = false
            state.safetyStatus.canInteract = !state.safetyStatus.isBlockedBy
            state.infoMessage = "This member has been unblocked."
        } catch {
            state.errorMessage = "We couldn't update safety settings. Please try again."
        }
    }

    func reportUser(reason: String, details: String?) async {
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        state.isPerformingSafetyAction = true
        state.errorMessage = nil
        state.infoMessage = nil
        defer { state.isPerformingSafetyAction = false }

        do {
            try await safetyRepository.report(userID: profileID, reason: reason, details: details)
            state.infoMessage = "Thank you for letting us know. Our safety team will review."
        } catch {
            state.errorMessage = "We couldn't submit the report. Please try again."
        }
    }

    func dismissMessages() {
        state.infoMessage = nil
        state.errorMessage = nil
    }

    private func load(force: Bool) async {
        if force {
            state.isRefreshing = true
        } else {
            state.isLoading = true
        }
        state.errorMessage = nil

        defer {
            state.isLoading = false
            state.isRefreshing = false
        }

        do {
            let detail = try await repository.fetchProfileDetail(id: profileID)
            state.detail = detail

            let safetyStatus = try await safetyRepository.status(for: profileID)
            state.safetyStatus = safetyStatus
        } catch let error as RepositoryError {
            switch error {
            case .notFound:
                state.errorMessage = "This profile is no longer available."
            case .permissionDenied:
                state.errorMessage = "You don't have access to view this profile."
            default:
                state.errorMessage = "Failed to load profile. Please try again."
            }
        } catch {
            state.errorMessage = "Failed to load profile. Please try again."
        }
    }
}
