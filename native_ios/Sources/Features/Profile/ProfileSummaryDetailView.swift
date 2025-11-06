#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct ProfileSummaryDetailView: View {
    @StateObject private var viewModel: ProfileDetailViewModel
    @State private var selectedImageIndex = 0
    @State private var showingReportSheet = false
    @State private var reportReason = ""
    @State private var reportDetails = ""

    init(profileID: String, repository: ProfileRepository = FirestoreProfileRepository()) {
        _viewModel = StateObject(wrappedValue: ProfileDetailViewModel(profileID: profileID, repository: repository))
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            content(width: width)
                .navigationTitle(viewModel.state.detail?.summary.displayName ?? "Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .background(AroosiColors.background)
                .task { await viewModel.loadIfNeeded() }
                .refreshable { await viewModel.refresh() }
                .overlay(alignment: .center) { loadingOverlay }
                .overlay(alignment: .center) { emptyStateOverlay }
                .onChange(of: viewModel.state.detail?.summary.id) { _ in
                    selectedImageIndex = 0
                }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportUserSheet(
                reason: $reportReason,
                details: $reportDetails,
                isSubmitting: viewModel.state.isPerformingSafetyAction,
                onSubmit: {
                    let trimmedReason = reportReason.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedReason.isEmpty else { return }
                    let trimmedDetails = reportDetails.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await viewModel.reportUser(reason: trimmedReason,
                                                   details: trimmedDetails.isEmpty ? nil : trimmedDetails)
                        if viewModel.state.errorMessage == nil {
                            reportReason = ""
                            reportDetails = ""
                            showingReportSheet = false
                        }
                    }
                },
                onCancel: {
                    reportReason = ""
                    reportDetails = ""
                    showingReportSheet = false
                }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if let detail = viewModel.state.detail {
                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: detail.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(detail.isFavorite ? AroosiColors.primary : AroosiColors.text)
                }
                .disabled(viewModel.state.isUpdatingFavorite)

                Button {
                    Task { await viewModel.toggleShortlist() }
                } label: {
                    Image(systemName: detail.isShortlisted ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(detail.isShortlisted ? AroosiColors.primary : AroosiColors.text)
                }
                .disabled(viewModel.state.isUpdatingShortlist)
            }

            Menu {
                Button("Report") {
                    reportReason = ""
                    reportDetails = ""
                    showingReportSheet = true
                }

                if viewModel.state.safetyStatus.isBlocked {
                    Button("Unblock") {
                        Task { await viewModel.unblockUser() }
                    }
                } else {
                    Button(role: .destructive) {
                        Task { await viewModel.blockUser() }
                    } label: {
                        Text("Block")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .semibold))
            }
            .disabled(viewModel.state.isPerformingSafetyAction || viewModel.state.detail == nil)
        }
    }

    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        if let detail = viewModel.state.detail {
            ScrollView {
                VStack(alignment: .leading, spacing: AroosiSpacing.lg) {
                    if let info = viewModel.state.infoMessage {
                        ProfileInlineMessageView(message: info, style: .info)
                            .onTapGesture { viewModel.dismissMessages() }
                    }

                    if let safetyMessage = safetyNotice(for: viewModel.state.safetyStatus) {
                        ProfileInlineMessageView(message: safetyMessage, style: .warning)
                    }

                    if let message = viewModel.state.errorMessage {
                        ProfileInlineMessageView(message: message, style: .error)
                            .onTapGesture { viewModel.dismissMessages() }
                    }

                    gallerySection(detail: detail)
                    headerSection(detail: detail)
                    quickFactsSection(detail: detail, isWide: Responsive.isLargeScreen(width: width))
                    aboutSection(detail: detail)
                    personalitySection(detail: detail)
                    familyBackgroundSection(detail: detail)
                    interestsSection(detail: detail)
                    culturalSection(detail: detail)
                    preferencesSection(detail: detail)
                }
                .padding(Responsive.screenPadding(width: width))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AroosiColors.background)
        } else {
            Color.clear
        }
    }

    private func safetyNotice(for status: SafetyStatus) -> String? {
        if status.isBlocked {
            return "You blocked this member. Unblock to resume interactions."
        }
        if status.isBlockedBy {
            return "This member has blocked you. Messaging and likes are disabled."
        }
        return nil
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.state.isLoading && viewModel.state.detail == nil {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AroosiColors.primary)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var emptyStateOverlay: some View {
        if let message = viewModel.state.errorMessage,
           viewModel.state.detail == nil,
           !viewModel.state.isLoading {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AroosiColors.warning)
                Text(message)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button("Retry") {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(.borderedProminent)
                .tint(AroosiColors.primary)
            }
            .padding()
            .background(AroosiColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    @ViewBuilder
    private func gallerySection(detail: ProfileDetail) -> some View {
        if detail.gallery.isEmpty {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AroosiColors.surfaceSecondary)
                    .frame(height: 260)
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AroosiColors.muted)
            }
        } else {
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $selectedImageIndex) {
                    ForEach(detail.gallery.indices, id: \.self) { index in
                        AsyncImage(url: detail.gallery[index]) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(AroosiColors.primary)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(AroosiColors.muted)
                            @unknown default:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(AroosiColors.muted)
                            }
                        }
                        .tag(index)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .clipped()
                    }
                }
                .frame(height: 260)
                .tabViewStyle(.page(indexDisplayMode: .automatic))

                if detail.gallery.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(detail.gallery.indices, id: \.self) { index in
                            Circle()
                                .fill(index == selectedImageIndex ? AroosiColors.primary : AroosiColors.primary.opacity(0.2))
                                .frame(width: index == selectedImageIndex ? 10 : 8, height: index == selectedImageIndex ? 10 : 8)
                        }
                    }
                    .padding(12)
                }
            }
        }
    }

    private func headerSection(detail: ProfileDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.summary.displayName)
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)

            if let headline = detail.headline?.nonEmpty {
                Text(headline)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
            }

            HStack(spacing: 12) {
                if let age = detail.summary.age {
                    Label("\(age)", systemImage: "calendar")
                }
                if let location = detail.summary.location?.nonEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                }
                if let motherTongue = detail.motherTongue?.nonEmpty {
                    Label(motherTongue, systemImage: "bubble.left.and.bubble.right")
                }
            }
            .font(AroosiTypography.caption())
            .foregroundStyle(AroosiColors.muted)
        }
    }

    @ViewBuilder
    private func quickFactsSection(detail: ProfileDetail, isWide: Bool) -> some View {
        let items = quickFactItems(detail: detail)

        if items.isEmpty {
            EmptyView()
        } else {
            SectionCard(title: "Quick Facts") {
                if isWide {
                    HStack(alignment: .top, spacing: AroosiSpacing.md) {
                        factTiles(items: items)
                    }
                } else {
                    VStack(alignment: .leading, spacing: AroosiSpacing.md) {
                        factTiles(items: items)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func aboutSection(detail: ProfileDetail) -> some View {
        if let about = detail.about?.nonEmpty {
            SectionCard(title: "About") {
                Text(about)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.text)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder
    private func personalitySection(detail: ProfileDetail) -> some View {
        if !detail.personalityTraits.isEmpty {
            SectionCard(title: "Personality Traits") {
                TagCloud(tags: detail.personalityTraits)
            }
        }
    }

    @ViewBuilder
    private func familyBackgroundSection(detail: ProfileDetail) -> some View {
        if let background = detail.familyBackground?.nonEmpty {
            SectionCard(title: "Family Background") {
                Text(background)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.text)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder
    private func interestsSection(detail: ProfileDetail) -> some View {
        if !detail.interests.isEmpty {
            SectionCard(title: "Interests") {
                TagCloud(tags: detail.interests)
            }
        }
    }

    @ViewBuilder
    private func culturalSection(detail: ProfileDetail) -> some View {
        if let cultural = detail.culturalProfile {
            let rows = culturalRows(for: cultural)

            if rows.isEmpty {
                EmptyView()
            } else {
                SectionCard(title: "Cultural Values") {
                    VStack(alignment: .leading, spacing: AroosiSpacing.md) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { item in
                            KeyValueRow(title: item.element.0, value: item.element.1)
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func preferencesSection(detail: ProfileDetail) -> some View {
        if let preferences = detail.preferences {
            let rows = preferenceRows(for: preferences)

            if rows.isEmpty {
                EmptyView()
            } else {
                SectionCard(title: "Match Preferences") {
                    VStack(alignment: .leading, spacing: AroosiSpacing.md) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { item in
                            KeyValueRow(title: item.element.0, value: item.element.1)
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func factTiles(items: [(String, String, String)]) -> some View {
        ForEach(Array(items.enumerated()), id: \.offset) { item in
            factTile(icon: item.element.0, title: item.element.1, value: item.element.2)
        }
    }

    private func factTile(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(AroosiTypography.caption(weight: .medium))
                .foregroundStyle(AroosiColors.muted)
            Text(value)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.text)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quickFactItems(detail: ProfileDetail) -> [(String, String, String)] {
        var items: [(String, String, String)] = []
        if let occupation = detail.occupation?.nonEmpty {
            items.append(("briefcase", "Occupation", occupation))
        }
        if let education = detail.education?.nonEmpty {
            items.append(("graduationcap", "Education", education))
        }
        if !detail.languages.isEmpty {
            items.append(("globe", "Languages", detail.languages.joined(separator: ", ")))
        }
        return items
    }

    private func culturalRows(for cultural: CulturalProfileDetail) -> [(String, String)] {
        var rows: [(String, String)] = []

        if let religion = formattedValue(for: cultural.religion) {
            rows.append(("Religion", religion))
        }
        if let practice = formattedValue(for: cultural.religiousPractice) {
            rows.append(("Religious Practice", practice))
        }
        if let familyValues = formattedValue(for: cultural.familyValues) {
            rows.append(("Family Values", familyValues))
        }
        if let marriageViews = formattedValue(for: cultural.marriageViews) {
            rows.append(("Marriage Views", marriageViews))
        }
        if let traditions = formattedValue(for: cultural.traditionalValues) {
            rows.append(("Traditional Values", traditions))
        }
        if let approval = formattedValue(for: cultural.familyApprovalImportance) {
            rows.append(("Family Approval", approval))
        }
        if let languages = cultural.languages.nonEmptyArray {
            rows.append(("Languages", languages.joined(separator: ", ")))
        }
        if let ethnicity = formattedValue(for: cultural.ethnicity) {
            rows.append(("Ethnicity", ethnicity))
        }
        if let religionImportance = cultural.religionImportance {
            rows.append(("Religion Importance", "\(religionImportance)/10"))
        }
        if let cultureImportance = cultural.cultureImportance {
            rows.append(("Culture Importance", "\(cultureImportance)/10"))
        }
        return rows
    }

    private func preferenceRows(for preferences: MatchPreferencesDetail) -> [(String, String)] {
        var rows: [(String, String)] = []
        if let min = preferences.minAge, let max = preferences.maxAge {
            rows.append(("Preferred Age Range", "\(min)-\(max)"))
        }
        if let location = preferences.location?.nonEmpty {
            rows.append(("Preferred Location", location))
        }
        if let religion = formattedValue(for: preferences.religion) {
            rows.append(("Preferred Religion", religion))
        }
        if let practice = formattedValue(for: preferences.religiousPractice) {
            rows.append(("Religious Practice", practice))
        }
        if let familyValues = formattedValue(for: preferences.familyValues) {
            rows.append(("Family Values", familyValues))
        }
        if let marriage = formattedValue(for: preferences.marriageViews) {
            rows.append(("Marriage Views", marriage))
        }
        return rows
    }

    private func formattedValue(for value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        let replaced = value.replacingOccurrences(of: "_", with: " " ).replacingOccurrences(of: "-", with: " " )
        return replaced.split(separator: " ").map { $0.lowercased().capitalized }.joined(separator: " " )
    }
}

@available(iOS 17, *)
private struct SectionCard<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AroosiSpacing.md) {
            Text(title)
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(AroosiColors.text)
            content()
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

@available(iOS 17, *)
private struct TagCloud: View {
    let tags: [String]

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(AroosiTypography.caption(weight: .semibold))
                    .foregroundStyle(AroosiColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AroosiColors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
}

@available(iOS 17, *)
private struct KeyValueRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AroosiTypography.caption(weight: .medium))
                .foregroundStyle(AroosiColors.muted)
            Text(value)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.text)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 17, *)
private struct ReportUserSheet: View {
    @Binding var reason: String
    @Binding var details: String
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    TextField("e.g. Spam, harassment, fake profile", text: $reason)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Details (optional)") {
                    TextField("Share additional context", text: $details, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Report user")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit", action: onSubmit)
                        .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView("Submitting…")
                        .progressViewStyle(.circular)
                        .tint(AroosiColors.primary)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

@available(iOS 17, *)
private struct ProfileInlineMessageView: View {
    enum Style {
        case info
        case warning
        case error

        var tint: Color {
            switch self {
            case .info:
                return AroosiColors.info
            case .warning:
                return AroosiColors.warning
            case .error:
                return AroosiColors.error
            }
        }

        var icon: String {
            switch self {
            case .info:
                return "info.circle"
            case .warning:
                return "hand.raised"
            case .error:
                return "exclamationmark.triangle"
            }
        }
    }

    let message: String
    let style: Style

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: style.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(style.tint)
            Text(message)
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(style.tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension Array where Element == String {
    var nonEmptyArray: [String]? {
        let cleaned = map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return cleaned.isEmpty ? nil : cleaned
    }
}

#endif
