#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct AppStoreInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appVersion: String = ""
    @State private var buildNumber: String = ""
    @State private var deviceInfo: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    appHeaderSection
                    
                    // Version Information
                    versionSection
                    
                    // App Store Compliance
                    complianceSection
                    
                    // Privacy & Security
                    privacySection
                    
                    // Legal Information
                    legalSection
                    
                    // Support
                    supportSection
                    
                    // Technical Information
                    technicalSection
                }
                .padding(20)
            }
            .background(AroosiColors.groupedBackground)
            .navigationTitle("App Information")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            loadAppInfo()
        }
    }
    
    private var appHeaderSection: some View {
        VStack(spacing: 16) {
            // App Icon
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [AroosiColors.primary, AroosiColors.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    VStack(spacing: 4) {
                        Text("A")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("roosi")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .shadow(color: AroosiColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Aroosi")
                    .font(AroosiTypography.heading(.h2))
                    .foregroundStyle(AroosiColors.text)
                
                Text("Cultural Dating & Family Connections")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var versionSection: some View {
        VStack(spacing: 16) {
            Text("Version Information")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                InfoRow(label: "App Version", value: appVersion)
                InfoRow(label: "Build Number", value: buildNumber)
                InfoRow(label: "Release Date", value: "October 2025")
                InfoRow(label: "Platform", value: "iOS 17.0+")
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var complianceSection: some View {
        VStack(spacing: 16) {
            Text("App Store Compliance")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ComplianceRow(
                    icon: "checkmark.shield.fill",
                    title: "Privacy Policy",
                    description: "Comprehensive privacy policy available",
                    status: .compliant
                )
                
                ComplianceRow(
                    icon: "checkmark.shield.fill",
                    title: "Terms of Service",
                    description: "Complete terms and conditions",
                    status: .compliant
                )
                
                ComplianceRow(
                    icon: "checkmark.shield.fill",
                    title: "Data Collection",
                    description: "Transparent data usage disclosure",
                    status: .compliant
                )
                
                ComplianceRow(
                    icon: "checkmark.shield.fill",
                    title: "Age Rating",
                    description: "Rated 17+ for mature content",
                    status: .compliant
                )
                
                ComplianceRow(
                    icon: "checkmark.shield.fill",
                    title: "Permissions",
                    description: "All permissions properly disclosed",
                    status: .compliant
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var privacySection: some View {
        VStack(spacing: 16) {
            Text("Privacy & Security")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                PrivacyRow(
                    icon: "lock.fill",
                    title: "End-to-End Encryption",
                    description: "Messages and calls are encrypted"
                )
                
                PrivacyRow(
                    icon: "shield.fill",
                    title: "Data Protection",
                    description: "Your data is protected and never sold"
                )
                
                PrivacyRow(
                    icon: "eye.slash.fill",
                    title: "Privacy Controls",
                    description: "You control what you share"
                )
                
                PrivacyRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Profile Verification",
                    description: "Optional verification for authenticity"
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var legalSection: some View {
        VStack(spacing: 16) {
            Text("Legal Information")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                LegalRow(
                    icon: "doc.text.fill",
                    title: "Privacy Policy",
                    subtitle: "How we collect and use your data"
                ) {
                    // Navigate to privacy policy
                }
                
                LegalRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    subtitle: "Rules and guidelines for using Aroosi"
                ) {
                    // Navigate to terms of service
                }
                
                LegalRow(
                    icon: "doc.text.fill",
                    title: "Community Guidelines",
                    subtitle: "Behavioral expectations and safety"
                ) {
                    // Navigate to community guidelines
                }
                
                LegalRow(
                    icon: "doc.text.fill",
                    title: "Cookie Policy",
                    subtitle: "How we use cookies and tracking"
                ) {
                    // Navigate to cookie policy
                }
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var supportSection: some View {
        VStack(spacing: 16) {
            Text("Support & Contact")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SupportRow(
                    icon: "envelope.fill",
                    title: "Email Support",
                    value: "support@aroosi.app"
                )
                
                SupportRow(
                    icon: "globe",
                    title: "Website",
                    value: "www.aroosi.app"
                )
                
                SupportRow(
                    icon: "questionmark.circle.fill",
                    title: "Help Center",
                    value: "help.aroosi.app"
                )
                
                SupportRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Report a Concern",
                    value: "safety@aroosi.app"
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var technicalSection: some View {
        VStack(spacing: 16) {
            Text("Technical Information")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                InfoRow(label: "Device", value: deviceInfo)
                InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                InfoRow(label: "Architecture", value: "arm64")
                InfoRow(label: "Language", value: Locale.current.languageCode ?? "en")
                InfoRow(label: "Region", value: Locale.current.regionCode ?? "US")
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func loadAppInfo() {
        // Load version information
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
        
        // Load device information
        let device = UIDevice.current
        deviceInfo = "\(device.model) (\(device.name))"
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
            
            Spacer()
            
            Text(value)
                .font(AroosiTypography.body(weight: .medium))
                .foregroundStyle(AroosiColors.text)
        }
    }
}

enum ComplianceStatus {
    case compliant
    case warning
    case error
    
    var color: Color {
        switch self {
        case .compliant:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .compliant:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
}

struct ComplianceRow: View {
    let icon: String
    let title: String
    let description: String
    let status: ComplianceStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(status.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AroosiTypography.body(weight: .medium))
                    .foregroundStyle(AroosiColors.text)
                
                Text(description)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
            
            Spacer()
            
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundStyle(status.color)
        }
    }
}

struct PrivacyRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AroosiColors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AroosiTypography.body(weight: .medium))
                    .foregroundStyle(AroosiColors.text)
                
                Text(description)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
            
            Spacer()
        }
    }
}

struct LegalRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AroosiColors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AroosiTypography.body(weight: .medium))
                        .foregroundStyle(AroosiColors.text)
                    
                    Text(subtitle)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AroosiColors.muted)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SupportRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AroosiColors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AroosiTypography.body(weight: .medium))
                    .foregroundStyle(AroosiColors.text)
                
                Text(value)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.primary)
            }
            
            Spacer()
        }
    }
}

@available(iOS 17, *)
#Preview {
    AppStoreInfoView()
        .environmentObject(NavigationCoordinator())
}

#endif
