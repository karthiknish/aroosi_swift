import Foundation

@available(iOS 17, *)
@MainActor
final class SupportCenterViewModel: ObservableObject {
    struct State: Equatable {
        var email: String = ""
        var subject: String = ""
        var message: String = ""
        var category: SupportContactRequest.Category = .general
        var includeDiagnostics: Bool = true
        var isSubmitting: Bool = false
        var errorMessage: String?
        var successMessage: String?
    }

    @Published private(set) var state = State()

    private let repository: SupportRepository
    private let user: UserProfile

    init(user: UserProfile,
         repository: SupportRepository = RemoteSupportRepository()) {
        self.user = user
        self.repository = repository
        state.email = user.email ?? ""
    }

    func updateEmail(_ email: String) {
        state.email = email
    }

    func updateSubject(_ subject: String) {
        state.subject = subject
    }

    func updateMessage(_ message: String) {
        state.message = message
    }

    func updateCategory(_ category: SupportContactRequest.Category) {
        state.category = category
    }

    func updateIncludeDiagnostics(_ include: Bool) {
        state.includeDiagnostics = include
    }

    func submit() async {
        let trimmedMessage = state.message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            state.errorMessage = "Please describe your issue before submitting."
            return
        }

        if !state.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !state.email.isValidEmail {
            state.errorMessage = "Please enter a valid email address."
            return
        }

        state.isSubmitting = true
        state.errorMessage = nil
        state.successMessage = nil

        let metadata = diagnostics()
        let request = SupportContactRequest(
            email: state.email.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            subject: state.subject.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            category: state.category,
            message: trimmedMessage,
            metadata: metadata.isEmpty ? nil : metadata
        )

        do {
            let accepted = try await repository.submitContact(request)
            if accepted {
                state.successMessage = "Thanks for reaching out. We'll reply via email."
                state.message = ""
                state.subject = ""
            } else {
                state.errorMessage = "We couldn't submit your request right now. Please try again or email support@aroosi.app."
            }
        } catch {
            state.errorMessage = "Something went wrong. Please try again later."
        }

        state.isSubmitting = false
    }

    func dismissMessages() {
        state.errorMessage = nil
        state.successMessage = nil
    }

    private func diagnostics() -> [String: String] {
        guard state.includeDiagnostics else { return [:] }
        var metadata: [String: String] = ["platform": "ios-native"]
        metadata["userId"] = user.id
        metadata["displayName"] = user.displayName
        return metadata
    }
}

private extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
