#if os(iOS)
import SwiftUI
import UserNotifications

@available(iOS 17, *)
struct NotificationPreferencesView: View {
    @StateObject private var viewModel: NotificationPreferencesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @MainActor
    init(userID: String) {
        _viewModel = StateObject(wrappedValue: NotificationPreferencesViewModel(userID: userID))
    }
    
    var body: some View {
        NavigationStack {
            List {
                messageNotificationsSection
                matchNotificationsSection
                profileNotificationsSection
                systemNotificationsSection
                quietHoursSection
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.custom(20))
            .scrollContentBackground(.hidden)
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Notification Preferences")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if viewModel.state.isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .top) {
                if let errorMessage = viewModel.state.errorMessage {
                    errorBanner(errorMessage)
                }
            }
            .onAppear {
                viewModel.loadPreferences()
            }
        }
        .tint(AroosiColors.primary)
    }
    
    private var messageNotificationsSection: some View {
        Section("Messages") {
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.newMessageNotificationsEnabled ?? false },
                set: { viewModel.updatePreference(key: .newMessageNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Messages")
                        .font(AroosiTypography.body())
                    Text("Get notified when you receive a new message")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.messageReadReceiptsEnabled ?? false },
                set: { viewModel.updatePreference(key: .messageReadReceiptsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message Read Receipts")
                        .font(AroosiTypography.body())
                    Text("Notify when your messages are read")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.messageSoundEnabled ?? true },
                set: { viewModel.updatePreference(key: .messageSoundEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message Sounds")
                        .font(AroosiTypography.body())
                    Text("Play sound for new messages")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var matchNotificationsSection: some View {
        Section("Matches & Interests") {
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.newMatchNotificationsEnabled ?? true },
                set: { viewModel.updatePreference(key: .newMatchNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Matches")
                        .font(AroosiTypography.body())
                    Text("Get notified when you have a new match")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.interestReceivedNotificationsEnabled ?? true },
                set: { viewModel.updatePreference(key: .interestReceivedNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interest Received")
                        .font(AroosiTypography.body())
                    Text("Get notified when someone sends you an interest")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.interestAcceptedNotificationsEnabled ?? true },
                set: { viewModel.updatePreference(key: .interestAcceptedNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interest Accepted")
                        .font(AroosiTypography.body())
                    Text("Get notified when your interest is accepted")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.dailyRecommendationsEnabled ?? false },
                set: { viewModel.updatePreference(key: .dailyRecommendationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Recommendations")
                        .font(AroosiTypography.body())
                    Text("Get daily profile recommendations")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var profileNotificationsSection: some View {
        Section("Profile & Activity") {
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.profileViewNotificationsEnabled ?? false },
                set: { viewModel.updatePreference(key: .profileViewNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Views")
                        .font(AroosiTypography.body())
                    Text("Get notified when someone views your profile")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.familyApprovalNotificationsEnabled ?? true },
                set: { viewModel.updatePreference(key: .familyApprovalNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Approval Updates")
                        .font(AroosiTypography.body())
                    Text("Get notified about family approval requests")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.compatibilityReportNotificationsEnabled ?? false },
                set: { viewModel.updatePreference(key: .compatibilityReportNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compatibility Reports")
                        .font(AroosiTypography.body())
                    Text("Get notified when compatibility reports are ready")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var systemNotificationsSection: some View {
        Section("System Updates") {
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.appUpdateNotificationsEnabled ?? true },
                set: { viewModel.updatePreference(key: .appUpdateNotificationsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Updates")
                        .font(AroosiTypography.body())
                    Text("Get notified about app updates and new features")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.safetyAlertsEnabled ?? true },
                set: { viewModel.updatePreference(key: .safetyAlertsEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Safety Alerts")
                        .font(AroosiTypography.body())
                    Text("Important safety and security notifications")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.communityGuidelinesEnabled ?? true },
                set: { viewModel.updatePreference(key: .communityGuidelinesEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Community Guidelines")
                        .font(AroosiTypography.body())
                    Text("Updates to community guidelines and policies")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var quietHoursSection: some View {
        Section("Quiet Hours") {
            Toggle(isOn: Binding(
                get: { viewModel.state.preferences?.quietHoursEnabled ?? false },
                set: { viewModel.updatePreference(key: .quietHoursEnabled, value: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Quiet Hours")
                        .font(AroosiTypography.body())
                    Text("Temporarily pause notifications during specific hours")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            if viewModel.state.preferences?.quietHoursEnabled == true {
                HStack {
                    Text("Start Time")
                    Spacer()
                    Text(viewModel.state.preferences?.quietHoursStart.formatted(date: .omitted, time: .shortened) ?? "10:00 PM")
                        .foregroundStyle(AroosiColors.muted)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.showTimePicker(for: .startTime)
                }
                
                HStack {
                    Text("End Time")
                    Spacer()
                    Text(viewModel.state.preferences?.quietHoursEnd.formatted(date: .omitted, time: .shortened) ?? "8:00 AM")
                        .foregroundStyle(AroosiColors.muted)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.showTimePicker(for: .endTime)
                }
                
                Toggle(isOn: Binding(
                    get: { viewModel.state.preferences?.quietHoursAllowUrgent ?? false },
                    set: { viewModel.updatePreference(key: .quietHoursAllowUrgent, value: $0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allow Urgent Messages")
                            .font(AroosiTypography.body())
                        Text("Still receive notifications for urgent messages")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.muted)
                    }
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private func errorBanner(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.red.opacity(0.85))
                .clipShape(Capsule())
                .padding(.top, 8)
                .onTapGesture {
                    viewModel.clearError()
                }
            Spacer()
        }
    }
}

@available(iOS 17, *)
#Preview {
    NotificationPreferencesView(userID: "test-user")
        .environmentObject(NavigationCoordinator())
}

#endif
