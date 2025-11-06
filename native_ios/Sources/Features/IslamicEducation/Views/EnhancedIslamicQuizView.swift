import SwiftUI

#if canImport(UIKit) && canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
@MainActor
struct EnhancedIslamicQuizView: View {
    let quiz: IslamicQuiz
    @ObservedObject private var quizService: IslamicQuizService
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String: Int] = [:]
    @State private var showResult = false
    @State private var quizResult: IslamicQuizResult?
    @State private var showExplanation = false
    @State private var timeRemaining: Int?
    @State private var timer: Timer?
    @State private var startTime = Date()
    
    @Environment(\.dismiss) private var dismiss
    
    private var currentQuestion: IslamicQuizQuestion? {
        guard currentQuestionIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentQuestionIndex]
    }
    
    private var progress: Double {
        Double(currentQuestionIndex) / Double(quiz.questions.count)
    }
    
    init(quiz: IslamicQuiz, quizService: IslamicQuizService? = nil) {
        self.quiz = quiz
        self.quizService = quizService ?? IslamicQuizService()
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
                        cancelQuiz()
                    }
                }
                
                if let timeRemaining = timeRemaining {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Image(systemName: "clock")
                            Text(formatTime(timeRemaining))
                                .foregroundColor(timeRemaining < 60 ? .red : .primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            startQuiz()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Quiz Content View
    
    private var quizContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Header
                progressHeader
                
                // Question Card
                if let question = currentQuestion {
                    questionCard(question: question)
                }
                
                // Navigation Buttons
                navigationButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Category and Difficulty
            HStack {
                Label(quiz.category.displayName, systemImage: quiz.category.icon)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(quiz.category.color).opacity(0.1))
                    .foregroundColor(Color(quiz.category.color))
                    .clipShape(Capsule())
                
                Spacer()
                
                Label(quiz.difficulty.displayName, systemImage: "star.fill")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(quiz.difficulty.color).opacity(0.1))
                    .foregroundColor(Color(quiz.difficulty.color))
                    .clipShape(Capsule())
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .tint(Color(quiz.category.color))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func questionCard(question: IslamicQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question Text
            VStack(alignment: .leading, spacing: 12) {
                Text(question.question)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Arabic Text (if available)
                if let arabicText = question.arabicText {
                    Text(arabicText)
                        .font(.title2)
                        .foregroundColor(Color(quiz.category.color))
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(quiz.category.color).opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Transliteration (if available)
                if let transliteration = question.transliteration {
                    Text(transliteration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Answer Options
            VStack(spacing: 12) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    AnswerOptionRow(
                        option: question.options[index],
                        index: index,
                        isSelected: selectedAnswers[question.id] == index,
                        onTap: {
                            selectAnswer(for: question.id, answerIndex: index)
                        }
                    )
                }
            }
            
            // Reference (if available)
            if let reference = question.reference {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(Color(quiz.category.color))
                    Text(reference)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous Button
            Button(action: previousQuestion) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(currentQuestionIndex == 0)
            
            // Next/Submit Button
            Button(action: nextQuestion) {
                HStack {
                    Text(isLastQuestion ? "Submit" : "Next")
                    Image(systemName: isLastQuestion ? "checkmark" : "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(quiz.category.color))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedAnswers[currentQuestion?.id ?? ""] == nil)
        }
    }
    
    // MARK: - Result View
    
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let result = quizResult {
                    // Result Header
                    resultHeader(result: result)
                    
                    // Score Details
                    scoreDetails(result: result)
                    
                    // Answer Review
                    answerReview(result: result)
                    
                    // Actions
                    resultActions
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func resultHeader(result: IslamicQuizResult) -> some View {
        VStack(spacing: 16) {
            // Success/Failure Icon
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(result.passed ? .green : .red)
            
            // Title
            Text(result.passed ? "Quiz Completed!" : "Quiz Not Passed")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Score
            Text("\(result.score)%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(result.passed ? .green : .orange)
            
            // Subtitle
            Text("\(result.correctAnswers) out of \(result.totalQuestions) questions correct")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func scoreDetails(result: IslamicQuizResult) -> some View {
        VStack(spacing: 16) {
            Text("Performance Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Time Taken",
                    value: formatTime(result.timeTaken),
                    icon: "clock"
                )
                
                DetailRow(
                    title: "Passing Score",
                    value: "\(quiz.passingScore)%",
                    icon: "target"
                )
                
                DetailRow(
                    title: "Your Score",
                    value: "\(result.score)%",
                    icon: result.passed ? "checkmark.circle" : "xmark.circle",
                    valueColor: result.passed ? .green : .orange
                )
                
                if result.certificateEarned {
                    DetailRow(
                        title: "Certificate",
                        value: "Earned",
                        icon: "badge",
                        valueColor: .green
                    )
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func answerReview(result: IslamicQuizResult) -> some View {
        VStack(spacing: 16) {
            Text("Answer Review")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(0..<quiz.questions.count, id: \.self) { index in
                let question = quiz.questions[index]
                let userAnswer = result.answers[question.id] ?? -1
                let isCorrect = userAnswer == question.correctAnswerIndex
                
                AnswerReviewRow(
                    questionNumber: index + 1,
                    question: question.question,
                    userAnswer: userAnswer >= 0 ? question.options[userAnswer] : "Not answered",
                    correctAnswer: question.options[question.correctAnswerIndex],
                    isCorrect: isCorrect,
                    explanation: question.explanation,
                    showExplanation: $showExplanation
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var resultActions: some View {
        VStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Text("Back to Quizzes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(quiz.category.color))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if quizResult?.passed == true {
                Button(action: {
                    // Share certificate
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Certificate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startQuiz() {
        guard let userId = authService.currentUser?.uid else { return }
        
        startTime = Date()
        quizService.startQuizSession(quiz: quiz, userId: userId)
        
        // Start timer if quiz has time limit
        if let timeLimit = quiz.timeLimit {
            timeRemaining = timeLimit * 60 // Convert to seconds
            startTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let timeRemaining = timeRemaining {
                if timeRemaining > 0 {
                    self.timeRemaining = timeRemaining - 1
                } else {
                    // Time's up - submit quiz
                    submitQuiz()
                }
            }
        }
    }
    
    private func selectAnswer(for questionId: String, answerIndex: Int) {
        selectedAnswers[questionId] = answerIndex
        quizService.submitAnswer(questionId: questionId, answerIndex: answerIndex)
    }
    
    private func nextQuestion() {
        if isLastQuestion {
            submitQuiz()
        } else {
            currentQuestionIndex += 1
        }
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    private func submitQuiz() {
        Task {
            do {
                timer?.invalidate()
                let result = try await quizService.completeQuizSession()
                quizResult = result
                showResult = true
            } catch {
                print("Failed to submit quiz: \(error)")
            }
        }
    }
    
    private func cancelQuiz() {
        timer?.invalidate()
        quizService.cancelQuizSession()
        dismiss()
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex == quiz.questions.count - 1
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Supporting Views

struct AnswerOptionRow: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Option Letter
                Text(String(UnicodeScalar(65 + index)!))
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.blue : Color(.systemGray6))
                    .clipShape(Circle())
                
                // Option Text
                Text(option)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}

struct AnswerReviewRow: View {
    let questionNumber: Int
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let explanation: String?
    @Binding var showExplanation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Header
            HStack {
                Text("Q\(questionNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(isCorrect ? .green : .red)
                    .clipShape(Circle())
                
                Text(question)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            // Answers
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Your answer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(userAnswer)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isCorrect ? .green : .red)
                }
                
                if !isCorrect {
                    HStack {
                        Text("Correct answer:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(correctAnswer)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Explanation
            if let explanation = explanation, showExplanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

@available(iOS 17.0.0, *)
#Preview {
    EnhancedIslamicQuizView(quiz: IslamicQuiz(
        title: "Basic Islamic Knowledge",
        description: "Test your knowledge of fundamental Islamic concepts",
        category: .aqidah,
        difficulty: .beginner,
        questions: [
            IslamicQuizQuestion(
                question: "What is the first pillar of Islam?",
                options: ["Salah", "Shahada", "Zakat", "Sawm"],
                correctAnswerIndex: 1,
                explanation: "The Shahada (declaration of faith) is the first pillar of Islam.",
                reference: "Sahih Bukhari 8",
                category: .aqidah,
                difficulty: .beginner
            )
        ]
    ))
}

#endif
