#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct DataUsagePolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Data Collection
                    dataCollectionSection
                    
                    // Data Usage
                    dataUsageSection
                    
                    // Data Sharing
                    dataSharingSection
                    
                    // Data Storage
                    dataStorageSection
                    
                    // User Rights
                    userRightsSection
                    
                    // Contact Information
                    contactSection
                }
                .padding(20)
            }
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Data Usage Policy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 50))
                .foregroundStyle(AroosiColors.primary)
            
            VStack(spacing: 8) {
                Text("Data Usage Policy")
                    .font(AroosiTypography.heading(.h2))
                    .foregroundStyle(AroosiColors.text)
                
                Text("How we collect, use, and protect your data")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var dataCollectionSection: some View {
        VStack(spacing: 16) {
            Text("Data We Collect")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DataCollectionItem(
                    icon: "person.fill",
                    title: "Personal Information",
                    description: "Name, email, phone number, date of birth, gender",
                    category: .required
                )
                
                DataCollectionItem(
                    icon: "photo.fill",
                    title: "Profile Data",
                    description: "Photos, bio, interests, preferences, location",
                    category: .optional
                )
                
                DataCollectionItem(
                    icon: "message.fill",
                    title: "Communication Data",
                    description: "Messages, calls, voice notes, shared media",
                    category: .required
                )
                
                DataCollectionItem(
                    icon: "location.fill",
                    title: "Location Data",
                    description: "Current location, city, region for matching",
                    category: .optional
                )
                
                DataCollectionItem(
                    icon: "gear.fill",
                    title: "Usage Data",
                    description: "App usage patterns, preferences, interactions",
                    category: .automatic
                )
                
                DataCollectionItem(
                    icon: "smartphone.fill",
                    title: "Device Data",
                    description: "Device type, OS version, unique identifiers",
                    category: .automatic
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var dataUsageSection: some View {
        VStack(spacing: 16) {
            Text("How We Use Your Data")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DataUsageItem(
                    icon: "heart.fill",
                    title: "Matching & Connections",
                    description: "To find compatible matches and facilitate connections"
                )
                
                DataUsageItem(
                    icon: "message.fill",
                    title: "Communication",
                    description: "To enable messaging, calls, and media sharing"
                )
                
                DataUsageItem(
                    icon: "shield.fill",
                    title: "Safety & Security",
                    description: "To verify profiles and prevent fraud"
                )
                
                DataUsageItem(
                    icon: "chart.bar.fill",
                    title: "Service Improvement",
                    description: "To analyze usage and improve our services"
                )
                
                DataUsageItem(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "To send relevant updates and notifications"
                )
                
                DataUsageItem(
                    icon: "questionmark.circle.fill",
                    title: "Customer Support",
                    description: "To provide help and resolve issues"
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var dataSharingSection: some View {
        VStack(spacing: 16) {
            Text("Data Sharing & Disclosure")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DataSharingItem(
                    icon: "person.2.fill",
                    title: "Other Users",
                    description: "Your profile is shared with potential matches",
                    type: .necessary
                )
                
                DataSharingItem(
                    icon: "building.2.fill",
                    title: "Service Providers",
                    description: "Third-party services for hosting, analytics, support",
                    type: .limited
                )
                
                DataSharingItem(
                    icon: "gavel.fill",
                    title: "Legal Requirements",
                    description: "When required by law or to protect rights",
                    type: .legal
                )
                
                DataSharingItem(
                    icon: "arrow.left.arrow.right.fill",
                    title: "Business Transfers",
                    description: "In case of merger, acquisition, or sale",
                    type: .potential
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var dataStorageSection: some View {
        VStack(spacing: 16) {
            Text("Data Storage & Security")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                DataStorageItem(
                    icon: "server.rack.fill",
                    title: "Cloud Storage",
                    description: "Data stored on secure cloud servers with encryption"
                )
                
                DataStorageItem(
                    icon: "lock.shield.fill",
                    title: "Encryption",
                    description: "Data encrypted in transit and at rest"
                )
                
                DataStorageItem(
                    icon: "clock.fill",
                    title: "Retention Period",
                    description: "Data retained as long as needed for service provision"
                )
                
                DataStorageItem(
                    icon: "trash.fill",
                    title: "Data Deletion",
                    description: "Data deleted upon account deletion or request"
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var userRightsSection: some View {
        VStack(spacing: 16) {
            Text("Your Rights & Choices")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                UserRightItem(
                    icon: "eye.fill",
                    title: "Access & Review",
                    description: "View and download your personal data"
                )
                
                UserRightItem(
                    icon: "pencil.fill",
                    title: "Correction & Updates",
                    description: "Update or correct your personal information"
                )
                
                UserRightItem(
                    icon: "trash.fill",
                    title: "Deletion",
                    description: "Request deletion of your personal data"
                )
                
                UserRightItem(
                    icon: "gear.fill",
                    title: "Privacy Controls",
                    description: "Control data collection and usage preferences"
                )
                
                UserRightItem(
                    icon: "xmark.circle.fill",
                    title: "Opt-Out",
                    description: "Opt out of marketing communications and tracking"
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var contactSection: some View {
        VStack(spacing: 16) {
            Text("Questions About Your Data?")
                .font(AroosiTypography.heading(.h4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ContactItem(
                    icon: "envelope.fill",
                    title: "Privacy Team",
                    value: "privacy@aroosi.app"
                )
                
                ContactItem(
                    icon: "questionmark.circle.fill",
                    title: "Data Protection Officer",
                    value: "dpo@aroosi.app"
                )
                
                ContactItem(
                    icon: "globe",
                    title: "Privacy Center",
                    value: "privacy.aroosi.app"
                )
            }
        }
        .padding(20)
        .background(AroosiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

enum DataCategory {
    case required
    case optional
    case automatic
    
    var color: Color {
        switch self {
        case .required:
            return .red
        case .optional:
            return .orange
        case .automatic:
            return .blue
        }
    }
    
    var label: String {
        switch self {
        case .required:
            return "Required"
        case .optional:
            return "Optional"
        case .automatic:
            return "Automatic"
        }
    }
}

struct DataCollectionItem: View {
    let icon: String
    let title: String
    let description: String
    let category: DataCategory
    
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
            
            Text(category.label)
                .font(AroosiTypography.caption(weight: .medium))
                .foregroundStyle(category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(category.color.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

struct DataUsageItem: View {
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

enum SharingType {
    case necessary
    case limited
    case legal
    case potential
    
    var color: Color {
        switch self {
        case .necessary:
            return .green
        case .limited:
            return .orange
        case .legal:
            return .red
        case .potential:
            return .gray
        }
    }
    
    var label: String {
        switch self {
        case .necessary:
            return "Necessary"
        case .limited:
            return "Limited"
        case .legal:
            return "Legal"
        case .potential:
            return "Potential"
        }
    }
}

struct DataSharingItem: View {
    let icon: String
    let title: String
    let description: String
    let type: SharingType
    
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
            
            Text(type.label)
                .font(AroosiTypography.caption(weight: .medium))
                .foregroundStyle(type.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(type.color.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

struct DataStorageItem: View {
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

struct UserRightItem: View {
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

struct ContactItem: View {
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
    DataUsagePolicyView()
        .environmentObject(NavigationCoordinator())
}

#endif
