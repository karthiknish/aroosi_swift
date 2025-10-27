#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: SupportCategory = .general
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var email: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                contactInfoSection
                
                supportFormSection
                
                quickHelpSection
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        submitSupport()
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your message has been sent. We'll get back to you soon!")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView("Sending...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var contactInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AroosiColors.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Get in Touch")
                            .font(AroosiTypography.body(weight: .semibold))
                            .foregroundStyle(AroosiColors.text)
                        
                        Text("We're here to help!")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.muted)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var supportFormSection: some View {
        Section("Your Message") {
            Picker("Category", selection: $selectedCategory) {
                ForEach(SupportCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            
            TextField("Email Address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Subject", text: $subject)
                .textInputAutocapitalization(.sentences)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
                
                TextEditor(text: $message)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AroosiColors.muted.opacity(0.2), lineWidth: 1)
                    )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
    }
    
    private var quickHelpSection: some View {
        Section("Quick Help") {
            NavigationLink {
                FAQView()
            } label: {
                Label("Frequently Asked Questions", systemImage: "questionmark.circle.fill")
            }
            
            NavigationLink {
                if #available(iOS 17, *) {
                    SafetyGuidelinesView()
                }
            } label: {
                Label("Safety Guidelines", systemImage: "shield.fill")
            }
            
            NavigationLink {
                if #available(iOS 17, *) {
                    PrivacyPolicyView()
                }
            } label: {
                Label("Privacy Policy", systemImage: "lock.fill")
            }
            
            NavigationLink {
                if #available(iOS 17, *) {
                    TermsOfServiceView()
                }
            } label: {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !subject.isEmpty &&
        !message.isEmpty &&
        message.count >= 10
    }
    
    private func submitSupport() {
        isSubmitting = true
        errorMessage = nil
        
        // Simulate API call
        Task {
            do {
                try await Task.sleep(for: .seconds(1.5))
                
                // In production, send to support system
                // For now, just show success
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to send message. Please try again."
                }
            }
        }
    }
}

@available(iOS 17, *)
private enum SupportCategory: String, CaseIterable {
    case general = "general"
    case technical = "technical"
    case account = "account"
    case safety = "safety"
    case feature = "feature"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .general: return "General Question"
        case .technical: return "Technical Issue"
        case .account: return "Account Help"
        case .safety: return "Safety Concern"
        case .feature: return "Feature Request"
        case .other: return "Other"
        }
    }
}

@available(iOS 17, *)
private struct FAQView: View {
    var body: some View {
        List {
            ForEach(faqs, id: \.question) { faq in
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(faq.question)
                            .font(AroosiTypography.body(weight: .semibold))
                            .foregroundStyle(AroosiColors.text)
                        
                        Text(faq.answer)
                            .font(AroosiTypography.body())
                            .foregroundStyle(AroosiColors.secondaryText)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var faqs: [FAQ] {
        [
            FAQ(
                question: "How do I create an account?",
                answer: "You can create an account using Sign in with Apple. Your information is kept private and secure."
            ),
            FAQ(
                question: "Is my information safe?",
                answer: "Yes! We use industry-standard encryption and security measures. We never share your personal information without your consent."
            ),
            FAQ(
                question: "How does matching work?",
                answer: "Our AI-powered matching system considers your preferences, values, cultural background, and compatibility factors to suggest potential matches."
            ),
            FAQ(
                question: "What is Family Approval?",
                answer: "Family Approval allows you to involve trusted family members in your search process. They can review matches and provide their input."
            ),
            FAQ(
                question: "How do I report someone?",
                answer: "Tap the three dots menu on any profile and select 'Report'. We review all reports and take appropriate action."
            ),
            FAQ(
                question: "Can I delete my account?",
                answer: "Yes, you can delete your account at any time from Settings > Account > Delete Account. This action is permanent."
            ),
            FAQ(
                question: "How do I block someone?",
                answer: "Tap the three dots menu on their profile and select 'Block'. Blocked users cannot see your profile or contact you."
            ),
            FAQ(
                question: "What is Islamic Education?",
                answer: "Our Islamic Education hub provides resources about marriage in Islam, helping you make informed decisions aligned with your faith."
            ),
            FAQ(
                question: "How do I change my preferences?",
                answer: "Go to Profile > Edit Profile to update your preferences, including age range, location, and other criteria."
            ),
            FAQ(
                question: "Is Aroosi free?",
                answer: "Yes, Aroosi is completely free to use. All core features are available at no cost."
            )
        ]
    }
}

private struct FAQ {
    let question: String
    let answer: String
}

#Preview {
    if #available(iOS 17, *) {
        ContactSupportView()
    }
}
#endif
