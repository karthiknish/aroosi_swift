import SwiftUI

#if canImport(UIKit) && canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
struct IslamicQuizManagementView: View {
    @StateObject private var quizService = IslamicQuizService()
    @StateObject private var uploadService = IslamicQuizUploadService()
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var selectedCategory: QuizCategory?
    @State private var selectedDifficulty: QuizDifficulty?
    @State private var showUploadConfirmation = false
    @State private var isUploading = false
    @State private var uploadMessage = ""
    @State private var selectedQuiz: IslamicQuiz?
    @State private var showQuizDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Filters
                filterSection
                
                // Content
                if quizService.isLoading {
                    loadingView
                } else if let error = quizService.error {
                    errorView(error)
                } else {
                    quizContent
                }
            }
            .navigationTitle("Islamic Quizzes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Upload Sample Quizzes") {
                            showUploadConfirmation = true
                        }
                        
                        Button("Refresh Quizzes") {
                            Task {
                                await loadQuizzes()
                            }
                        }
                        
                        if let userId = authService.currentUser?.uid {
                            Button("My Progress") {
                                // Navigate to user progress
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadQuizzes()
                if let userId = authService.currentUser?.uid {
                    await quizService.loadUserProfile(userId: userId)
                }
            }
        }
        .sheet(isPresented: $showQuizDetail) {
            if let quiz = selectedQuiz {
                EnhancedIslamicQuizView(quiz: quiz, quizService: quizService)
            }
        }
        .alert("Upload Quizzes", isPresented: $showUploadConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Upload") {
                Task {
                    await uploadSampleQuizzes()
                }
            }
        } message: {
            Text("This will upload sample Islamic quizzes to Firebase. Continue?")
        }
        .alert("Upload Status", isPresented: .constant(!uploadMessage.isEmpty)) {
            Button("OK") {
                uploadMessage = ""
            }
        } message: {
            Text(uploadMessage)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Islamic Education")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Test your knowledge of Islam")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let profile = quizService.userProfile {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(profile.totalQuizzesTaken)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Quizzes Taken")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Featured Quizzes Scroll
            if !quizService.featuredQuizzes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(quizService.featuredQuizzes.prefix(3)) { quiz in
                            FeaturedQuizCard(quiz: quiz) {
                                selectedQuiz = quiz
                                showQuizDetail = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryFilterChip(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        color: .gray
                    ) {
                        selectedCategory = nil
                        Task { await loadQuizzes() }
                    }
                    
                    ForEach(QuizCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category,
                            color: Color(category.color)
                        ) {
                            selectedCategory = category
                            Task { await loadQuizzes() }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Difficulty Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    DifficultyFilterChip(
                        title: "All",
                        isSelected: selectedDifficulty == nil
                    ) {
                        selectedDifficulty = nil
                        Task { await loadQuizzes() }
                    }
                    
                    ForEach(QuizDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyFilterChip(
                            title: difficulty.displayName,
                            isSelected: selectedDifficulty == difficulty,
                            color: Color(difficulty.color)
                        ) {
                            selectedDifficulty = difficulty
                            Task { await loadQuizzes() }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Quiz Content
    
    private var quizContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(quizService.availableQuizzes) { quiz in
                    QuizCard(quiz: quiz) {
                        selectedQuiz = quiz
                        showQuizDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading Islamic quizzes...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to load quizzes")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await loadQuizzes()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func loadQuizzes() async {
        await quizService.loadAvailableQuizzes(
            category: selectedCategory,
            difficulty: selectedDifficulty
        )
        await quizService.loadFeaturedQuizzes()
    }
    
    private func uploadSampleQuizzes() async {
        isUploading = true
        
        do {
            try await uploadService.uploadSampleQuizzes()
            uploadMessage = "Successfully uploaded sample quizzes to Firebase!"
            
            // Refresh quizzes after upload
            await loadQuizzes()
            
        } catch {
            uploadMessage = "Failed to upload quizzes: \(error.localizedDescription)"
        }
        
        isUploading = false
    }
}

// MARK: - Supporting Views

struct FeaturedQuizCard: View {
    let quiz: IslamicQuiz
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: quiz.category.icon)
                        .foregroundColor(Color(quiz.category.color))
                    
                    Spacer()
                    
                    Text("\(quiz.questions.count) questions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(quiz.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(quiz.difficulty.displayName)
                    .font(.caption2)
                    .foregroundColor(Color(quiz.difficulty.color))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(quiz.difficulty.color).opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(12)
            .frame(width: 160)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color = .blue
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuizCard: View {
    let quiz: IslamicQuiz
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quiz.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(quiz.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: quiz.category.icon)
                            .font(.title2)
                            .foregroundColor(Color(quiz.category.color))
                        
                        Text(quiz.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Details
                HStack {
                    Label("\(quiz.questions.count)", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(quiz.difficulty.displayName, systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(Color(quiz.difficulty.color))
                    
                    Spacer()
                    
                    if let timeLimit = quiz.timeLimit {
                        Label("\(timeLimit) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress Bar (if user has taken this quiz)
                // This would show user's previous score
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

@available(iOS 17.0.0, *)
#Preview {
    NavigationStack {
        IslamicQuizManagementView()
            .environmentObject(MockAuthenticationService())
    }
}

// Enhanced Mock Authentication Service for Preview
@available(iOS 17.0.0, *)
class MockAuthenticationService: AuthenticationService {
    @Published var currentUser: User? = User.preview
    @Published var isAuthenticated = true
    @Published var isLoading = false
    @Published var error: Error? = nil
    
    // Mock user database for realistic preview behavior
    private let mockUsers: [String: User] = [
        "aisha.khan@example.com": User.preview,
        "fatima.ali@example.com": User(
            id: "preview-user-456",
            email: "fatima.ali@example.com",
            displayName: "Fatima Ali",
            photoURL: URL(string: "https://storage.googleapis.com/aroosi-app/avatars/fatima-preview.jpg"),
            isEmailVerified: true,
            createdAt: Date().addingTimeInterval(-45 * 24 * 60 * 60),
            lastLoginAt: Date().addingTimeInterval(-1 * 60 * 60)
        )
    ]
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if let user = mockUsers[email] {
            currentUser = user
            isAuthenticated = true
        } else {
            throw MockAuthError.invalidCredentials
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        // Create new user for preview
        let newUser = User(
            id: "preview-user-\(UUID().uuidString.prefix(8))",
            email: email,
            displayName: email.components(separatedBy: "@").first?.capitalized ?? "New User",
            photoURL: nil,
            isEmailVerified: false,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        currentUser = newUser
        isAuthenticated = true
        isLoading = false
    }
    
    func signOut() async throws {
        isLoading = true
        try await Task.sleep(nanoseconds: 200_000_000)
        
        currentUser = nil
        isAuthenticated = false
        isLoading = false
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        try await Task.sleep(nanoseconds: 300_000_000)
        isLoading = false
        // In preview, just simulate success
    }
    
    // Additional preview-specific methods
    func switchToUser(_ email: String) {
        if let user = mockUsers[email] {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    func simulateAuthError() {
        error = MockAuthError.networkError
    }
}

// Mock auth errors for realistic preview behavior
enum MockAuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case emailAlreadyInUse
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection failed"
        case .emailAlreadyInUse:
            return "Email address is already in use"
        }
    }
}

#endif
