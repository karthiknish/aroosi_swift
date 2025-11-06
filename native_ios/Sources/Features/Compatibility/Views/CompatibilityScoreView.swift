import SwiftUI
import Charts

#if os(iOS)

@available(iOS 17, *)
public struct CompatibilityScoreView: View {
    let score: CompatibilityScore
    let user1Name: String
    let user2Name: String
    @State private var animateScore = false
    @Environment(\.dismiss) private var dismiss
    
    public init(score: CompatibilityScore, user1Name: String, user2Name: String) {
        self.score = score
        self.user1Name = user1Name
        self.user2Name = user2Name
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall score card
                    overallScoreCard
                    
                    // Compatibility level description
                    descriptionCard
                    
                    // Category breakdown
                    categoryBreakdown
                    
                    // Detailed insights
                    insightsSection
                }
                .padding()
            }
            .background(AroosiColors.background)
            .navigationTitle("Compatibility Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                    animateScore = true
                }
            }
        }
    }
    
    // MARK: - Overall Score Card
    
    private var overallScoreCard: some View {
        VStack(spacing: 20) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: animateScore ? CGFloat(score.overallScore / 100) : 0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(animateScore ? score.overallScore : 0))")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    
                    Text("out of 100")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            // Level badge
            Text(score.compatibilityLevel)
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(scoreColor)
            
            // User names
            HStack(spacing: 8) {
                Text(user1Name)
                    .font(AroosiTypography.body(weight: .semibold))
                Image(systemName: "heart.fill")
                    .foregroundStyle(AroosiColors.primary)
                Text(user2Name)
                    .font(AroosiTypography.body(weight: .semibold))
            }
            .foregroundStyle(AroosiColors.text)
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Description Card
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(AroosiColors.primary)
                Text("What This Means")
                    .font(AroosiTypography.heading(.h3))
            }
            
            Text(score.compatibilityDescription)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Scores")
                .font(AroosiTypography.heading(.h3))
            
            let categories = IslamicCompatibilityQuestions.getCategories()
            
            ForEach(categories) { category in
                if let categoryScore = score.categoryScores[category.id] {
                    CategoryScoreRow(
                        category: category,
                        score: categoryScore,
                        animate: animateScore
                    )
                }
            }
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(AroosiTypography.heading(.h3))
            
            let categories = IslamicCompatibilityQuestions.getCategories()
            let sortedCategories = categories.sorted { category1, category2 in
                let score1 = score.categoryScores[category1.id] ?? 0
                let score2 = score.categoryScores[category2.id] ?? 0
                return score1 > score2
            }
            
            // Top strength
            if let topCategory = sortedCategories.first,
               let topScore = score.categoryScores[topCategory.id] {
                InsightCard(
                    icon: "star.fill",
                    title: "Top Strength",
                    subtitle: topCategory.name,
                    score: topScore,
                    color: .green
                )
            }
            
            // Area for discussion
            if let lowestCategory = sortedCategories.last,
               let lowestScore = score.categoryScores[lowestCategory.id],
               lowestScore < 0.7 {
                InsightCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Area for Discussion",
                    subtitle: lowestCategory.name,
                    score: lowestScore,
                    color: .orange
                )
            }
            
            // Balanced match indicator
            let scoreVariance = calculateVariance(scores: Array(score.categoryScores.values))
            if scoreVariance < 0.05 {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Well-Balanced Match")
                            .font(AroosiTypography.body(weight: .semibold))
                        Text("Consistent compatibility across all areas")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.muted)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Helpers
    
    private var scoreColor: Color {
        switch score.overallScore {
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
    
    private func calculateVariance(scores: [Double]) -> Double {
        guard !scores.isEmpty else { return 0 }
        let mean = scores.reduce(0, +) / Double(scores.count)
        let squaredDifferences = scores.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(scores.count)
    }
}

// MARK: - Category Score Row

@available(iOS 17, *)
private struct CategoryScoreRow: View {
    let category: IslamicCompatibilityCategory
    let score: Double
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(AroosiTypography.body(weight: .semibold))
                Spacer()
                Text("\(Int(score * 100))%")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(scoreColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: animate ? geometry.size.width * CGFloat(score) : 0, height: 8)
                        .clipShape(Capsule())
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0:
            return AroosiColors.success
        case 0.6..<0.8:
            return AroosiColors.info
        case 0.4..<0.6:
            return AroosiColors.warning
        default:
            return AroosiColors.error
        }
    }
}

// MARK: - Insight Card

@available(iOS 17, *)
private struct InsightCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let score: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AroosiTypography.caption(weight: .medium))
                    .foregroundStyle(AroosiColors.muted)
                Text(subtitle)
                    .font(AroosiTypography.body(weight: .semibold))
                Text("\(Int(score * 100))% compatibility")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

@available(iOS 17, *)
#Preview {
    CompatibilityScoreView(
        score: CompatibilityScore(
            userId1: "user1",
            userId2: "user2",
            overallScore: 85.5,
            categoryScores: [
                "religious_practice": 0.90,
                "family_structure": 0.85,
                "cultural_values": 0.80,
                "financial_management": 0.88,
                "education_career": 0.82,
                "social_life": 0.84,
                "conflict_resolution": 0.86,
                "life_goals": 0.89
            ],
            calculatedAt: Date()
        ),
        user1Name: "Aisha",
        user2Name: "Mohammad"
    )
}

#endif
