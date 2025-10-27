#if os(iOS)
import Foundation
import UserNotifications
import Combine

@available(iOS 17, *)
@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    @Published var state = NotificationPreferencesState()
    @Published var preferences: NotificationPreferences
    
    private let settingsRepository: SettingsRepository
    private let notificationService: NotificationService
    private let permissionManager: PermissionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(userID: String,
         settingsRepository: SettingsRepository = DefaultSettingsRepository(),
         notificationService: NotificationService = DefaultNotificationService(),
         permissionManager: PermissionManager = .shared) {
        self.settingsRepository = settingsRepository
        self.notificationService = notificationService
        self.permissionManager = permissionManager
        self.preferences = NotificationPreferences()
        
        loadPreferences(userID: userID)
    }
    
    func loadPreferences(userID: String) {
        Task {
            do {
                state.isLoading = true
                let settings = try await settingsRepository.fetchSettings(for: userID)
                preferences = NotificationPreferences(from: settings)
                state.userID = userID
            } catch {
                state.errorMessage = "Failed to load notification preferences: \(error.localizedDescription)"
            }
            state.isLoading = false
        }
    }
    
    func requestNotificationPermission() async {
        let hasPermission = await permissionManager.handleNotificationPermission()
        
        if hasPermission {
            do {
                let granted = try await notificationService.requestPermission()
                state.systemPermissionGranted = granted
                
                if !granted {
                    state.errorMessage = "Notification permission was denied by the system"
                }
            } catch {
                state.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            }
        } else {
            state.systemPermissionGranted = false
            state.errorMessage = "Notification permission is required to receive notifications"
        }
    }
    
    func updatePreference(key: NotificationPreferenceKey, value: Bool) {
        Task {
            do {
                state.isSaving = true
                state.clearError()
                
                var preferences = state.preferences ?? NotificationPreferences()
                preferences.updateValue(key: key, value: value)
                
                // Update settings repository
                let settings = UserSettings(from: preferences)
                try await settingsRepository.updateSettings(settings, userID: userID)
                
                state.preferences = preferences
                
                // Update notification registration if needed
                if key.requiresNotificationRegistration {
                    try await notificationService.updateNotificationSettings(preferences)
                }
                
            } catch {
                state.errorMessage = "Failed to update preference: \(error.localizedDescription)"
            }
            state.isSaving = false
        }
    }
    
    func showTimePicker(for timeType: TimePickerType) {
        state.showingTimePicker = true
        state.timePickerType = timeType
    }
    
    func updateTime(_ time: Date) {
        Task {
            do {
                state.isSaving = true
                state.clearError()
                
                var preferences = state.preferences ?? NotificationPreferences()
                
                switch state.timePickerType {
                case .startTime:
                    preferences.quietHoursStart = time
                case .endTime:
                    preferences.quietHoursEnd = time
                }
                
                // Update settings repository
                let settings = UserSettings(from: preferences)
                try await settingsRepository.updateSettings(settings, userID: userID)
                
                state.preferences = preferences
                state.showingTimePicker = false
                
            } catch {
                state.errorMessage = "Failed to update quiet hours: \(error.localizedDescription)"
            }
            state.isSaving = false
        }
    }
    
    func requestNotificationPermission() {
        Task {
            do {
                let granted = try await notificationService.requestPermission()
                state.notificationPermissionStatus = granted ? .authorized : .denied
                
                if granted {
                    try await notificationService.registerForRemoteNotifications()
                }
                
            } catch {
                state.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            }
        }
    }
    
    func clearError() {
        state.clearError()
    }
}

// MARK: - State

@available(iOS 17, *)
class NotificationPreferencesState: ObservableObject {
    @Published var preferences: NotificationPreferences?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var showingTimePicker = false
    @Published var timePickerType: TimePickerType = .startTime
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Models

@available(iOS 17, *)
struct NotificationPreferences {
    var newMessageNotificationsEnabled: Bool = true
    var messageReadReceiptsEnabled: Bool = false
    var messageSoundEnabled: Bool = true
    var newMatchNotificationsEnabled: Bool = true
    var interestReceivedNotificationsEnabled: Bool = true
    var interestAcceptedNotificationsEnabled: Bool = true
    var dailyRecommendationsEnabled: Bool = false
    var profileViewNotificationsEnabled: Bool = false
    var familyApprovalNotificationsEnabled: Bool = true
    var compatibilityReportNotificationsEnabled: Bool = false
    var appUpdateNotificationsEnabled: Bool = true
    var safetyAlertsEnabled: Bool = true
    var communityGuidelinesEnabled: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    var quietHoursAllowUrgent: Bool = false
    
    mutating func updateValue(key: NotificationPreferenceKey, value: Bool) {
        switch key {
        case .newMessageNotificationsEnabled:
            newMessageNotificationsEnabled = value
        case .messageReadReceiptsEnabled:
            messageReadReceiptsEnabled = value
        case .messageSoundEnabled:
            messageSoundEnabled = value
        case .newMatchNotificationsEnabled:
            newMatchNotificationsEnabled = value
        case .interestReceivedNotificationsEnabled:
            interestReceivedNotificationsEnabled = value
        case .interestAcceptedNotificationsEnabled:
            interestAcceptedNotificationsEnabled = value
        case .dailyRecommendationsEnabled:
            dailyRecommendationsEnabled = value
        case .profileViewNotificationsEnabled:
            profileViewNotificationsEnabled = value
        case .familyApprovalNotificationsEnabled:
            familyApprovalNotificationsEnabled = value
        case .compatibilityReportNotificationsEnabled:
            compatibilityReportNotificationsEnabled = value
        case .appUpdateNotificationsEnabled:
            appUpdateNotificationsEnabled = value
        case .safetyAlertsEnabled:
            safetyAlertsEnabled = value
        case .communityGuidelinesEnabled:
            communityGuidelinesEnabled = value
        case .quietHoursEnabled:
            quietHoursEnabled = value
        case .quietHoursAllowUrgent:
            quietHoursAllowUrgent = value
        }
    }
}

@available(iOS 17, *)
enum NotificationPreferenceKey: String, CaseIterable {
    case newMessageNotificationsEnabled
    case messageReadReceiptsEnabled
    case messageSoundEnabled
    case newMatchNotificationsEnabled
    case interestReceivedNotificationsEnabled
    case interestAcceptedNotificationsEnabled
    case dailyRecommendationsEnabled
    case profileViewNotificationsEnabled
    case familyApprovalNotificationsEnabled
    case compatibilityReportNotificationsEnabled
    case appUpdateNotificationsEnabled
    case safetyAlertsEnabled
    case communityGuidelinesEnabled
    case quietHoursEnabled
    case quietHoursAllowUrgent
    
    var requiresNotificationRegistration: Bool {
        switch self {
        case .newMessageNotificationsEnabled, .newMatchNotificationsEnabled, 
             .interestReceivedNotificationsEnabled, .interestAcceptedNotificationsEnabled,
             .dailyRecommendationsEnabled, .familyApprovalNotificationsEnabled,
             .compatibilityReportNotificationsEnabled, .safetyAlertsEnabled:
            return true
        default:
            return false
        }
    }
}

enum TimePickerType {
    case startTime
    case endTime
}

// MARK: - Extensions

extension NotificationPreferences {
    init(from settings: UserSettings) {
        self.newMessageNotificationsEnabled = settings.pushNotificationsEnabled
        self.messageSoundEnabled = settings.pushNotificationsEnabled
        self.newMatchNotificationsEnabled = settings.pushNotificationsEnabled
        self.interestReceivedNotificationsEnabled = settings.pushNotificationsEnabled
        self.interestAcceptedNotificationsEnabled = settings.pushNotificationsEnabled
        self.familyApprovalNotificationsEnabled = settings.pushNotificationsEnabled
        self.safetyAlertsEnabled = settings.pushNotificationsEnabled
        self.appUpdateNotificationsEnabled = settings.emailUpdatesEnabled
        self.communityGuidelinesEnabled = settings.emailUpdatesEnabled
    }
}

extension UserSettings {
    init(from preferences: NotificationPreferences) {
        self.pushNotificationsEnabled = preferences.newMessageNotificationsEnabled
        self.emailUpdatesEnabled = preferences.appUpdateNotificationsEnabled
        self.profileVisibility = .public
        self.discoveryPreferences = DiscoveryPreferences.default
    }
}

// MARK: - Protocols

protocol NotificationService {
    func requestPermission() async throws -> Bool
    func getAuthorizationStatus() async -> UNAuthorizationStatus
    func registerForRemoteNotifications() async throws
    func updateNotificationSettings(_ preferences: NotificationPreferences) async throws
}

class DefaultNotificationService: NotificationService {
    func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        return await center.notificationSettings().authorizationStatus
    }
    
    func registerForRemoteNotifications() async throws {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func updateNotificationSettings(_ preferences: NotificationPreferences) async throws {
        // Update notification categories and settings
        let center = UNUserNotificationCenter.current()
        
        var categories: Set<UNNotificationCategory> = []
        
        if preferences.newMessageNotificationsEnabled {
            let messageCategory = UNNotificationCategory(
                identifier: "NEW_MESSAGE",
                actions: [],
                intentIdentifiers: [],
                options: []
            )
            categories.insert(messageCategory)
        }
        
        if preferences.newMatchNotificationsEnabled {
            let matchCategory = UNNotificationCategory(
                identifier: "NEW_MATCH",
                actions: [],
                intentIdentifiers: [],
                options: []
            )
            categories.insert(matchCategory)
        }
        
        await center.setNotificationCategories(categories)
    }
}

#endif
