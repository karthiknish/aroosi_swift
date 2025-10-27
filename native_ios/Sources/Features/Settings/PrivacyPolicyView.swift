#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct PrivacyPolicyView: View {
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
            .navigationTitle("Privacy Policy")
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
            Text("Privacy Policy")
                .font(AroosiTypography.heading(size: 28, weight: .bold))
                .foregroundStyle(AroosiColors.text)
            
            Text("Your privacy is important to us. This policy explains how we collect, use, and protect your personal information.")
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
    
    private func sectionView(_ section: PrivacySection) -> some View {
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
    
    private var sections: [PrivacySection] {
        [
            PrivacySection(
                title: "1. Information We Collect",
                content: [
                    "We collect information that you provide directly to us, including:",
                    "• Account information (name, email, date of birth, gender)",
                    "• Profile information (photos, bio, interests, preferences)",
                    "• Communications with other users",
                    "• Device information and usage data",
                    "• Location data (with your permission)"
                ]
            ),
            PrivacySection(
                title: "2. How We Use Your Information",
                content: [
                    "We use your information to:",
                    "• Provide and improve our services",
                    "• Create and manage your account",
                    "• Connect you with compatible matches",
                    "• Communicate with you about the App",
                    "• Ensure safety and security",
                    "• Comply with legal obligations",
                    "• Analyze usage patterns and improve features"
                ]
            ),
            PrivacySection(
                title: "3. Information Sharing",
                content: [
                    "We do not sell your personal information. We may share your information:",
                    "• With other users as part of your profile",
                    "• With service providers who help us operate the App",
                    "• When required by law or to protect rights and safety",
                    "• With your consent or at your direction",
                    "All third parties are contractually obligated to protect your information."
                ]
            ),
            PrivacySection(
                title: "4. Data Security",
                content: [
                    "We implement security measures to protect your information:",
                    "• Encryption of data in transit and at rest",
                    "• Regular security audits and updates",
                    "• Access controls and authentication",
                    "• Secure cloud infrastructure",
                    "However, no method of transmission is 100% secure. We cannot guarantee absolute security."
                ]
            ),
            PrivacySection(
                title: "5. Your Privacy Rights",
                content: [
                    "You have the right to:",
                    "• Access your personal information",
                    "• Correct inaccurate information",
                    "• Delete your account and data",
                    "• Opt out of marketing communications",
                    "• Control who sees your profile",
                    "• Export your data",
                    "To exercise these rights, visit your account settings or contact us."
                ]
            ),
            PrivacySection(
                title: "6. Data Retention",
                content: [
                    "We retain your information for as long as your account is active.",
                    "When you delete your account, we remove your information within 30 days.",
                    "Some information may be retained longer if required by law.",
                    "Anonymized usage data may be retained for analytics."
                ]
            ),
            PrivacySection(
                title: "7. Children's Privacy",
                content: [
                    "Aroosi is not intended for users under 18 years of age.",
                    "We do not knowingly collect information from children.",
                    "If we discover that we have collected information from a child, we will delete it immediately.",
                    "Parents who believe we may have information about their child should contact us."
                ]
            ),
            PrivacySection(
                title: "8. International Data Transfers",
                content: [
                    "Your information may be transferred to and stored in countries outside your residence.",
                    "We ensure appropriate safeguards are in place for international transfers.",
                    "By using the App, you consent to these transfers."
                ]
            ),
            PrivacySection(
                title: "9. Cookies and Tracking",
                content: [
                    "We use cookies and similar technologies to:",
                    "• Remember your preferences",
                    "• Analyze usage patterns",
                    "• Improve performance",
                    "• Prevent fraud",
                    "You can control cookies through your device settings."
                ]
            ),
            PrivacySection(
                title: "10. Third-Party Services",
                content: [
                    "The App may contain links to third-party services.",
                    "We are not responsible for their privacy practices.",
                    "We encourage you to read their privacy policies.",
                    "Third-party analytics may be used to improve our services."
                ]
            ),
            PrivacySection(
                title: "11. Changes to This Policy",
                content: [
                    "We may update this Privacy Policy from time to time.",
                    "We will notify you of material changes via the App or email.",
                    "Your continued use after changes constitutes acceptance.",
                    "We encourage you to review this policy periodically."
                ]
            ),
            PrivacySection(
                title: "12. Contact Us",
                content: [
                    "If you have questions about this Privacy Policy or our data practices:",
                    "• Visit the Support section in the App",
                    "• Email our privacy team",
                    "• Submit a request through your account settings",
                    "We are committed to addressing your privacy concerns."
                ]
            ),
            PrivacySection(
                title: "13. California Privacy Rights",
                content: [
                    "California residents have additional rights under CCPA:",
                    "• Right to know what information is collected",
                    "• Right to delete personal information",
                    "• Right to opt-out of data sales (we don't sell data)",
                    "• Right to non-discrimination",
                    "Contact us to exercise these rights."
                ]
            ),
            PrivacySection(
                title: "14. European Privacy Rights",
                content: [
                    "EU residents have rights under GDPR:",
                    "• Right to access and portability",
                    "• Right to rectification",
                    "• Right to erasure",
                    "• Right to restrict processing",
                    "• Right to object",
                    "• Right to withdraw consent",
                    "• Right to lodge a complaint with supervisory authority"
                ]
            )
        ]
    }
}

private struct PrivacySection {
    let title: String
    let content: [String]
}

#Preview {
    if #available(iOS 17, *) {
        PrivacyPolicyView()
    }
}
#endif
