#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    
                    ForEach(sections, id: \.title) { section in
                        sectionView(section)
                    }
                    
                    lastUpdated
                }
                .padding(20)
            }
            .background(AroosiColors.background)
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms of Service")
                .font(AroosiTypography.heading(size: 28, weight: .bold))
                .foregroundStyle(AroosiColors.text)
            
            Text("Please read these terms carefully before using Aroosi.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
        }
    }
    
    private var lastUpdated: some View {
        Text("Last Updated: October 25, 2025")
            .font(AroosiTypography.caption())
            .foregroundStyle(AroosiColors.muted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 24)
    }
    
    private func sectionView(_ section: TermsSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(AroosiTypography.heading(size: 20, weight: .semibold))
                .foregroundStyle(AroosiColors.text)
            
            ForEach(section.content, id: \.self) { paragraph in
                Text(paragraph)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var sections: [TermsSection] {
        [
            TermsSection(
                title: "1. Acceptance of Terms",
                content: [
                    "By accessing and using Aroosi (the \"App\"), you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.",
                    "We reserve the right to modify these terms at any time. Your continued use of the App after changes constitutes acceptance of the modified terms."
                ]
            ),
            TermsSection(
                title: "2. Eligibility",
                content: [
                    "You must be at least 18 years old to use Aroosi.",
                    "You must be legally able to enter into a binding contract.",
                    "You agree to provide accurate and truthful information about yourself."
                ]
            ),
            TermsSection(
                title: "3. Account Responsibilities",
                content: [
                    "You are responsible for maintaining the confidentiality of your account credentials.",
                    "You are responsible for all activities that occur under your account.",
                    "You must immediately notify us of any unauthorized use of your account.",
                    "We reserve the right to terminate accounts that violate these terms."
                ]
            ),
            TermsSection(
                title: "4. User Conduct",
                content: [
                    "You agree not to use the App for any unlawful purpose.",
                    "You will not harass, abuse, or harm other users.",
                    "You will not impersonate any person or entity.",
                    "You will not post false, misleading, or fraudulent content.",
                    "You will not engage in commercial activities without our permission."
                ]
            ),
            TermsSection(
                title: "5. Content Guidelines",
                content: [
                    "You retain ownership of content you post, but grant us a license to use it.",
                    "Content must not be offensive, inappropriate, or violate any laws.",
                    "We reserve the right to remove any content that violates our guidelines.",
                    "You are solely responsible for your content and its consequences."
                ]
            ),
            TermsSection(
                title: "6. Privacy",
                content: [
                    "Your use of the App is also governed by our Privacy Policy.",
                    "We collect, use, and protect your data as described in our Privacy Policy.",
                    "You consent to our data practices by using the App."
                ]
            ),
            TermsSection(
                title: "7. Intellectual Property",
                content: [
                    "The App and its content are protected by copyright and other intellectual property laws.",
                    "You may not copy, modify, or distribute our content without permission.",
                    "Aroosi and related logos are trademarks owned by us."
                ]
            ),
            TermsSection(
                title: "8. Disclaimer of Warranties",
                content: [
                    "The App is provided \"as is\" without warranties of any kind.",
                    "We do not guarantee that the App will be error-free or uninterrupted.",
                    "We are not responsible for the conduct of users you meet through the App.",
                    "You use the App at your own risk."
                ]
            ),
            TermsSection(
                title: "9. Limitation of Liability",
                content: [
                    "We are not liable for any damages arising from your use of the App.",
                    "This includes direct, indirect, incidental, and consequential damages.",
                    "Some jurisdictions do not allow limitations of liability, so this may not apply to you."
                ]
            ),
            TermsSection(
                title: "10. Termination",
                content: [
                    "You may delete your account at any time.",
                    "We may suspend or terminate your account for violating these terms.",
                    "Upon termination, your right to use the App ceases immediately."
                ]
            ),
            TermsSection(
                title: "11. Dispute Resolution",
                content: [
                    "Any disputes will be resolved through binding arbitration.",
                    "You waive your right to participate in class action lawsuits.",
                    "These terms are governed by the laws of the United States."
                ]
            ),
            TermsSection(
                title: "12. Contact Information",
                content: [
                    "If you have questions about these terms, please contact us through the App's support section or via email.",
                    "We are committed to addressing your concerns promptly."
                ]
            )
        ]
    }
}

private struct TermsSection {
    let title: String
    let content: [String]
}

#Preview {
    if #available(iOS 17, *) {
        TermsOfServiceView()
    }
}
#endif
