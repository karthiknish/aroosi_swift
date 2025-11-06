import SwiftUI

#if os(iOS)

@available(iOS 17, *)
public struct CompatibilityQuestionnaireView: View {
    @StateObject private var service = CompatibilityService()
    @State private var currentCategoryIndex = 0
    @State private var currentQuestionIndex = 0
    @State private var selectedOptions: Set<String> = []
    @State private var selectedOption: String? = nil
    @State private var showingCompletion = false
    @State private var showingError = false
    @Environment(\.dismiss) private var dismiss
    
    let userId: String
    let onComplete: () -> Void
    
    private let categories = IslamicCompatibilityQuestions.getCategories()
    
    private var currentCategory: IslamicCompatibilityCategory {
        categories[currentCategoryIndex]
    }
    
    private var currentQuestion: CompatibilityQuestion {
        currentCategory.questions[currentQuestionIndex]
    }
    
    private var isLastQuestionInCategory: Bool {
        currentQuestionIndex == currentCategory.questions.count - 1
    }
    
    private var isLastCategory: Bool {
        currentCategoryIndex == categories.count - 1
    }
    
    private var canProceed: Bool {
        if currentQuestion.type == .multipleChoice {
            return !selectedOptions.isEmpty
        } else {
            return selectedOption != nil
        }
    }
    
    public init(userId: String, onComplete: @escaping () -> Void) {
        self.userId = userId
        self.onComplete = onComplete
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: service.progress / 100)
                    .tint(AroosiColors.primary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Category header
                        categoryHeader
                        
                        // Question
                        questionView
                        
                        // Options
                        optionsView
                    }
                    .padding()
                }
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Compatibility Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = service.error {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showingCompletion) {
                CompletionView(userId: userId) {
                    dismiss()
                    onComplete()
                }
            }
            .task {
                await service.loadUserResponse(userId: userId)
                loadCurrentAnswer()
            }
        }
    }
    
    // MARK: - Category Header
    
    private var categoryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category progress
            HStack {
                Text("Category \(currentCategoryIndex + 1) of \(categories.count)")
                    .font(AroosiTypography.caption(weight: .medium))
                    .foregroundStyle(AroosiColors.muted)
                Spacer()
                Text("\(Int(service.progress))% Complete")
                    .font(AroosiTypography.caption(weight: .semibold))
                    .foregroundStyle(AroosiColors.primary)
            }
            
            // Category name
            Text(currentCategory.name)
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)
            
            // Category description
            Text(currentCategory.description)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
        }
        .padding()
        .background(AroosiColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(currentCategory.questions.count)")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
                
                if currentQuestion.isRequired {
                    Text("Required")
                        .font(AroosiTypography.caption(weight: .semibold))
                        .foregroundStyle(AroosiColors.warning)
                }
            }
            
            Text(currentQuestion.text)
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(AroosiColors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Options View
    
    @ViewBuilder
    private var optionsView: some View {
        switch currentQuestion.type {
        case .singleChoice, .yesNo, .scale:
            singleChoiceOptions
        case .multipleChoice:
            multipleChoiceOptions
        }
    }
    
    private var singleChoiceOptions: some View {
        VStack(spacing: 12) {
            ForEach(currentQuestion.options) { option in
                OptionButton(
                    text: option.text,
                    isSelected: selectedOption == option.id
                ) {
                    selectedOption = option.id
                }
            }
        }
    }
    
    private var multipleChoiceOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select all that apply")
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
            
            ForEach(currentQuestion.options) { option in
                CheckboxButton(
                    text: option.text,
                    isSelected: selectedOptions.contains(option.id)
                ) {
                    if selectedOptions.contains(option.id) {
                        selectedOptions.remove(option.id)
                    } else {
                        selectedOptions.insert(option.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentQuestionIndex > 0 || currentCategoryIndex > 0 {
                Button {
                    goToPreviousQuestion()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AroosiColors.muted)
            }
            
            Button {
                goToNextQuestion()
            } label: {
                HStack {
                    Text(isLastQuestionInCategory && isLastCategory ? "Complete" : "Next")
                    if !isLastQuestionInCategory || !isLastCategory {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AroosiColors.primary)
            .disabled(!canProceed)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Navigation Logic
    
    private func goToNextQuestion() {
        // Save current answer
        saveCurrentAnswer()
        
        // Check if last question
        if isLastQuestionInCategory && isLastCategory {
            submitQuestionnaire()
        } else if isLastQuestionInCategory {
            // Move to next category
            currentCategoryIndex += 1
            currentQuestionIndex = 0
            loadCurrentAnswer()
        } else {
            // Move to next question
            currentQuestionIndex += 1
            loadCurrentAnswer()
        }
    }
    
    private func goToPreviousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        } else if currentCategoryIndex > 0 {
            currentCategoryIndex -= 1
            currentQuestionIndex = categories[currentCategoryIndex].questions.count - 1
        }
        loadCurrentAnswer()
    }
    
    private func saveCurrentAnswer() {
        let value: ResponseValue
        
        if currentQuestion.type == .multipleChoice {
            value = .multiple(Array(selectedOptions))
        } else if let selected = selectedOption {
            value = .single(selected)
        } else {
            return
        }
        
        service.saveResponse(questionId: currentQuestion.id, value: value)
    }
    
    private func loadCurrentAnswer() {
        // Clear selections
        selectedOption = nil
        selectedOptions.removeAll()
        
        // Load saved answer if exists
        if let savedValue = service.responseState.responses[currentQuestion.id] {
            switch savedValue {
            case .single(let value):
                selectedOption = value
            case .multiple(let values):
                selectedOptions = Set(values)
            }
        }
    }
    
    private func submitQuestionnaire() {
        Task {
            do {
                try await service.submitQuestionnaire(userId: userId)
                showingCompletion = true
            } catch {
                showingError = true
            }
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
                    .font(AroosiTypography.body())
                    .foregroundStyle(isSelected ? .white : AroosiColors.text)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? AroosiColors.primary : AroosiColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AroosiColors.primary : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Checkbox Button

private struct CheckboxButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AroosiColors.primary : AroosiColors.muted)
                
                Text(text)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.text)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(AroosiColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completion View

@available(iOS 17.0, *)
private struct CompletionView: View {
    let userId: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AroosiColors.success)
            
            VStack(spacing: 12) {
                Text("Questionnaire Complete!")
                    .font(AroosiTypography.heading(.h2))
                
                Text("Your compatibility profile has been saved. You can now see compatibility scores with your matches.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AroosiColors.primary)
        }
        .padding()
    }
}

@available(iOS 17, *)
#Preview {
    CompatibilityQuestionnaireView(userId: "user123") {
        // Questionnaire completed
    }
}

#endif
