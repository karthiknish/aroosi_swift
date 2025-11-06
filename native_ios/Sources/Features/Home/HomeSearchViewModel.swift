#if os(iOS)
import Foundation

@available(iOS 17, *)
@MainActor
final class HomeSearchViewModel: ObservableObject {
    struct State: Equatable {
        var query: String = ""
        var selectedCity: String?
        var selectedInterests: Set<String> = []
        var minAge: Int = SearchFilterMetadata.default.minAge
        var maxAge: Int = SearchFilterMetadata.default.maxAge
        var minAllowedAge: Int = SearchFilterMetadata.default.minAge
        var maxAllowedAge: Int = SearchFilterMetadata.default.maxAge
        var availableCities: [String] = []
        var availableInterests: [String] = []
        var results: [ProfileSummary] = []
        var nextCursor: String?
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var hasLoaded: Bool = false
        var errorMessage: String?
        var isShowingFilters: Bool = false

        var hasActiveFilters: Bool {
            selectedCity != nil || !selectedInterests.isEmpty || minAge != minAllowedAge || maxAge != maxAllowedAge
        }

        var isEmpty: Bool {
            !isLoading && results.isEmpty && errorMessage == nil
        }
    }

    @Published private(set) var state = State()

    private let pageSize = 20
    private let searchRepository: ProfileSearchRepository
    private let metadataRepository: SearchMetadataRepository
    private let profileRepository: ProfileRepository
    private let interestRepository: InterestRepository
    private var currentUserID: String?
    private var metadata: SearchFilterMetadata = .default
    private var loadedProfileIDs: Set<String> = []
    private var searchTask: Task<Void, Never>?

    init(searchRepository: ProfileSearchRepository = FirestoreProfileSearchRepository(),
         metadataRepository: SearchMetadataRepository = FirestoreSearchMetadataRepository(),
         profileRepository: ProfileRepository = FirestoreProfileRepository(),
         interestRepository: InterestRepository = FirestoreInterestRepository()) {
        self.searchRepository = searchRepository
        self.metadataRepository = metadataRepository
        self.profileRepository = profileRepository
        self.interestRepository = interestRepository
    }

    deinit {
        searchTask?.cancel()
    }

    func loadIfNeeded(for userID: String) {
        guard !state.hasLoaded else { return }
        currentUserID = userID
        Task { await bootstrap() }
    }

    func refresh() {
        Task { await performSearch(reset: true) }
    }

    func updateQuery(_ value: String) {
        state.query = value
        debounceSearch()
    }

    func setFilterSheetVisible(_ isVisible: Bool) {
        state.isShowingFilters = isVisible
    }

    func applyFilters(city: String?, minAge: Int, maxAge: Int, interests: Set<String>) {
        state.selectedCity = city
        state.minAge = minAge
        state.maxAge = maxAge
        state.selectedInterests = interests
        state.isShowingFilters = false
        Task { await performSearch(reset: true) }
    }

    func clearFilters() {
        state.selectedCity = nil
        state.selectedInterests = []
        state.minAge = metadata.minAge
        state.maxAge = metadata.maxAge
        state.isShowingFilters = false
        Task { await performSearch(reset: true) }
    }

    func loadMoreIfNeeded(currentItem item: ProfileSummary) {
        guard state.nextCursor != nil,
              !state.isLoadingMore,
              !state.isLoading,
              state.results.last?.id == item.id else { return }

        Task { await performSearch(reset: false) }
    }

    func fetchDetail(for profileID: String) async -> ProfileDetail? {
        do {
            return try await profileRepository.fetchProfileDetail(id: profileID)
        } catch {
            Logger.shared.error("Failed to load profile detail: \(error.localizedDescription)")
            ToastManager.shared.showError("We couldn't load that profile right now.")
            return nil
        }
    }

    func sendInterest(to profile: ProfileSummary) {
        guard let currentUserID, profile.id != currentUserID else { return }

        Task {
            do {
                try await interestRepository.sendInterest(from: currentUserID, to: profile.id)
                await MainActor.run {
                    ToastManager.shared.showSuccess("Interest sent to \(profile.displayName)")
                }
            } catch let error as RepositoryError where error == .alreadyExists {
                await MainActor.run {
                    ToastManager.shared.showInfo("You've already shown interest in \(profile.displayName)")
                }
            } catch {
                Logger.shared.error("Failed to send interest: \(error.localizedDescription)")
                await MainActor.run {
                    ToastManager.shared.showError("We couldn't send interest right now.")
                }
            }
        }
    }

    func dismissError() {
        state.errorMessage = nil
    }
 }
 
 private extension HomeSearchViewModel {
    func bootstrap() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            metadata = try await metadataRepository.fetchMetadata()
            state.availableCities = metadata.normalizedCities
            state.availableInterests = metadata.normalizedInterests
            state.minAllowedAge = metadata.minAge
            state.maxAllowedAge = metadata.maxAge
            state.minAge = metadata.minAge
            state.maxAge = metadata.maxAge
            state.hasLoaded = true
            await performSearch(reset: true)
        } catch {
            Logger.shared.error("Failed to load search metadata: \(error.localizedDescription)")
            state.availableCities = metadata.normalizedCities
            state.availableInterests = metadata.normalizedInterests
            state.errorMessage = "We couldn't load discovery filters. Showing default results."
            state.hasLoaded = true
            await performSearch(reset: true)
        }
    }

    func debounceSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch(reset: true)
        }
    }

    func performSearch(reset: Bool) async {
        guard let currentUserID else { return }
        if reset {
            state.isLoading = true
            state.nextCursor = nil
            loadedProfileIDs.removeAll()
        } else {
            state.isLoadingMore = true
        }

        state.errorMessage = nil

        do {
            let filters = SearchFilters(
                query: state.query,
                city: state.selectedCity,
                minAge: state.minAge,
                maxAge: state.maxAge,
                preferredGender: nil,
                pageSize: pageSize,
                interests: state.selectedInterests
            )

            let page = try await searchRepository.searchProfiles(filters: filters,
                                                                 pageSize: pageSize,
                                                                 cursor: reset ? nil : state.nextCursor)

            var items = page.items.filter { $0.id != currentUserID }
            items.removeAll { loadedProfileIDs.contains($0.id) }

            if reset {
                state.results = items
            } else {
                state.results.append(contentsOf: items)
            }

            for profile in items {
                loadedProfileIDs.insert(profile.id)
            }

            state.nextCursor = page.nextCursor
        } catch let error as RepositoryError {
            state.errorMessage = error.userMessage
            if reset {
                state.results = []
                loadedProfileIDs.removeAll()
                state.nextCursor = nil
            }
        } catch {
            Logger.shared.error("Search failed: \(error.localizedDescription)")
            state.errorMessage = "We couldn't load matches right now. Please try again later."
            if reset {
                state.results = []
                loadedProfileIDs.removeAll()
                state.nextCursor = nil
            }
        }

        state.isLoading = false
        state.isLoadingMore = false
    }
 }
 
 private extension RepositoryError {
    var userMessage: String {
        switch self {
        case .permissionDenied:
            return "You don't have permission to run this search."
        case .networkFailure:
            return "You're offline right now. Please check your connection."
        case .notFound:
            return "We couldn't find any profiles for these filters."
        default:
            return "Something went wrong. Please try again."
        }
    }
 }
#endif
