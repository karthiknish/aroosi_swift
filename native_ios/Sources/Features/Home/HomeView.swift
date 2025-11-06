#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct HomeView: View {
    let user: UserProfile
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @StateObject private var viewModel = HomeSearchViewModel()
    @State private var filterDraft = FilterDraft()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()

                ScrollView {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        VStack(alignment: .leading, spacing: Responsive.spacing(width: width)) {
                            header
                            searchField
                            filterRow
                            resultsSection
                        }
                        .padding(Responsive.screenPadding(width: width))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .navigationDestination(for: String.self) { profileID in
                ProfileSummaryDetailView(profileID: profileID)
            }
        }
        .tint(Color.blue)
        .task { viewModel.loadIfNeeded(for: user.id) }
        .sheet(isPresented: filterSheetBinding) { filterSheet }
        .onChange(of: viewModel.state.isShowingFilters) { newValue in
            if newValue {
                filterDraft = FilterDraft(state: viewModel.state)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Salaam, \(user.displayName)")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.primary)

            Text("Discover profiles tailored to your preferences and send a thoughtful interest.")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.secondary)

            TextField("Search by name, city, or interest", text: Binding(
                get: { viewModel.state.query },
                set: { viewModel.updateQuery($0) }
            ))
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .onSubmit { viewModel.refresh() }

            if !viewModel.state.query.isEmpty {
                Button {
                    viewModel.updateQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 6)
    }

    private var filterRow: some View {
        HStack(spacing: 12) {
            Button {
                filterDraft = FilterDraft(state: viewModel.state)
                viewModel.setFilterSheetVisible(true)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text(viewModel.state.hasActiveFilters ? "Filters • On" : "Filters")
                }
                .font(.body.weight(.medium))
                .foregroundStyle(viewModel.state.hasActiveFilters ? Color.blue : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    viewModel.state.hasActiveFilters ?
                        Color.blue.opacity(0.1) :
                        Color(UIColor.secondarySystemBackground),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)

            if viewModel.state.hasActiveFilters {
                Button("Clear") {
                    viewModel.clearFilters()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.blue)
            }

            Spacer()
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let error = viewModel.state.errorMessage {
                VStack(spacing: 12) {
                    InlineMessageView(message: error, style: .error)
                        .onTapGesture { viewModel.dismissError() }
                    
                    Button {
                        viewModel.refresh()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry Search")
                        }
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AroosiColors.primary)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Retry Search")
                    .accessibilityHint("Double tap to retry searching for profiles")
                }
            }

            if viewModel.state.isLoading && viewModel.state.results.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AroosiColors.primary)
                    Text("Searching for compatible profiles…")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if viewModel.state.isEmpty {
                ContentUnavailableView(
                    "No matches yet",
                    systemImage: "person.2.circle",
                    description: Text("Adjust your filters to see more potential matches.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.state.results) { profile in
                        NavigationLink(value: profile.id) {
                            ProfileCardView(profile: profile)
                        }
                        .buttonStyle(.plain)
                        .task { viewModel.loadMoreIfNeeded(currentItem: profile) }
                        .contextMenu {
                            Button {
                                viewModel.sendInterest(to: profile)
                            } label: {
                                Label("Send Interest", systemImage: "heart.fill")
                            }
                        }
                    }

                    if viewModel.state.isLoadingMore {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.blue)
                            .padding(.vertical)
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.state.isLoading)
        }

        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                coordinator.navigate(to: .dashboard)
            } label: {
                Image(systemName: "square.grid.2x2")
            }
        }
    }

    private var filterSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.isShowingFilters },
            set: { viewModel.setFilterSheetVisible($0) }
        )
    }

    @ViewBuilder
    private var filterSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AgeRangeFilterView(
                        minAge: $filterDraft.minAge,
                        maxAge: $filterDraft.maxAge,
                        range: viewModel.state.minAllowedAge...viewModel.state.maxAllowedAge
                    )

                    LocationFilterView(
                        selectedLocation: $filterDraft.city,
                        locations: viewModel.state.availableCities
                    )

                    InterestFilterView(
                        selectedInterests: $filterDraft.interests,
                        availableInterests: viewModel.state.availableInterests,
                        maxSelections: 6
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { viewModel.setFilterSheetVisible(false) }
                }
            }
            .safeAreaInset(edge: .bottom) {
                FilterActionsView(
                    onClear: {
                        filterDraft.reset(to: viewModel.state)
                    },
                    onApply: {
                        viewModel.applyFilters(city: filterDraft.city,
                                               minAge: filterDraft.minAge,
                                               maxAge: filterDraft.maxAge,
                                               interests: filterDraft.interests)
                    },
                    hasActiveFilters: filterDraft.hasActiveFilters(relativeTo: viewModel.state)
                )
                .background(Color(UIColor.systemBackground))
            }
        }
        .presentationDetents([.medium, .large])
    }
}

@available(iOS 17, *)
private struct FilterDraft {
    var city: String?
    var minAge: Int
    var maxAge: Int
    var interests: Set<String>
    var minBaseline: Int
    var maxBaseline: Int

    init() {
        let defaults = SearchFilterMetadata.default
        self.city = nil
        self.minAge = defaults.minAge
        self.maxAge = defaults.maxAge
        self.interests = []
        self.minBaseline = defaults.minAge
        self.maxBaseline = defaults.maxAge
    }

    init(state: HomeSearchViewModel.State) {
        self.city = state.selectedCity
        self.minAge = state.minAge
        self.maxAge = state.maxAge
        self.interests = state.selectedInterests
        self.minBaseline = state.minAllowedAge
        self.maxBaseline = state.maxAllowedAge
    }

    mutating func reset(to state: HomeSearchViewModel.State) {
        city = nil
        interests = []
        minAge = state.minAllowedAge
        maxAge = state.maxAllowedAge
        minBaseline = state.minAllowedAge
        maxBaseline = state.maxAllowedAge
    }

    func hasActiveFilters(relativeTo state: HomeSearchViewModel.State) -> Bool {
        city != nil || !interests.isEmpty || minAge != state.minAllowedAge || maxAge != state.maxAllowedAge
    }
}

#Preview {
    if #available(iOS 17, *) {
        HomeView(user: UserProfile(id: "user-123", displayName: "Test User", email: nil, avatarURL: nil))
            .environmentObject(NavigationCoordinator())
    }
}
#endif
