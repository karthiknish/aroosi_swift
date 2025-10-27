import SwiftUI

#if os(iOS)
@available(iOS 17, *)
struct CulturalMatchingView: View {
    let user: UserProfile
    @StateObject private var viewModel: CulturalMatchingViewModel

    @MainActor
    init(user: UserProfile, viewModel: CulturalMatchingViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? CulturalMatchingViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        if let profile = viewModel.state.profile {
                            profileSummary(profile)
                        }

                        preferencesSection

                        matchesHeader

                    if viewModel.state.recommendations.isEmpty && !viewModel.state.isLoading {
                            emptyRecommendations
                        } else {
                            VStack(spacing: 16) {
                            ForEach(viewModel.state.recommendations, id: \.id) { recommendation in
                                    CulturalMatchCard(user: user, recommendation: recommendation)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Responsive.screenPadding(width: proxy.size.width))
                }
                .background(AroosiColors.background)
                .refreshable { viewModel.refresh() }
                .overlay { loadingOverlay }
                .alert("Heads up", isPresented: Binding(
                    get: { viewModel.state.errorMessage != nil },
                    set: { isPresented in if !isPresented { viewModel.dismissError() } }
                )) {
                    Button("OK", role: .cancel) { viewModel.dismissError() }
                } message: {
                    Text(viewModel.state.errorMessage ?? "")
                }
            }
            .navigationTitle("Cultural Matches")
        }
        .task(id: user.id) {
            viewModel.load(for: user.id)
        }
    }

    private func profileSummary(_ profile: CulturalProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Cultural Profile")
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                if let religion = profile.religion?.nonEmpty {
                    summaryRow(icon: "sparkles", label: "Religion", value: religion)
                }
                if let motherTongue = profile.motherTongue?.nonEmpty {
                    summaryRow(icon: "character.book.closed", label: "Mother Tongue", value: motherTongue)
                }
                if let familyValues = profile.familyValues?.nonEmpty {
                    summaryRow(icon: "person.3.column", label: "Family Values", value: familyValues)
                }
                if let marriageViews = profile.marriageViews?.nonEmpty {
                    summaryRow(icon: "heart.text.square", label: "Marriage Views", value: marriageViews)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            LinearGradient(colors: [AroosiColors.primary, AroosiColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(AroosiColors.primary)
                Text("Matching Preferences")
                    .font(AroosiTypography.heading(.h3))
            }

            if let profile = viewModel.state.profile {
                let preferences = preferencePairs(from: profile)
                ForEach(preferences, id: \.label) { item in
                    PreferenceRow(label: item.label, value: item.value)
                }
            } else {
                Text("Complete your cultural assessment to receive tailored matches.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
            }

            NavigationLink {
                Text("Assessment coming soon")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AroosiColors.background)
            } label: {
                Label("Update Preferences", systemImage: "pencil")
                    .font(AroosiTypography.caption(weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(AroosiColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var matchesHeader: some View {
        HStack {
            Text("Cultural Matches")
                .font(AroosiTypography.heading(.h2))
            Spacer()
            if let updated = viewModel.state.lastUpdated {
                Text("Updated \(updated, style: .time)")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
        }
    }

    private var emptyRecommendations: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundStyle(AroosiColors.warning)
            Text("No cultural matches yet")
                .font(AroosiTypography.heading(.h3))
            Text("Answer more cultural questions to help us find better matches for you.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var loadingOverlay: some View {
        Group {
            if viewModel.state.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.9))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AroosiTypography.caption(weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text(value)
                    .font(AroosiTypography.body(weight: .semibold, size: 16))
                    .foregroundStyle(.white)
            }
        }
    }

    private func preferencePairs(from profile: CulturalProfile) -> [(label: String, value: String)] {
        var items: [(String, String)] = []
        if let religion = profile.religion?.nonEmpty { items.append(("Religion", religion)) }
        if let practice = profile.religiousPractice?.nonEmpty { items.append(("Practice", practice)) }
        if let language = profile.motherTongue?.nonEmpty { items.append(("Mother Tongue", language)) }
        if !profile.languages.isEmpty { items.append(("Speaks", profile.languages.joined(separator: ", "))) }
        if let values = profile.familyValues?.nonEmpty { items.append(("Family Values", values)) }
        if let marriage = profile.marriageViews?.nonEmpty { items.append(("Marriage Views", marriage)) }
        if let traditions = profile.traditionalValues?.nonEmpty { items.append(("Traditions", traditions)) }
        if let approval = profile.familyApprovalImportance?.nonEmpty { items.append(("Family Approval", approval)) }
        return items
    }
}

@available(iOS 17, *)
private struct PreferenceRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(AroosiTypography.caption(weight: .medium))
                .foregroundStyle(AroosiColors.muted)
            Spacer()
            Text(value)
                .font(AroosiTypography.body(weight: .semibold, size: 16))
        }
        .padding(.vertical, 8)
    }
}

@available(iOS 17, *)
private struct CulturalMatchCard: View {
    let user: UserProfile
    let recommendation: CulturalRecommendation

    var body: some View {
        NavigationLink {
            CulturalCompatibilityView(primaryUserID: user.id, targetUserID: recommendation.id)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                header
                compatibilitySection
                factorsSection
                actionRow
            }
            .padding()
            .background(AroosiColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(spacing: 16) {
            AvatarView(url: recommendation.profile.avatarURL)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.profile.displayName)
                    .font(AroosiTypography.heading(.h3))
                    .foregroundStyle(AroosiColors.text)
                if let age = recommendation.profile.age {
                    Text("\(age) years")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
                if let location = recommendation.profile.location?.nonEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }

            Spacer()

            CompatibilityBadge(score: recommendation.compatibilityScore)
        }
    }

    private var compatibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cultural Alignment")
                .font(AroosiTypography.caption(weight: .semibold))
                .foregroundStyle(AroosiColors.muted)

            compatibilityRow(label: "Religion", score: recommendation.breakdown.religion, weight: 40)
            compatibilityRow(label: "Language", score: recommendation.breakdown.language, weight: 20)
            compatibilityRow(label: "Values", score: recommendation.breakdown.values, weight: 25)
            compatibilityRow(label: "Family", score: recommendation.breakdown.family, weight: 15)
        }
    }

    private func compatibilityRow(label: String, score: Int, weight: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(label) (\(weight)%)")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
                Spacer()
                Text("\(score)%")
                    .font(AroosiTypography.caption(weight: .medium))
            }

            ProgressView(value: Double(score) / 100.0)
                .progressViewStyle(.linear)
                .tint(color(for: score))
        }
    }

    private func color(for score: Int) -> Color {
        if score >= 80 { return AroosiColors.success }
        if score >= 60 { return AroosiColors.warning }
        return AroosiColors.error
    }

    private var factorsSection: some View {
        Group {
            if !recommendation.matchingFactors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shared highlights")
                        .font(AroosiTypography.caption(weight: .semibold))
                        .foregroundStyle(AroosiColors.muted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recommendation.matchingFactors.prefix(6), id: \.self) { factor in
                                Text(factor)
                                    .font(AroosiTypography.caption(weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AroosiColors.primary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var actionRow: some View {
        HStack {
            NavigationLink {
                ProfileSummaryDetailView(profileID: recommendation.id)
            } label: {
                Label("View Profile", systemImage: "person.crop.circle")
                    .font(AroosiTypography.caption(weight: .semibold))
            }
            .buttonStyle(.borderless)

            Spacer()

            Label("See Compatibility", systemImage: "chart.bar")
                .font(AroosiTypography.caption(weight: .semibold))
                .foregroundStyle(AroosiColors.primary)
        }
    }
}

@available(iOS 17, *)
private struct CompatibilityBadge: View {
    let score: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(score)%")
                .font(AroosiTypography.heading(.h3))
            Text(scoreLabel)
                .font(AroosiTypography.caption(weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var color: Color {
        if score >= 80 { return AroosiColors.success }
        if score >= 60 { return AroosiColors.warning }
        return AroosiColors.error
    }

    private var scoreLabel: String {
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        return "Emerging"
    }
}

@available(iOS 17, *)
private struct AvatarView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            AroosiColors.primary.opacity(0.1)
            Image(systemName: "person.fill")
                .font(.system(size: 24))
                .foregroundStyle(AroosiColors.primary)
        }
    }
}

#endif
