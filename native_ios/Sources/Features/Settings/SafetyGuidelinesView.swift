#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct SafetyGuidelinesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    
                    emergencyCard
                    
                    ForEach(sections, id: \.title) { section in
                        sectionView(section)
                    }
                    
                    reportingCard
                }
                .padding(20)
            }
            .background(AroosiColors.background)
            .navigationTitle("Safety Guidelines")
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
            Text("Your Safety Matters")
                .font(AroosiTypography.heading(size: 28, weight: .bold))
                .foregroundStyle(AroosiColors.text)
            
            Text("Please read these important safety guidelines before using Aroosi. Your wellbeing is our priority.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
        }
    }
    
    private var emergencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AroosiColors.error)
                
                Text("In Case of Emergency")
                    .font(AroosiTypography.heading(size: 18, weight: .semibold))
                    .foregroundStyle(AroosiColors.text)
            }
            
            Text("If you feel unsafe or threatened, contact local emergency services immediately. Your safety comes first.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.secondaryText)
        }
        .padding(16)
        .background(AroosiColors.error.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var reportingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AroosiColors.primary)
                
                Text("Report Concerns")
                    .font(AroosiTypography.heading(size: 18, weight: .semibold))
                    .foregroundStyle(AroosiColors.text)
            }
            
            Text("If you encounter suspicious behavior, inappropriate content, or safety concerns, please report it immediately through the App. We review all reports promptly.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.secondaryText)
        }
        .padding(16)
        .background(AroosiColors.primary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func sectionView(_ section: SafetySection) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            ResponsiveVStack(width: width) {
                ResponsiveIconRow(
                    icon: section.icon,
                    title: section.title,
                    width: width
                )
                
                ResponsiveVStack(spacing: Responsive.spacing(width: width, multiplier: 0.6), width: width) {
                    ForEach(section.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: Responsive.spacing(width: width, multiplier: 0.8)) {
                            Text("•")
                                .font(AroosiTypography.body(weight: .bold, width: width))
                                .foregroundStyle(AroosiColors.primary)
                    
                    Text(tip)
                                .font(AroosiTypography.body(width: width))
                                .foregroundStyle(AroosiColors.secondaryText)
                        }
                    }
                }
            }
            .padding(.vertical, Responsive.spacing(width: width, multiplier: 0.5))
        }
    }
    
    private var sections: [SafetySection] {
        [
            SafetySection(
                title: "Protect Your Personal Information",
                icon: "lock.shield.fill",
                tips: [
                    "Never share your full name, address, or phone number in your profile or early messages",
                    "Avoid sharing financial information or sending money to people you meet on the App",
                    "Don't share passwords or login credentials with anyone",
                    "Be cautious about sharing photos that reveal your location or other identifying information",
                    "Use the in-app messaging system until you feel comfortable sharing contact information"
                ]
            ),
            SafetySection(
                title: "Meeting in Person",
                icon: "figure.2.and.child.holdinghands",
                tips: [
                    "Always meet in public places for the first several dates",
                    "Tell a friend or family member about your plans, including where and when you're meeting",
                    "Arrange your own transportation to and from the meeting",
                    "Stay sober and in control during your meeting",
                    "Trust your instincts - if something feels wrong, leave immediately",
                    "Keep your phone charged and with you at all times"
                ]
            ),
            SafetySection(
                title: "Communication Best Practices",
                icon: "bubble.left.and.bubble.right.fill",
                tips: [
                    "Take your time getting to know someone before meeting in person",
                    "Be wary of people who avoid video calls or seem too eager to meet",
                    "Watch for red flags like inconsistent stories or requests for money",
                    "Don't feel pressured to respond immediately or meet up if you're not comfortable",
                    "Report any harassing, threatening, or inappropriate messages"
                ]
            ),
            SafetySection(
                title: "Recognizing Red Flags",
                icon: "flag.fill",
                tips: [
                    "Profiles with limited information or only one photo",
                    "Requests for money, gifts, or financial help",
                    "Overly aggressive or persistent behavior",
                    "Reluctance to meet in person or video chat",
                    "Stories that don't add up or change frequently",
                    "Pressure to move conversations off the App quickly",
                    "Requests for explicit photos or inappropriate content"
                ]
            ),
            SafetySection(
                title: "Online Safety",
                icon: "network",
                tips: [
                    "Use strong, unique passwords for your account",
                    "Enable two-factor authentication if available",
                    "Be careful clicking on links from people you don't know well",
                    "Don't share login credentials for other accounts",
                    "Log out when using shared or public devices",
                    "Keep your app updated to the latest version"
                ]
            ),
            SafetySection(
                title: "Consent and Respect",
                icon: "hand.raised.fill",
                tips: [
                    "Always respect others' boundaries and consent",
                    "Accept 'no' gracefully and don't pressure others",
                    "Treat everyone with dignity and respect",
                    "Don't engage in harassment or abusive behavior",
                    "Report anyone who violates these principles",
                    "Remember that cultural and religious values should be respected"
                ]
            ),
            SafetySection(
                title: "Family Involvement",
                icon: "person.3.fill",
                tips: [
                    "Use the Family Approval feature to involve trusted family members",
                    "Discuss your dating goals and boundaries with family",
                    "Value family input while maintaining your autonomy",
                    "Ensure family members also respect privacy and boundaries",
                    "Be honest with family about your experiences and concerns"
                ]
            ),
            SafetySection(
                title: "Account Security",
                icon: "key.fill",
                tips: [
                    "Review your privacy settings regularly",
                    "Control who can see your profile and information",
                    "Block and report users who make you uncomfortable",
                    "Review your match history and messages periodically",
                    "Delete your account if you no longer wish to use the App"
                ]
            )
        ]
    }
}

private struct SafetySection {
    let title: String
    let icon: String
    let tips: [String]
}

#Preview {
    if #available(iOS 17, *) {
        SafetyGuidelinesView()
    }
}
#endif
