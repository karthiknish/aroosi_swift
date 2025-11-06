#if os(iOS)
import Foundation
import UserNotifications
import Combine
import UIKit

@available(iOS 17, *)
@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    @Published var state = NotificationPreferencesState()
    
    private let settingsRepository: SettingsRepository
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()
    private let userID: String
    private let fcmService: FCMService
    private let logger = Logger.shared
    private var currentSettings: UserSettings?
    private var activeTopics: Set<FCMTopic> = []
    
    init(userID: String,
         settingsRepository: SettingsRepository = DefaultSettingsRepository(),
         notificationService: NotificationService = DefaultNotificationService(),
         fcmService: FCMService = DefaultFCMService()) {
        self.userID = userID
        self.settingsRepository = settingsRepository
        self.notificationService = notificationService
        self.fcmService = fcmService
        observePushRegistration()
        Task { await refreshAuthorizationStatus() }
        state.deviceToken = PushNotificationService.shared.fcmToken
        Task { await loadPreferencesIfNeeded(force: true) }
    }
    
    func loadPreferencesIfNeeded(force: Bool = false) async {
        if state.isLoading { return }
        if state.hasLoaded && !force { return }

        state.isLoading = true
        state.clearError()

        do {
            let settings = try await settingsRepository.fetchSettings(for: userID)
            apply(settings: settings)
            state.hasLoaded = true

            await refreshAuthorizationStatus()
            if state.systemPermissionGranted {
                try await notificationService.updateNotificationSettings(state.preferences)
                try await updatePushTopics(for: state.preferences)
            }
        } catch RepositoryError.notFound {
            let defaults = UserSettings.default(userID: userID)
            apply(settings: defaults)
            state.hasLoaded = true
        } catch {
            logger.error("Failed to load notification preferences: \(error.localizedDescription)")
            state.errorMessage = "Failed to load notification preferences. Please try again."
        }

        state.isLoading = false
    }
    
    func updatePreference(key: NotificationPreferenceKey, value: Bool) {
        Task {
            let previous = state.preferences
            do {
                state.isSaving = true
                state.clearError()

                if key.requiresNotificationRegistration && !state.systemPermissionGranted {
                    state.errorMessage = "Enable notifications in iOS Settings to manage this option."
                    state.preferences = previous
                    return
                }

                var updated = previous
                updated.updateValue(key: key, value: value)
                state.preferences = updated

                var settings = currentSettings ?? UserSettings.default(userID: userID)
                settings.applyNotificationPreferences(updated)
                try await settingsRepository.updateSettings(settings, userID: userID)
                currentSettings = settings

                if state.systemPermissionGranted {
                    try await notificationService.updateNotificationSettings(updated)
                    if key.requiresNotificationRegistration {
                        try await updatePushTopics(for: updated)
                    }
                }
            } catch {
                logger.error("Failed to update notification preference: \(error.localizedDescription)")
                state.errorMessage = "Failed to update preference. Please try again."
                state.preferences = previous
                if let currentSettings {
                    let rollback = NotificationPreferences(from: currentSettings)
                    state.preferences = rollback
                }
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
            let previous = state.preferences
            do {
                state.isSaving = true
                state.clearError()
                
                var updated = state.preferences

                switch state.timePickerType {
                case .startTime:
                    updated.quietHoursStart = time
                case .endTime:
                    updated.quietHoursEnd = time
                }

                var settings = currentSettings ?? UserSettings.default(userID: userID)
                settings.applyNotificationPreferences(updated)
                try await settingsRepository.updateSettings(settings, userID: userID)
                currentSettings = settings

                state.preferences = updated
                state.showingTimePicker = false

                if state.systemPermissionGranted {
                    try await notificationService.updateNotificationSettings(updated)
                }
            } catch {
                logger.error("Failed to update quiet hours: \(error.localizedDescription)")
                state.preferences = previous
                state.errorMessage = "Failed to update quiet hours: \(error.localizedDescription)"
            }
            state.isSaving = false
        }
    }
    
    func requestNotificationPermission() {
        Task {
            do {
                state.notificationPermissionStatus = .notDetermined
                let granted = try await notificationService.requestPermission()
                state.notificationPermissionStatus = granted ? .authorized : .denied
                state.systemPermissionGranted = granted

                if granted {
                    try await notificationService.registerForRemoteNotifications()
                    try await notificationService.updateNotificationSettings(state.preferences)
                    try await updatePushTopics(for: state.preferences)
                } else {
                    state.errorMessage = "Notification permission was denied by the system"
                }
                await refreshAuthorizationStatus()
            } catch {
                logger.error("Notification permission request failed: \(error.localizedDescription)")
                state.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            }
        }
    }
    
    func clearError() {
        state.clearError()
    }

    private func observePushRegistration() {
        PushNotificationService.shared.$fcmToken
            .receive(on: DispatchQueue.main)
            .sink { [weak self] token in
                guard let self else { return }
                self.state.deviceToken = token
            }
            .store(in: &cancellables)
    }
    
    private func refreshAuthorizationStatus() async {
        let status = await notificationService.getAuthorizationStatus()
        let systemGranted: Bool
        switch status {
        case .authorized, .provisional, .ephemeral:
            systemGranted = true
        default:
            systemGranted = false
        }
        state.notificationPermissionStatus = status
        state.systemPermissionGranted = systemGranted
    }
    
    private func updatePushTopics(for preferences: NotificationPreferences) async throws {
        guard state.systemPermissionGranted else { return }
        let desired = NotificationPreferenceKey.topics(for: preferences)
        let topicsToSubscribe = desired.subtracting(activeTopics)
        let topicsToUnsubscribe = activeTopics.subtracting(desired)

        for topic in topicsToSubscribe {
            try await fcmService.subscribeToTopic(topic.rawValue)
        }

        for topic in topicsToUnsubscribe {
            try await fcmService.unsubscribeFromTopic(topic.rawValue)
        }

        activeTopics = desired
    }

    private func apply(settings: UserSettings) {
        currentSettings = settings
        let resolved = NotificationPreferences(from: settings)
        state.preferences = resolved
    }
}

// MARK: - State

@available(iOS 17, *)
class NotificationPreferencesState: ObservableObject {
    @Published var preferences = NotificationPreferences()
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var systemPermissionGranted = false
    @Published var deviceToken: String?
    @Published var showingTimePicker = false
    @Published var timePickerType: TimePickerType = .startTime
    @Published var hasLoaded = false
    
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
    
    static func topics(for preferences: NotificationPreferences) -> Set<FCMTopic> {
        var topics: Set<FCMTopic> = []
        if preferences.newMessageNotificationsEnabled { topics.insert(.messages) }
        if preferences.newMatchNotificationsEnabled { topics.insert(.matches) }
        if preferences.interestReceivedNotificationsEnabled { topics.insert(.interests) }
        if preferences.interestAcceptedNotificationsEnabled { topics.insert(.matches) }
        if preferences.dailyRecommendationsEnabled { topics.insert(.recommendations) }
        if preferences.familyApprovalNotificationsEnabled { topics.insert(.family) }
        if preferences.compatibilityReportNotificationsEnabled { topics.insert(.compatibility) }
        if preferences.safetyAlertsEnabled { topics.insert(.safety) }
        return topics
    }
}

enum FCMTopic: String, CaseIterable {
    case messages = "notifications_messages"
    case matches = "notifications_matches"
    case interests = "notifications_interests"
    case recommendations = "notifications_recommendations"
    case family = "notifications_family"
    case compatibility = "notifications_compatibility"
    case safety = "notifications_safety"
}

enum TimePickerType {
    case startTime
    case endTime
}

// MARK: - Extensions

extension NotificationPreferences {
    init(from settings: UserSettings) {
        self.newMessageNotificationsEnabled = settings.pushNotificationsEnabled
        self.messageReadReceiptsEnabled = settings.messageReadReceiptsEnabled
        self.messageSoundEnabled = settings.messageSoundEnabled
        self.newMatchNotificationsEnabled = settings.newMatchNotificationsEnabled
        self.interestReceivedNotificationsEnabled = settings.interestReceivedNotificationsEnabled
        self.interestAcceptedNotificationsEnabled = settings.interestAcceptedNotificationsEnabled
        self.dailyRecommendationsEnabled = settings.dailyRecommendationsEnabled
        self.profileViewNotificationsEnabled = settings.profileViewNotificationsEnabled
        self.familyApprovalNotificationsEnabled = settings.familyApprovalNotificationsEnabled
        self.compatibilityReportNotificationsEnabled = settings.compatibilityReportNotificationsEnabled
        self.appUpdateNotificationsEnabled = settings.appUpdateNotificationsEnabled
        self.safetyAlertsEnabled = settings.safetyAlertsEnabled
        self.communityGuidelinesEnabled = settings.communityGuidelinesEnabled
        self.quietHoursEnabled = settings.quietHoursEnabled
        self.quietHoursAllowUrgent = settings.quietHoursAllowUrgent

        let calendar = Calendar(identifier: .gregorian)
        let defaultStart = calendar.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        let defaultEnd = calendar.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

        self.quietHoursStart = settings.quietHoursStart ?? defaultStart
        self.quietHoursEnd = settings.quietHoursEnd ?? defaultEnd
    }
}

extension UserSettings {
    init(userID: String, preferences: NotificationPreferences, existing: UserSettings? = nil) {
        if var existing {
            existing.applyNotificationPreferences(preferences)
            self = existing
        } else {
            self = UserSettings.default(userID: userID)
            self.applyNotificationPreferences(preferences)
        }
    }

    mutating func applyNotificationPreferences(_ preferences: NotificationPreferences) {
        pushNotificationsEnabled = preferences.newMessageNotificationsEnabled
        messageReadReceiptsEnabled = preferences.messageReadReceiptsEnabled
        messageSoundEnabled = preferences.messageSoundEnabled
        newMatchNotificationsEnabled = preferences.newMatchNotificationsEnabled
        interestReceivedNotificationsEnabled = preferences.interestReceivedNotificationsEnabled
        interestAcceptedNotificationsEnabled = preferences.interestAcceptedNotificationsEnabled
        dailyRecommendationsEnabled = preferences.dailyRecommendationsEnabled
        profileViewNotificationsEnabled = preferences.profileViewNotificationsEnabled
        familyApprovalNotificationsEnabled = preferences.familyApprovalNotificationsEnabled
        compatibilityReportNotificationsEnabled = preferences.compatibilityReportNotificationsEnabled
        safetyAlertsEnabled = preferences.safetyAlertsEnabled
        communityGuidelinesEnabled = preferences.communityGuidelinesEnabled
        appUpdateNotificationsEnabled = preferences.appUpdateNotificationsEnabled
        emailUpdatesEnabled = preferences.communityGuidelinesEnabled || preferences.appUpdateNotificationsEnabled
        quietHoursEnabled = preferences.quietHoursEnabled
        quietHoursAllowUrgent = preferences.quietHoursAllowUrgent
        quietHoursStart = preferences.quietHoursStart
        quietHoursEnd = preferences.quietHoursEnd
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
        let center = UNUserNotificationCenter.current()
        var categories = Set<UNNotificationCategory>()

        if preferences.newMessageNotificationsEnabled {
            let messageCategory = UNNotificationCategory(
                identifier: "NEW_MESSAGE",
                actions: [UNNotificationAction(identifier: "REPLY", title: "Reply", options: [.foreground]),
                          UNNotificationAction(identifier: "MARK_READ", title: "Mark as Read", options: [])],
                intentIdentifiers: [],
                options: []
            )
            categories.insert(messageCategory)
        }

        if preferences.newMatchNotificationsEnabled {
            let matchCategory = UNNotificationCategory(
                identifier: "NEW_MATCH",
                actions: [UNNotificationAction(identifier: "VIEW_PROFILE", title: "View Profile", options: [.foreground]),
                          UNNotificationAction(identifier: "SEND_MESSAGE", title: "Send Message", options: [.foreground])],
                intentIdentifiers: [],
                options: []
            )
            categories.insert(matchCategory)
        }

        if preferences.interestReceivedNotificationsEnabled {
            let interestCategory = UNNotificationCategory(
                identifier: "INTEREST_RECEIVED",
                actions: [UNNotificationAction(identifier: "ACCEPT", title: "Accept", options: []),
                          UNNotificationAction(identifier: "DECLINE", title: "Decline", options: [])],
                intentIdentifiers: [],
                options: []
            )
            categories.insert(interestCategory)
        }

        if preferences.safetyAlertsEnabled {
            let safetyCategory = UNNotificationCategory(
                identifier: "SAFETY_ALERT",
                actions: [],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
            categories.insert(safetyCategory)
        }

        center.setNotificationCategories(categories)
    }
}

#endif
