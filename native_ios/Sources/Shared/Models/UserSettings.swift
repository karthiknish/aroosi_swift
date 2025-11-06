import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

public struct UserSettings: Equatable {
    public var userID: String
    public var pushNotificationsEnabled: Bool
    public var emailUpdatesEnabled: Bool
    public var appUpdateNotificationsEnabled: Bool
    public var messageReadReceiptsEnabled: Bool
    public var messageSoundEnabled: Bool
    public var newMatchNotificationsEnabled: Bool
    public var interestReceivedNotificationsEnabled: Bool
    public var interestAcceptedNotificationsEnabled: Bool
    public var dailyRecommendationsEnabled: Bool
    public var profileViewNotificationsEnabled: Bool
    public var familyApprovalNotificationsEnabled: Bool
    public var compatibilityReportNotificationsEnabled: Bool
    public var safetyAlertsEnabled: Bool
    public var communityGuidelinesEnabled: Bool
    public var quietHoursEnabled: Bool
    public var quietHoursAllowUrgent: Bool
    public var quietHoursStart: Date?
    public var quietHoursEnd: Date?
    public var supportEmail: String?
    public var supportPhoneNumber: String?

    public init(userID: String,
                pushNotificationsEnabled: Bool,
                emailUpdatesEnabled: Bool,
                appUpdateNotificationsEnabled: Bool = true,
                messageReadReceiptsEnabled: Bool = false,
                messageSoundEnabled: Bool = true,
                newMatchNotificationsEnabled: Bool = true,
                interestReceivedNotificationsEnabled: Bool = true,
                interestAcceptedNotificationsEnabled: Bool = true,
                dailyRecommendationsEnabled: Bool = false,
                profileViewNotificationsEnabled: Bool = false,
                familyApprovalNotificationsEnabled: Bool = true,
                compatibilityReportNotificationsEnabled: Bool = false,
                safetyAlertsEnabled: Bool = true,
                communityGuidelinesEnabled: Bool = true,
                quietHoursEnabled: Bool = false,
                quietHoursAllowUrgent: Bool = false,
                quietHoursStart: Date? = nil,
                quietHoursEnd: Date? = nil,
                supportEmail: String? = nil,
                supportPhoneNumber: String? = nil) {
        self.userID = userID
        self.pushNotificationsEnabled = pushNotificationsEnabled
        self.emailUpdatesEnabled = emailUpdatesEnabled
        self.appUpdateNotificationsEnabled = appUpdateNotificationsEnabled
        self.messageReadReceiptsEnabled = messageReadReceiptsEnabled
        self.messageSoundEnabled = messageSoundEnabled
        self.newMatchNotificationsEnabled = newMatchNotificationsEnabled
        self.interestReceivedNotificationsEnabled = interestReceivedNotificationsEnabled
        self.interestAcceptedNotificationsEnabled = interestAcceptedNotificationsEnabled
        self.dailyRecommendationsEnabled = dailyRecommendationsEnabled
        self.profileViewNotificationsEnabled = profileViewNotificationsEnabled
        self.familyApprovalNotificationsEnabled = familyApprovalNotificationsEnabled
        self.compatibilityReportNotificationsEnabled = compatibilityReportNotificationsEnabled
        self.safetyAlertsEnabled = safetyAlertsEnabled
        self.communityGuidelinesEnabled = communityGuidelinesEnabled
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursAllowUrgent = quietHoursAllowUrgent
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.supportEmail = supportEmail
        self.supportPhoneNumber = supportPhoneNumber
    }
}

public extension UserSettings {
    init?(id: String, data: [String: Any]) {
        let pushEnabled = data["pushNotificationsEnabled"] as? Bool
            ?? data["push_notifications_enabled"] as? Bool
            ?? false
        let emailEnabled = data["emailUpdatesEnabled"] as? Bool
            ?? data["email_updates_enabled"] as? Bool
            ?? false
        let appUpdate = data["appUpdateNotificationsEnabled"] as? Bool
            ?? data["app_update_notifications_enabled"] as? Bool
            ?? true
        let messageRead = data["messageReadReceiptsEnabled"] as? Bool ?? false
        let messageSound = data["messageSoundEnabled"] as? Bool ?? true
        let newMatch = data["newMatchNotificationsEnabled"] as? Bool ?? true
        let interestReceived = data["interestReceivedNotificationsEnabled"] as? Bool ?? true
        let interestAccepted = data["interestAcceptedNotificationsEnabled"] as? Bool ?? true
        let dailyRecommendations = data["dailyRecommendationsEnabled"] as? Bool ?? false
        let profileViews = data["profileViewNotificationsEnabled"] as? Bool ?? false
        let familyApproval = data["familyApprovalNotificationsEnabled"] as? Bool ?? true
        let compatibility = data["compatibilityReportNotificationsEnabled"] as? Bool ?? false
        let safetyAlerts = data["safetyAlertsEnabled"] as? Bool ?? true
        let communityGuidelines = data["communityGuidelinesEnabled"] as? Bool ?? true
        let quietHoursEnabled = data["quietHoursEnabled"] as? Bool ?? false
        let quietHoursAllowUrgent = data["quietHoursAllowUrgent"] as? Bool ?? false

        let quietStartValue = data["quietHoursStart"]
        let quietEndValue = data["quietHoursEnd"]
        let quietStart = UserSettings.parseDate(from: quietStartValue)
        let quietEnd = UserSettings.parseDate(from: quietEndValue)

        let supportEmail = data["supportEmail"] as? String
            ?? data["support_email"] as? String
        let supportPhone = data["supportPhoneNumber"] as? String
            ?? data["support_phone_number"] as? String

        self.init(userID: id,
                  pushNotificationsEnabled: pushEnabled,
                  emailUpdatesEnabled: emailEnabled,
                  appUpdateNotificationsEnabled: appUpdate,
                  messageReadReceiptsEnabled: messageRead,
                  messageSoundEnabled: messageSound,
                  newMatchNotificationsEnabled: newMatch,
                  interestReceivedNotificationsEnabled: interestReceived,
                  interestAcceptedNotificationsEnabled: interestAccepted,
                  dailyRecommendationsEnabled: dailyRecommendations,
                  profileViewNotificationsEnabled: profileViews,
                  familyApprovalNotificationsEnabled: familyApproval,
                  compatibilityReportNotificationsEnabled: compatibility,
                  safetyAlertsEnabled: safetyAlerts,
                  communityGuidelinesEnabled: communityGuidelines,
                  quietHoursEnabled: quietHoursEnabled,
                  quietHoursAllowUrgent: quietHoursAllowUrgent,
                  quietHoursStart: quietStart,
                  quietHoursEnd: quietEnd,
                  supportEmail: supportEmail,
                  supportPhoneNumber: supportPhone)
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "pushNotificationsEnabled": pushNotificationsEnabled,
            "emailUpdatesEnabled": emailUpdatesEnabled,
            "appUpdateNotificationsEnabled": appUpdateNotificationsEnabled,
            "messageReadReceiptsEnabled": messageReadReceiptsEnabled,
            "messageSoundEnabled": messageSoundEnabled,
            "newMatchNotificationsEnabled": newMatchNotificationsEnabled,
            "interestReceivedNotificationsEnabled": interestReceivedNotificationsEnabled,
            "interestAcceptedNotificationsEnabled": interestAcceptedNotificationsEnabled,
            "dailyRecommendationsEnabled": dailyRecommendationsEnabled,
            "profileViewNotificationsEnabled": profileViewNotificationsEnabled,
            "familyApprovalNotificationsEnabled": familyApprovalNotificationsEnabled,
            "compatibilityReportNotificationsEnabled": compatibilityReportNotificationsEnabled,
            "safetyAlertsEnabled": safetyAlertsEnabled,
            "communityGuidelinesEnabled": communityGuidelinesEnabled,
            "quietHoursEnabled": quietHoursEnabled,
            "quietHoursAllowUrgent": quietHoursAllowUrgent
        ]

        if let quietHoursStart {
            dict["quietHoursStart"] = quietHoursStart
        }
        if let quietHoursEnd {
            dict["quietHoursEnd"] = quietHoursEnd
        }

        if let supportEmail {
            dict["supportEmail"] = supportEmail
        }
        if let supportPhoneNumber {
            dict["supportPhoneNumber"] = supportPhoneNumber
        }

        return dict
    }

    static func `default`(userID: String) -> UserSettings {
        let calendar = Calendar(identifier: .gregorian)
        let defaultStart = calendar.date(from: DateComponents(hour: 22, minute: 0))
        let defaultEnd = calendar.date(from: DateComponents(hour: 8, minute: 0))

        return UserSettings(userID: userID,
                            pushNotificationsEnabled: true,
                            emailUpdatesEnabled: true,
                            appUpdateNotificationsEnabled: true,
                            messageReadReceiptsEnabled: false,
                            messageSoundEnabled: true,
                            newMatchNotificationsEnabled: true,
                            interestReceivedNotificationsEnabled: true,
                            interestAcceptedNotificationsEnabled: true,
                            dailyRecommendationsEnabled: false,
                            profileViewNotificationsEnabled: false,
                            familyApprovalNotificationsEnabled: true,
                            compatibilityReportNotificationsEnabled: false,
                            safetyAlertsEnabled: true,
                            communityGuidelinesEnabled: true,
                            quietHoursEnabled: false,
                            quietHoursAllowUrgent: false,
                            quietHoursStart: defaultStart,
                            quietHoursEnd: defaultEnd,
                            supportEmail: nil,
                            supportPhoneNumber: nil)
    }
}

private extension UserSettings {
    static func parseDate(from value: Any?) -> Date? {
        if let date = value as? Date { return date }
        #if canImport(FirebaseFirestore)
        if let timestamp = value as? Timestamp { return timestamp.dateValue() }
        #endif
        if let seconds = value as? TimeInterval { return Date(timeIntervalSince1970: seconds) }
        if let string = value as? String {
            let formatter = ISO8601DateFormatter()
            if let parsed = formatter.date(from: string) { return parsed }
        }
        return nil
    }
}
