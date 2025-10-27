import Foundation

public struct UserSettings: Equatable {
    public var userID: String
    public var pushNotificationsEnabled: Bool
    public var emailUpdatesEnabled: Bool
    public var supportEmail: String?
    public var supportPhoneNumber: String?

    public init(userID: String,
                pushNotificationsEnabled: Bool,
                emailUpdatesEnabled: Bool,
                supportEmail: String? = nil,
                supportPhoneNumber: String? = nil) {
        self.userID = userID
        self.pushNotificationsEnabled = pushNotificationsEnabled
        self.emailUpdatesEnabled = emailUpdatesEnabled
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
        let supportEmail = data["supportEmail"] as? String
            ?? data["support_email"] as? String
        let supportPhone = data["supportPhoneNumber"] as? String
            ?? data["support_phone_number"] as? String

        self.init(userID: id,
                  pushNotificationsEnabled: pushEnabled,
                  emailUpdatesEnabled: emailEnabled,
                  supportEmail: supportEmail,
                  supportPhoneNumber: supportPhone)
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "pushNotificationsEnabled": pushNotificationsEnabled,
            "emailUpdatesEnabled": emailUpdatesEnabled
        ]

        if let supportEmail {
            dict["supportEmail"] = supportEmail
        }
        if let supportPhoneNumber {
            dict["supportPhoneNumber"] = supportPhoneNumber
        }

        return dict
    }

    static func `default`(userID: String) -> UserSettings {
        UserSettings(userID: userID,
                     pushNotificationsEnabled: false,
                     emailUpdatesEnabled: false,
                     supportEmail: nil,
                     supportPhoneNumber: nil)
    }
}
