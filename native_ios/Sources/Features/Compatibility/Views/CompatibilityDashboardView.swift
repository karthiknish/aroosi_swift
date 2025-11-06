import SwiftUI

#if os(iOS)

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@available(iOS 17, *)
public struct CompatibilityDashboardView: View {
    @StateObject private var service = CompatibilityService()
    @State private var showingQuestionnaire = false
    @State private var showingScore: CompatibilityScore? = nil
    @State private var reports: [CompatibilityReport] = []
    @State private var hasCompletedQuestionnaire = false
    @State private var matchUserNames: [String: String] = [:]

    private let profileRepository: (any ProfileRepository)?
    private let logger = Logger.shared

    let userId: String
    let userName: String
    
    public init(
        userId: String,
        userName: String,
        profileRepository: (any ProfileRepository)? = nil
    ) {
        self.userId = userId
        self.userName = userName
        #if canImport(FirebaseFirestore)
        self.profileRepository = profileRepository ?? FirestoreProfileRepository()
        #else
        self.profileRepository = profileRepository
        #endif
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !hasCompletedQuestionnaire {
                        // Prompt to complete questionnaire
                        questionnairePrompt
                    } else {
                        // Reports list
                        if reports.isEmpty {
                            emptyState
                        } else {
                            reportsSection
                        }
                    }
                }
                .padding()
            }
            .background(AroosiColors.background)
            .navigationTitle("Compatibility")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if hasCompletedQuestionnaire {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingQuestionnaire = true
                        } label: {
                            Label("Retake", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingQuestionnaire) {
                CompatibilityQuestionnaireView(userId: userId) {
                    Task {
                        await loadData()
                    }
                }
            }
            .sheet(item: $showingScore) { score in
                let counterpartID = counterpartID(for: score)
                CompatibilityScoreView(
                    score: score,
                    user1Name: userName,
                    user2Name: displayName(for: counterpartID)
                )
                .task {
                    await fetchMatchUserName(for: counterpartID)
                }
            }
        }
    }
    
    // MARK: - Questionnaire Prompt
    
    private var questionnairePrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundStyle(AroosiColors.primary)
            
            VStack(spacing: 12) {
                Text("Complete Your Compatibility Profile")
                    .font(AroosiTypography.heading(.h2))
                    .multilineTextAlignment(.center)
                
                Text("Answer questions about your Islamic values, lifestyle, and preferences to see compatibility scores with your matches.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureBullet(
                    icon: "checkmark.circle.fill",
                    text: "8 categories covering Islamic values"
                )
                FeatureBullet(
                    icon: "checkmark.circle.fill",
                    text: "27 carefully crafted questions"
                )
                FeatureBullet(
                    icon: "checkmark.circle.fill",
                    text: "Takes about 10-15 minutes"
                )
                FeatureBullet(
                    icon: "checkmark.circle.fill",
                    text: "Private and secure"
                )
            }
            .padding()
            .background(AroosiColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Button {
                showingQuestionnaire = true
            } label: {
                HStack {
                    Text("Start Questionnaire")
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AroosiColors.primary)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 50))
                .foregroundStyle(AroosiColors.muted)
            
            Text("No Compatibility Reports Yet")
                .font(AroosiTypography.heading(.h3))
            
            Text("Compatibility scores will appear here when you view matches.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Reports Section
    
    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Compatibility Reports")
                .font(AroosiTypography.heading(.h3))
            
            ForEach(reports) { report in
                let counterpartID = counterpartID(for: report)
                ReportCard(
                    report: report,
                    counterpartName: displayName(for: counterpartID)
                ) {
                    showingScore = report.scores
                }
                .task {
                    await fetchMatchUserName(for: counterpartID)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadData() async {
        // Check if questionnaire is completed
        do {
            let repository = CompatibilityRepository()
            hasCompletedQuestionnaire = try await repository.hasCompletedQuestionnaire(userId: userId)
            
            if hasCompletedQuestionnaire {
                // Load reports
                reports = try await service.fetchReports(userId: userId)
                await ensureMatchNames(for: reports)
            }
        } catch {
            // Error handled by service state
        }
    }

    private func counterpartID(for report: CompatibilityReport) -> String {
        report.userId1 == userId ? report.userId2 : report.userId1
    }

    private func counterpartID(for score: CompatibilityScore) -> String {
        score.userId1 == userId ? score.userId2 : score.userId1
    }

    private func displayName(for counterpartID: String) -> String {
        matchUserNames[counterpartID] ?? "Match"
    }

    @MainActor
    private func ensureMatchNames(for reports: [CompatibilityReport]) async {
        let ids = Set(reports.map { counterpartID(for: $0) }).filter { !$0.isEmpty }
        for id in ids {
            await fetchMatchUserName(for: id)
        }
    }

    @MainActor
    private func fetchMatchUserName(for counterpartID: String) async {
        guard matchUserNames[counterpartID] == nil else { return }

        guard let profileRepository else {
            matchUserNames[counterpartID] = "Match"
            return
        }

        do {
            let profile = try await profileRepository.fetchProfile(id: counterpartID)
            matchUserNames[counterpartID] = profile.displayName
        } catch {
            logger.error("Failed to load match user name for \(counterpartID): \(error.localizedDescription)")
            matchUserNames[counterpartID] = "Match"
        }
    }
}

// MARK: - Feature Bullet

@available(iOS 17.0.0, *)
private struct FeatureBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AroosiColors.success)
            Text(text)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.text)
        }
    }
}

// MARK: - Report Card

@available(iOS 17.0.0, *)
private struct ReportCard: View {
    let report: CompatibilityReport
    let counterpartName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Score circle
                    ZStack {
                        Circle()
                            .fill(scoreColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text("\(Int(report.scores.overallScore))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(counterpartName.isEmpty ? "Match" : counterpartName)
                            .font(AroosiTypography.heading(.h4))
                        
                        Text(report.scores.compatibilityLevel)
                            .font(AroosiTypography.body(weight: .medium))
                            .foregroundStyle(scoreColor)
                        
                        Text(report.generatedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.muted)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AroosiColors.muted)
                }
                
                // Family feedback indicator
                if let feedback = report.familyFeedback, !feedback.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(feedback.count) family feedback")
                            .font(AroosiTypography.caption())
                    }
                    .foregroundStyle(AroosiColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AroosiColors.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding()
            .background(AroosiColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private var scoreColor: Color {
        switch report.scores.overallScore {
        case 80...100:
            return AroosiColors.success
        case 60..<80:
            return AroosiColors.info
        case 40..<60:
            return AroosiColors.warning
        default:
            return AroosiColors.error
        }
    }
    
}

@available(iOS 17, *)
#Preview {
    if #available(iOS 17, *) {
        CompatibilityDashboardView(
            userId: "user123",
            userName: "Aisha"
        )
    }
}

#endif
