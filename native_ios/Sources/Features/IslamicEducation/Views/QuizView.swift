import SwiftUI

#if canImport(UIKit) && canImport(FirebaseFirestore)

@available(iOS 17.0, *)
struct QuizView: View {
    let content: IslamicEducationalContent
    let quiz: EducationalQuiz

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: IslamicEducationService
    @EnvironmentObject private var authService: AuthenticationService

    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String: String] = [:]
    @State private var showResult = false
    @State private var quizResult: QuizResult?

    private var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentQuestionIndex]
    }

    private var progress: Double {
        guard quiz.questions.count > 0 else { return 0 }
        return Double(currentQuestionIndex) / Double(quiz.questions.count)
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
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Quiz Content

    private var quizContentView: some View {
        VStack(spacing: 0) {
            ProgressView(value: progress)
                .tint(.aroosi)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let question = currentQuestion {
                        Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(question.text)
                            .font(.title3)
                            .fontWeight(.semibold)

                        VStack(spacing: 12) {
                            ForEach(question.options) { option in
                                OptionButton(
                                    option: option,
                                    isSelected: selectedAnswers[question.id] == option.id,
                                    action: { selectAnswer(option.id) }
                                )
                            }
                        }

                        if let explanation = question.explanation,
                           let selectedId = selectedAnswers[question.id] {
                            let isCorrect = selectedId == question.correctOptionId
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(isCorrect ? .green : .red)
                                    Text(isCorrect ? "Correct!" : "Incorrect")
                                        .fontWeight(.medium)
                                }

                                Text(explanation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AroosiColors.mutedSystemBackground)
                            )
                            .transition(.opacity)
                        }
                    }
                }
                .padding()
            }

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
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(result.passed ? .green : .red)

                Text(result.passed ? "Congratulations!" : "Keep Learning")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 8) {
                    Text("\(result.score)%")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.aroosi)

                    Text("\(result.correctCount) out of \(result.totalQuestions) correct")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Text(result.passed ? "You've successfully completed this quiz!" : "You need \(quiz.passingScore)% to pass. Try again!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 30) {
                    StatView(title: "Correct", value: "\(result.correctCount)", color: .green)
                    StatView(title: "Incorrect", value: "\(result.totalQuestions - result.correctCount)", color: .red)
                    StatView(title: "Score", value: "\(result.score)%", color: .aroosi)
                }
                .padding()
                .background(AroosiColors.mutedSystemBackground)
                .cornerRadius(12)

                answerReview
            }

            Spacer()

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

    private var answerReview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Answers")
                .font(.headline)

            ForEach(Array(quiz.questions.enumerated()), id: \.element.id) { index, question in
                let selectedId = selectedAnswers[question.id]
                let userAnswer = question.options.first(where: { $0.id == selectedId })?.text ?? "Not answered"
                let correctAnswer = question.options.first(where: { $0.id == question.correctOptionId })?.text ?? ""
                let isCorrect = selectedId == question.correctOptionId

                AnswerReviewRow(
                    questionNumber: index + 1,
                    question: question.text,
                    userAnswer: userAnswer,
                    correctAnswer: correctAnswer,
                    isCorrect: isCorrect,
                    explanation: question.explanation
                )
            }
        }
        .padding()
        .background(AroosiColors.mutedSystemBackground)
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func selectAnswer(_ optionId: String) {
        guard let question = currentQuestion else { return }
        withAnimation {
            selectedAnswers[question.id] = optionId
        }
    }

    private func nextQuestion() {
        withAnimation { currentQuestionIndex += 1 }
    }

    private func previousQuestion() {
        withAnimation { currentQuestionIndex = max(currentQuestionIndex - 1, 0) }
    }

    private func submitQuiz() {
        guard let userId = authService.currentUser?.uid else { return }

        Task {
            let result = await service.submitQuizAnswers(
                contentId: content.id,
                userId: userId,
                answers: selectedAnswers
            )

            withAnimation {
                quizResult = result
                showResult = true
            }
        }
    }

    private func retakeQuiz() {
        withAnimation {
            currentQuestionIndex = 0
            selectedAnswers.removeAll()
            quizResult = nil
            showResult = false
        }
    }
}

// MARK: - Option Button

private struct OptionButton: View {
    let option: QuizOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.text)
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat View

@available(iOS 17.0, *)
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

private struct QuizAnswerReviewRow: View {
    let questionNumber: Int
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let explanation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Q\(questionNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(isCorrect ? Color.green : Color.red)
                    .clipShape(Circle())

                Text(question)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
            }

            Text("Your answer: \(userAnswer)")
                .font(.caption)
                .foregroundStyle(isCorrect ? .green : .secondary)

            if !isCorrect {
                Text("Correct answer: \(correctAnswer)")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            if let explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

#endif
