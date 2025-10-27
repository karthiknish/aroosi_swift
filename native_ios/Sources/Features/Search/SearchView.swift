#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct SearchView: View {
    let user: UserProfile
    @StateObject private var viewModel: SearchViewModel
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var isPresentingFilters = false
    @State private var pendingFilters = SearchFilters()
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var rotation: Double = 0

    @MainActor
    init(user: UserProfile, viewModel: SearchViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? SearchViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AroosiColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with filters
                    header
                    
                    // Card stack
                    GeometryReader { geometry in
                        ZStack {
                            if viewModel.state.items.isEmpty {
                                emptyState
                            } else {
                                cardStack(in: geometry)
                            }
                        }
                    }
                    
                    // Action buttons
                    actionButtons
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(AroosiColors.primary)
        .task(id: user.id) {
            viewModel.configure(userID: user.id)
        }
        .sheet(isPresented: $isPresentingFilters) {
            AdvancedSearchFiltersView(initialFilters: pendingFilters) { updatedFilters in
                viewModel.apply(filters: updatedFilters)
                isPresentingFilters = false
            }
        }
        .onAppear { handlePendingRoute() }
        .onChange(of: coordinator.pendingRoute) { _ in
            handlePendingRoute()
        }
    }
    
    private var header: some View {
        HStack {
            Text("Discover")
                .font(AroosiTypography.heading(size: 28, weight: .bold))
                .foregroundStyle(AroosiColors.text)
            
            Spacer()
            
            Button {
                presentFilters()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundStyle(AroosiColors.primary)
                    .padding(8)
                    .background(AroosiColors.surface, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func cardStack(in geometry: GeometryProxy) -> some View {
        let cardSize = Responsive.cardSize(width: geometry.size.width, height: geometry.size.height)
        
        return ZStack {
            // Show up to 3 cards in stack
            ForEach(Array(viewModel.state.items.enumerated()), id: \.offset) { index, profile in
                if index >= currentIndex && index < currentIndex + 3 {
                    ProfileCard(
                        profile: profile,
                        onTap: {
                            coordinator.navigate(to: .profile(profile.id))
                        }
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(
                        x: index == currentIndex ? dragOffset.width : 0,
                        y: CGFloat(index - currentIndex) * Responsive.spacing(width: geometry.size.width, multiplier: 0.5)
                    )
                    .scaleEffect(index == currentIndex ? 1.0 : 0.95 - CGFloat(index - currentIndex) * 0.05)
                    .rotationEffect(.degrees(index == currentIndex ? rotation : 0))
                    .opacity(index == currentIndex ? 1.0 : 0.5)
                    .zIndex(Double(viewModel.state.items.count - index))
                    .gesture(
                        index == currentIndex ?
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                                rotation = Double(value.translation.width / 20)
                            }
                            .onEnded { value in
                                handleSwipe(value: value, profile: profile)
                            }
                        : nil
                    )
                    .animation(AroosiMotionCurves.spring, value: dragOffset)
                    .animation(AroosiMotionCurves.spring, value: currentIndex)
                }
            }
            
            // Loading indicator
            if viewModel.state.isLoadingMore && currentIndex >= viewModel.state.items.count - 2 {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AroosiColors.primary)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(AroosiColors.muted)
            
            Text("No Profiles Available")
                .font(AroosiTypography.heading(size: 20, weight: .semibold))
                .foregroundStyle(AroosiColors.text)
            
            Text("Try adjusting your filters to see more profiles")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
            
            Button("Adjust Filters") {
                presentFilters()
            }
            .buttonStyle(.borderedProminent)
            .tint(AroosiColors.primary)
        }
        .padding(40)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Pass button
            Button {
                swipeLeft()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
            }
            
            // Info button
            Button {
                if currentIndex < viewModel.state.items.count {
                    let profile = viewModel.state.items[currentIndex]
                    coordinator.navigate(to: .profile(profile.id))
                }
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(AroosiColors.primary, in: Circle())
                    .shadow(color: AroosiColors.primary.opacity(0.3), radius: 8, y: 4)
            }
            
            // Like button
            Button {
                swipeRight()
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private func handleSwipe(value: DragGesture.Value, profile: ProfileSummary) {
        let swipeThreshold: CGFloat = 100
        
        if abs(value.translation.width) > swipeThreshold {
            if value.translation.width > 0 {
                // Swipe right - Like
                likeProfile(profile)
            } else {
                // Swipe left - Pass
                passProfile(profile)
            }
            
            // Animate card off screen
            withAnimation(.easeOut(duration: AroosiMotionDurations.short)) {
                dragOffset = CGSize(
                    width: value.translation.width > 0 ? 500 : -500,
                    height: value.translation.height
                )
            }
            
            // Move to next card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex += 1
                dragOffset = .zero
                rotation = 0
                
                // Load more if near end
                if currentIndex >= viewModel.state.items.count - 2 {
                    viewModel.loadMore()
                }
            }
        } else {
            // Snap back
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = .zero
                rotation = 0
            }
        }
    }
    
    private func swipeLeft() {
        guard currentIndex < viewModel.state.items.count else { return }
        
        let profile = viewModel.state.items[currentIndex]
        passProfile(profile)
        
        withAnimation(.easeOut(duration: AroosiMotionDurations.short)) {
            dragOffset = CGSize(width: -500, height: 0)
            rotation = -20
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AroosiMotionDurations.short) {
            currentIndex += 1
            dragOffset = .zero
            rotation = 0
            
            if currentIndex >= viewModel.state.items.count - 2 {
                viewModel.loadMore()
            }
        }
    }
    
    private func swipeRight() {
        guard currentIndex < viewModel.state.items.count else { return }
        
        let profile = viewModel.state.items[currentIndex]
        likeProfile(profile)
        
        withAnimation(.easeOut(duration: AroosiMotionDurations.short)) {
            dragOffset = CGSize(width: 500, height: 0)
            rotation = 20
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AroosiMotionDurations.short) {
            currentIndex += 1
            dragOffset = .zero
            rotation = 0
            
            if currentIndex >= viewModel.state.items.count - 2 {
                viewModel.loadMore()
            }
        }
    }
    
    private func handleLike(profile: ProfileSummary) {
        // Send interest/like via viewModel
        viewModel.likeProfile(profile)
        moveToNextCard()
    }
    
    private func handlePass(profile: ProfileSummary) {
        // Track pass action
        viewModel.passProfile(profile)
        moveToNextCard()
    }

}

// MARK: - Profile Card Component
@available(iOS 17, *)
private struct ProfileCard: View {
    let profile: ProfileSummary
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image
            Group {
                if let url = profile.avatarURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.3)
                                .overlay(ProgressView().tint(AroosiColors.primary))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.7)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Profile info
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(profile.displayName)
                        .font(AroosiTypography.heading(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    
                    if let age = profile.age {
                        Text("\(age)")
                            .font(AroosiTypography.heading(size: 28, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                if let location = profile.location, !location.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                        Text(location)
                            .font(AroosiTypography.body(size: 16))
                    }
                    .foregroundStyle(.white)
                }
                
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(AroosiTypography.body())
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                if !profile.interests.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(profile.interests.prefix(5), id: \.self) { interest in
                                Text(interest)
                                    .font(AroosiTypography.caption(size: 13))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AroosiColors.primary.opacity(0.8), in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AroosiColors.surface)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        .onTapGesture {
            onTap()
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [AroosiColors.primary.opacity(0.3), AroosiColors.primaryDark.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(AroosiColors.primary.opacity(0.5))
        }
    }
}

@available(iOS 17, *)
private extension SearchView {
    func presentFilters() {
        pendingFilters = viewModel.currentFilters
        isPresentingFilters = true
    }

    func handlePendingRoute() {
        guard let route = coordinator.consumePendingRoute(for: .search) else { return }
        guard case let .search(destination) = route else { return }

        switch destination {
        case .filters, .advanced:
            presentFilters()
        }
    }
}

#Preview {
    if #available(iOS 17, *) {
        SearchView(user: UserProfile(id: "user-123", displayName: "Test User", email: nil, avatarURL: nil),
                   viewModel: SearchViewModel(searchRepository: FirestoreProfileSearchRepository(),
                                               interestRepository: FirestoreInterestRepository()))
        .environmentObject(NavigationCoordinator())
    }
}

@available(iOS 17, *)
private final class ProfileSearchRepositoryStub: ProfileSearchRepository {
    func searchProfiles(filters: SearchFilters, pageSize: Int, cursor: String?) async throws -> ProfileSearchPage {
        let profiles = [
            ProfileSummary(id: "1", displayName: "Aisha", age: 28, location: "Seattle", bio: nil, avatarURL: nil, interests: ["Art", "Travel"]),
            ProfileSummary(id: "2", displayName: "Farah", age: 30, location: "Austin", bio: nil, avatarURL: nil, interests: ["Food", "Outdoors"])
        ]
        return ProfileSearchPage(items: profiles, nextCursor: nil)
    }
}

@available(iOS 17, *)
private final class InterestRepositoryStub: InterestRepository {
    func sendInterest(from userID: String, to targetUserID: String) async throws {}
}

@available(iOS 17, *)
private struct SearchFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var city: String
    @State private var minAgeText: String
    @State private var maxAgeText: String
    @State private var preferredGender: String

    let onApply: (SearchFilters) -> Void
    let onReset: () -> Void

    private let genders = ["Any", "Female", "Male"]

    init(filters: SearchFilters,
         onApply: @escaping (SearchFilters) -> Void,
         onReset: @escaping () -> Void) {
        _city = State(initialValue: filters.city ?? "")
        _minAgeText = State(initialValue: filters.minAge.map(String.init) ?? "")
        _maxAgeText = State(initialValue: filters.maxAge.map(String.init) ?? "")
        _preferredGender = State(initialValue: filters.preferredGender ?? "Any")
        self.onApply = onApply
        self.onReset = onReset
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("City", text: $city)
                        .textInputAutocapitalization(.words)
                }

                Section("Age Range") {
                    HStack {
                        TextField("Min", text: $minAgeText)
                            .keyboardType(.numberPad)
                        Text("-")
                        TextField("Max", text: $maxAgeText)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Preferences") {
                    Picker("Preferred Gender", selection: $preferredGender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(makeFilters())
                    }
                    .disabled(!inputIsValid)
                }

                ToolbarItem(placement: .bottomBar) {
                    Button("Reset") {
                        onReset()
                        dismiss()
                    }
                    .tint(AroosiColors.muted)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var inputIsValid: Bool {
        let minAge = Int(minAgeText)
        let maxAge = Int(maxAgeText)
        if let minAge, let maxAge, minAge > maxAge { return false }
        return true
    }

    private func makeFilters() -> SearchFilters {
        let minAge = Int(minAgeText)
        let maxAge = Int(maxAgeText)
        let gender = preferredGender == "Any" ? nil : preferredGender

        return SearchFilters(query: nil,
                              city: city.isEmpty ? nil : city,
                              minAge: minAge,
                              maxAge: maxAge,
                              preferredGender: gender)
    }
}
#endif
