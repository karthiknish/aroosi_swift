import SwiftUI

#if canImport(UIKit) && canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
struct QuizView: View {
    let content: IslamicEducationalContent
    let quiz: EducationalQuiz
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: IslamicEducationService
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String: Int] = [:]
    @State private var showResult = false
    @State private var quizResult: QuizResult?
    @State private var showExplanation = false
    
    private var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentQuestionIndex]
    }
    
    private var progress: Double {
        Double(currentQuestionIndex) / Double(quiz.questions.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if showResult {
                    resultView
                } else {
                    quizContentView
                }
            }
            .navigationTitle(quiz.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Quiz Content
    
    private var quizContentView: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: progress)
                .tint(.aroosi)
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let question = currentQuestion {
                        // Question Number
                        Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // Question Text
                        Text(question.question)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        // Options
                        VStack(spacing: 12) {
                            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                OptionButton(
                                    text: option,
                                    isSelected: selectedAnswers[question.id] == index,
                                    action: { selectAnswer(index) }
                                )
                            }
                        }
                        
                        // Explanation (if answer selected)
                        if let selectedIndex = selectedAnswers[question.id],
                           let explanation = question.explanation {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: selectedIndex == question.correctOptionIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(selectedIndex == question.correctOptionIndex ? .green : .red)
                                    Text(selectedIndex == question.correctOptionIndex ? "Correct!" : "Incorrect")
                                        .fontWeight(.medium)
                                }
                                
                                Text(explanation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AroosiColors.mutedSystemBackground)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding()
            }
            
            // Navigation Buttons
            HStack(spacing: 16) {
                if currentQuestionIndex > 0 {
                    Button(action: previousQuestion) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                
                if currentQuestionIndex < quiz.questions.count - 1 {
                    Button(action: nextQuestion) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.aroosi)
                    .disabled(selectedAnswers[currentQuestion?.id ?? ""] == nil)
                } else {
                    Button(action: submitQuiz) {
                        Text("Submit Quiz")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.aroosi)
                    .disabled(selectedAnswers.count != quiz.questions.count)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Result View
    
    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let result = quizResult {
                // Result Icon
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(result.passed ? .green : .red)
                
                // Result Title
                Text(result.passed ? "Congratulations!" : "Keep Learning")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Score
                VStack(spacing: 8) {
                    Text("\(result.score)%")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.aroosi)
                    
                    Text("\(result.correctCount) out of \(result.totalQuestions) correct")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                // Pass/Fail Message
                Text(result.passed ? 
                     "You've successfully completed this quiz!" : 
                     "You need \(quiz.passingScore)% to pass. Try again!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Stats
                HStack(spacing: 30) {
                    StatView(
                        title: "Correct",
                        value: "\(result.correctCount)",
                        color: .green
                    )
                    
                    StatView(
                        title: "Incorrect",
                        value: "\(result.totalQuestions - result.correctCount)",
                        color: .red
                    )
                    
                    StatView(
                        title: "Score",
                        value: "\(result.score)%",
                        color: .aroosi
                    )
                }
                .padding()
                .background(AroosiColors.mutedSystemBackground)
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: retakeQuiz) {
                    Text("Retake Quiz")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.aroosi)
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.aroosi)
            }
            .padding()
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func selectAnswer(_ index: Int) {
        guard let question = currentQuestion else { return }
        withAnimation {
            selectedAnswers[question.id] = index
        }
    }
    
    private func nextQuestion() {
        withAnimation {
            currentQuestionIndex += 1
        }
    }
    
    private func previousQuestion() {
        withAnimation {
            currentQuestionIndex -= 1
        }
    }
    
    private func submitQuiz() {
        guard let userId = authService.currentUser?.uid else { return }
        
        // Convert Int answers to String for service
        let stringAnswers = selectedAnswers.mapValues { String($0) }
        
        Task {
            quizResult = await service.submitQuizAnswers(
                contentId: content.id,
                userId: userId,
                answers: stringAnswers
            )
            
            withAnimation {
                showResult = true
            }
        }
    }
    
    private func retakeQuiz() {
        withAnimation {
            currentQuestionIndex = 0
            selectedAnswers.removeAll()
            showResult = false
            quizResult = nil
        }
    }
}

// MARK: - Option Button

private struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.aroosi : AroosiColors.mutedSystemBackground)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat View

@available(iOS 17.0.0, *)
private struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview {
    QuizView(
        content: IslamicEducationalContent(
            id: "1",
            title: "Marriage in Islam",
            description: "Test your knowledge",
            category: .islamicMarriage,
            contentType: .quiz,
            content: EducationContent(
                sections: [],
                verses: [],
                hadiths: [],
                images: [],
                videos: [],
                thumbnailUrl: nil
            ),
            difficultyLevel: .beginner,
            estimatedReadTime: 5,
            createdAt: Date(),
            updatedAt: Date(),
            author: nil,
            tags: nil,
            isFeatured: false,
            viewCount: nil,
            likeCount: nil,
            bookmarkCount: nil,
            quiz: EducationalQuiz(
                id: "q1",
                title: "Marriage Knowledge Test",
                description: "Test your understanding",
                questions: [
                    QuizQuestion(
                        id: "q1",
                        text: "What is considered half of faith in Islam?",
                        options: [
                            QuizOption(id: "opt1", text: "Prayer"),
                            QuizOption(id: "opt2", text: "Marriage"),
                            QuizOption(id: "opt3", text: "Charity"),
                            QuizOption(id: "opt4", text: "Fasting")
                        ],
                        correctOptionId: "opt2",
                        explanation: "The Prophet (PBUH) said marriage is half of faith."
                    )
                ],
                passingScore: 70
            ),
            relatedContent: nil
        ),
        quiz: EducationalQuiz(
            id: "q1",
            title: "Marriage Knowledge Test",
            description: "Test your understanding",
            questions: [
                QuizQuestion(
                    id: "q1",
                    question: "What is considered half of faith in Islam?",
                    options: ["Prayer", "Marriage", "Charity", "Fasting"],
                    correctOptionIndex: 1,
                    explanation: "The Prophet (PBUH) said marriage is half of faith."
                )
            ],
            passingScore: 70
        )
    )
    .environmentObject(IslamicEducationService())
    
}
#endif
