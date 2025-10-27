import SwiftUI

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
    
    let userId: String
    let userName: String
    
    public init(userId: String, userName: String) {
        self.userId = userId
        self.userName = userName
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
                CompatibilityScoreView(
                    score: score,
                    user1Name: userName,
                    user2Name: matchUserNames[score.userId2] ?? "Loading..."
                )
                .onAppear {
                    Task {
                        await fetchMatchUserName(for: score.userId2)
                    }
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
                ReportCard(report: report) {
                    showingScore = report.scores
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        // Check if questionnaire is completed
        do {
            let repository = CompatibilityRepository()
            hasCompletedQuestionnaire = try await repository.hasCompletedQuestionnaire(userId: userId)
            
            if hasCompletedQuestionnaire {
                // Load reports
                reports = try await service.fetchReports(userId: userId)
            }
        } catch {
            // Error handled by service state
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
                        Text("Match with User") // TODO: Fetch actual name
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
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
    
    // MARK: - Helper Functions
    
    private func fetchMatchUserName(for userId: String) async {
        guard matchUserNames[userId] == nil else { return } // Already fetched
        
        #if canImport(FirebaseFirestore)
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("users").document(userId).getDocument()
            
            if let data = document.data(),
               let displayName = data["displayName"] as? String {
                await MainActor.run {
                    matchUserNames[userId] = displayName
                }
            }
        } catch {
            print("Failed to fetch user name for \(userId): \(error)")
            await MainActor.run {
                matchUserNames[userId] = "Unknown User"
            }
        }
        #else
        await MainActor.run {
            matchUserNames[userId] = "Match User"
        }
        #endif
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
