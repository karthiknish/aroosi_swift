import SwiftUI

#if os(iOS)
@available(iOS 17, *)
struct CulturalCompatibilityView: View {
    let primaryUserID: String
    let targetUserID: String
    @StateObject private var viewModel: CulturalCompatibilityViewModel

    @MainActor
    init(primaryUserID: String,
         targetUserID: String,
         viewModel: CulturalCompatibilityViewModel? = nil) {
        self.primaryUserID = primaryUserID
        self.targetUserID = targetUserID
        let resolvedViewModel = viewModel ?? CulturalCompatibilityViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    if let report = viewModel.state.report {
                        scoreHero(report)
                        dimensionsSection(report)
                        insightsSection(report)
                    } else if !viewModel.state.isLoading {
                        emptyState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Responsive.screenPadding(width: proxy.size.width))
            }
            .background(AroosiColors.background)
            .refreshable { viewModel.refresh(primaryUserID: primaryUserID, targetUserID: targetUserID) }
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
        .navigationTitle("Compatibility")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .task {
            viewModel.load(primaryUserID: primaryUserID, targetUserID: targetUserID)
        }
    }

    private func scoreHero(_ report: CulturalCompatibilityReport) -> some View {
        VStack(spacing: 16) {
            Text("Overall Cultural Compatibility")
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(.white.opacity(0.9))

            Text("\(report.overallScore)%")
                .font(AroosiTypography.heading(.h1))
                .foregroundStyle(.white)

            ProgressView(value: Double(report.overallScore) / 100.0)
                .progressViewStyle(.linear)
                .tint(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(colors: [AroosiColors.primary, AroosiColors.secondary.opacity(0.8)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func dimensionsSection(_ report: CulturalCompatibilityReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compatibility Breakdown")
                .font(AroosiTypography.heading(.h3))

            ForEach(report.dimensions) { dimension in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(dimension.label)
                            .font(AroosiTypography.body(weight: .semibold, size: 16))
                        Spacer()
                        Text("\(dimension.score)%")
                            .font(AroosiTypography.caption(weight: .medium))
                    }

                    ProgressView(value: Double(dimension.score) / 100.0)
                        .progressViewStyle(.linear)
                        .tint(color(for: dimension.score))

                    if let description = dimension.description?.nonEmpty {
                        Text(description)
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.muted)
                    }
                }
                .padding()
                .background(AroosiColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func insightsSection(_ report: CulturalCompatibilityReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(AroosiTypography.heading(.h3))

            if report.insights.isEmpty {
                Text("We are gathering more insights based on your cultural preferences.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(report.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkle")
                                .foregroundStyle(AroosiColors.primary)
                            Text(insight)
                                .font(AroosiTypography.body())
                                .foregroundStyle(AroosiColors.text)
                        }
                        .padding()
                        .background(AroosiColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(AroosiColors.warning)
            Text("Compatibility report unavailable")
                .font(AroosiTypography.heading(.h3))
            Text("We couldn't find enough data to generate a full cultural compatibility report.")
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

    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                viewModel.refresh(primaryUserID: primaryUserID, targetUserID: targetUserID)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }

    private func color(for score: Int) -> Color {
        if score >= 80 { return AroosiColors.success }
        if score >= 60 { return AroosiColors.warning }
        return AroosiColors.error
    }
}

#endif
