#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appVersion: String = ""
    @State private var buildNumber: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    appIcon
                    
                    appInfo
                    
                    featuresList
                    
                    acknowledgements
                    
                    legalLinks
                    
                    copyright
                }
                .padding(20)
            }
            .background(AroosiColors.background)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadVersionInfo()
        }
    }
    
    private var appIcon: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [AroosiColors.primary, AroosiColors.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Text("A")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            Text("Aroosi")
                .font(AroosiTypography.heading(size: 28, weight: .bold))
                .foregroundStyle(AroosiColors.text)
            
            Text("Muslim Matrimony")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var appInfo: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Version", value: appVersion)
            InfoRow(label: "Build", value: buildNumber)
        }
        .padding(16)
        .background(AroosiColors.surface)
        .cornerRadius(12)
    }
    
    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features")
                .font(AroosiTypography.heading(size: 20, weight: .semibold))
                .foregroundStyle(AroosiColors.text)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "person.2.fill", title: "Smart Matching", description: "AI-powered compatibility assessment")
                FeatureRow(icon: "sparkles", title: "Cultural Compatibility", description: "Afghan traditions and values integration")
                FeatureRow(icon: "person.3.fill", title: "Family Approval", description: "Involve family in the process")
                FeatureRow(icon: "book.fill", title: "Islamic Education", description: "Learn about marriage in Islam")
                FeatureRow(icon: "shield.fill", title: "Safety First", description: "Verification and safety features")
                FeatureRow(icon: "lock.fill", title: "Privacy Control", description: "You control your information")
            }
        }
    }
    
    private var acknowledgements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acknowledgements")
                .font(AroosiTypography.heading(size: 20, weight: .semibold))
                .foregroundStyle(AroosiColors.text)
            
            Text("Aroosi is built with love and dedication to help Muslims find their perfect match. We acknowledge the contributions of our community, advisors, and the open-source projects that make this app possible.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Firebase - Backend infrastructure")
                Text("• SwiftUI - Modern UI framework")
                Text("• Community feedback and support")
            }
            .font(AroosiTypography.caption())
            .foregroundStyle(AroosiColors.muted)
        }
    }
    
    private var legalLinks: some View {
        VStack(spacing: 12) {
            NavigationLink {
                if #available(iOS 17, *) {
                    TermsOfServiceView()
                }
            } label: {
                HStack {
                    Text("Terms of Service")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AroosiColors.surface)
            .cornerRadius(8)
            
            NavigationLink {
                if #available(iOS 17, *) {
                    PrivacyPolicyView()
                }
            } label: {
                HStack {
                    Text("Privacy Policy")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AroosiColors.surface)
            .cornerRadius(8)
            
            NavigationLink {
                if #available(iOS 17, *) {
                    SafetyGuidelinesView()
                }
            } label: {
                HStack {
                    Text("Safety Guidelines")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AroosiColors.surface)
            .cornerRadius(8)
        }
    }
    
    private var copyright: some View {
        VStack(spacing: 8) {
            Text("© 2025 Aroosi")
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
            
            Text("Made with ❤️ for the Muslim community")
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
    
    private func loadVersionInfo() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        } else {
            appVersion = "1.0.0"
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            buildNumber = build
        } else {
            buildNumber = "1"
        }
    }
}

@available(iOS 17, *)
private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
            Spacer()
            Text(value)
                .font(AroosiTypography.body(weight: .semibold))
                .foregroundStyle(AroosiColors.text)
        }
    }
}

@available(iOS 17, *)
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AroosiColors.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(AroosiColors.text)
                
                Text(description)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
        }
    }
}

#Preview {
    if #available(iOS 17, *) {
        AboutView()
    }
}
#endif
