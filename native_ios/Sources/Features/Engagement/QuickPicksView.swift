#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct QuickPicksView: View {
    let user: UserProfile
    @StateObject private var viewModel: QuickPicksViewModel

    @State private var showingDatePicker = false
    @State private var selectedDate = Date()

    @MainActor
    init(user: UserProfile, viewModel: QuickPicksViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? QuickPicksViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AroosiColors.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Quick Picks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .task { await viewModel.load() }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showingDatePicker = true
            } label: {
                Image(systemName: "calendar")
            }
            .disabled(viewModel.state.isLoading)

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.state.isLoading)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: AroosiSpacing.lg) {
            if let message = viewModel.state.errorMessage {
                MessageBanner(message: message, style: .error)
                    .onTapGesture { viewModel.dismissMessages() }
            } else if let info = viewModel.state.infoMessage {
                MessageBanner(message: info, style: .info)
                    .onTapGesture { viewModel.dismissMessages() }
            }

            if viewModel.state.isLoading {
                ProgressView("Loading quick picks…")
                    .progressViewStyle(.circular)
                    .tint(AroosiColors.primary)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if let recommendation = viewModel.state.currentRecommendation {
                ScrollView {
                    VStack(spacing: AroosiSpacing.lg) {
                        heroCard(for: recommendation)
                        actionsSection
                        upcomingSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(AroosiColors.primary)
                    Text("You're all caught up!")
                        .font(AroosiTypography.heading(.h3))
                    Text("Check back later for new matches.")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.muted)
                }
                .padding()
            }
        }
        .padding(.top, AroosiSpacing.lg)
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Choose Day",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingDatePicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            showingDatePicker = false
                            Task {
                                let formatter = DateFormatter()
                                formatter.locale = Locale(identifier: "en_US_POSIX")
                                formatter.dateFormat = "yyyyMMdd"
                                let key = formatter.string(from: selectedDate)
                                await viewModel.load(dayKey: key)
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func heroCard(for recommendation: QuickPickRecommendation) -> some View {
        let profile = recommendation.profile
        let compatibility = viewModel.state.compatibility(for: recommendation.id)

        return GeometryReader { proxy in
            let width = proxy.size.width
            
            VStack(alignment: .leading, spacing: Responsive.spacing(width: width)) {
                ZStack(alignment: .bottomLeading) {
                    ResponsiveMediaFrame(
                        width: width,
                        type: .banner,
                        aspectRatio: nil
                    ) {
                        if let url = profile.avatarURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(AroosiColors.primary)
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                case .failure:
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(AroosiColors.muted)
                                @unknown default:
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(AroosiColors.muted)
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(AroosiColors.muted)
                                .frame(width: Responsive.frameSize(for: width, type: .mediumSquare).width)
                        }
                    }

                    if let compatibility {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Compatibility \(compatibility)%")
                        }
                        .font(AroosiTypography.caption(weight: .semibold, width: width))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, Responsive.spacing(width: width, multiplier: 1.2))
                        .padding(.vertical, Responsive.spacing(width: width, multiplier: 0.6))
                    .background(AroosiColors.primary.opacity(0.85), in: Capsule())
                    .padding(16)
                }
            }

            VStack(alignment: .leading, spacing: Responsive.spacing(width: width, multiplier: 0.6)) {
                Text(profile.displayName)
                    .font(AroosiTypography.heading(.h2, width: width))
                HStack(spacing: Responsive.spacing(width: width, multiplier: 0.8)) {
                    if let age = profile.age {
                        Label("\(age)", systemImage: "calendar")
                    }
                    if let location = profile.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.and.ellipse")
                    }
                }
                .font(AroosiTypography.caption(width: width))
                .foregroundStyle(AroosiColors.muted)
            }

            NavigationLink {
                ProfileSummaryDetailView(profileID: profile.id)
            } label: {
                ResponsiveButton(
                    title: "View Profile",
                    action: {},
                    style: .primary,
                    width: width
                )
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Daily likes: \(viewModel.state.likesUsed)/\(viewModel.state.dailyLimit)")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(viewModel.state.canLikeCurrent ? AroosiColors.muted : AroosiColors.warning)
                Spacer()
            }

            HStack(spacing: 16) {
                Button {
                    Task { await viewModel.skipCurrent() }
                } label: {
                    Label("Skip", systemImage: "xmark")
                        .font(AroosiTypography.body(weight: .semibold, size: 15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(AroosiColors.muted)
                .disabled(viewModel.state.isPerformingAction || viewModel.state.currentRecommendation == nil)

                Button {
                    Task { await viewModel.likeCurrent() }
                } label: {
                    Label("Like", systemImage: "heart.fill")
                        .font(AroosiTypography.body(weight: .semibold, size: 15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AroosiColors.primary)
                .disabled(viewModel.state.isPerformingAction || !viewModel.state.canLikeCurrent || viewModel.state.currentRecommendation == nil)
            }
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        let upcoming = viewModel.state.upcomingRecommendations
        if upcoming.isEmpty { EmptyView() }
        else {
            GeometryReader { proxy in
                let width = proxy.size.width
                
                ResponsiveVStack(alignment: .leading, width: width) {
                    Text("Next Up")
                        .font(AroosiTypography.heading(.h3, width: width))
                    ScrollView(.horizontal, showsIndicators: false) {
                        ResponsiveHStack(spacing: Responsive.spacing(width: width), width: width) {
                            ForEach(upcoming) { item in
                                VStack(alignment: .leading, spacing: Responsive.spacing(width: width, multiplier: 0.5)) {
                                    ResponsiveMediaFrame(
                                        width: Responsive.frameSize(for: width, type: .mediumSquare).width,
                                        type: .card
                                    ) {
                                        if let url = item.profile.avatarURL {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .progressViewStyle(.circular)
                                                        .tint(AroosiColors.primary)
                                                case .success(let image):
                                                    image.resizable().scaledToFill()
                                                case .failure:
                                                    Image(systemName: "person.crop.circle")
                                                        .resizable().scaledToFit()
                                                        .foregroundStyle(AroosiColors.muted)
                                                @unknown default:
                                                    Image(systemName: "person.crop.circle")
                                                        .resizable().scaledToFit()
                                                        .foregroundStyle(AroosiColors.muted)
                                                }
                                            }
                                        } else {
                                            Image(systemName: "person.crop.circle")
                                                .resizable().scaledToFit()
                                                .foregroundStyle(AroosiColors.muted)
                                                .frame(width: Responsive.frameSize(for: width, type: .smallSquare).width)
                                        }
                                    }

                                Text(item.profile.displayName)
                                    .font(AroosiTypography.body(weight: .semibold, size: 15, width: width))
                                if let location = item.profile.location, !location.isEmpty {
                                    Text(location)
                                        .font(AroosiTypography.caption(width: width))
                                        .foregroundStyle(AroosiColors.muted)
                                }
                            }
                            .frame(width: Responsive.frameSize(for: width, type: .mediumSquare).width, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    @available(iOS 17, *)
    private struct MessageBanner: View {
        enum Style {
            case info
            case error

            var tint: Color {
                switch self {
                case .info:
                    return AroosiColors.info
                case .error:
                    return AroosiColors.error
                }
            }

            var icon: String {
                switch self {
                case .info:
                    return "info.circle"
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
}
#endif
