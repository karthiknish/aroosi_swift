#if os(iOS)
import Foundation
import UserNotifications
import UIKit

#if canImport(FirebaseMessaging)
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
#endif

@available(iOS 17, *)
class PushNotificationService: ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var isRegistered = false
    @Published var deviceToken: String?
    @Published var notificationSettings: UNNotificationSettings?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let fcmService: FCMService
    
    init(fcmService: FCMService = DefaultFCMService()) {
        self.fcmService = fcmService
        setupNotificationDelegate()
    }
    
    // MARK: - Registration
    
    func requestNotificationPermission() async throws -> Bool {
        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        
        if granted {
            await registerForRemoteNotifications()
            await updateNotificationSettings()
        }
        
        return granted
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        self.isRegistered = true
        
        Task {
            await registerTokenWithFCM(tokenString)
        }
    }
    
    func didFailToRegisterForRemoteNotifications(with error: Error) {
        print("Failed to register for remote notifications: \(error)")
        self.isRegistered = false
    }
    
    private func registerTokenWithFCM(_ token: String) async {
        do {
            try await fcmService.registerDeviceToken(token)
            print("Successfully registered FCM token")
        } catch {
            print("Failed to register FCM token: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        subtitle: String? = nil,
        userInfo: [AnyHashable: Any] = [:],
        scheduledDate: Date? = nil,
        categoryIdentifier: String? = nil
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        content.userInfo = userInfo
        
        // Add deep linking support
        if let deepLink = userInfo["deepLink"] as? String {
            content.userInfo["deepLink"] = deepLink
        }
        
        // Add rich media support
        if let imageURL = userInfo["imageURL"] as? String {
            content.attachments = try await createNotificationAttachment(imageURL: imageURL)
        }
        
        let trigger: UNNotificationTrigger
        if let scheduledDate = scheduledDate {
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: scheduledDate),
                repeats: false
            )
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        try await notificationCenter.add(request)
    }
    
    func cancelNotification(id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func getScheduledNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Rich Media Notifications
    
    private func createNotificationAttachment(imageURL: String) async throws -> [UNNotificationAttachment] {
        guard let url = URL(string: imageURL),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return []
        }
        
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let imageURL = documentsPath.appendingPathComponent("notification_image_\(UUID().uuidString).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return []
        }
        
        try imageData.write(to: imageURL)
        
        let attachment = try UNNotificationAttachment(
            identifier: "image",
            url: imageURL,
            options: [UNNotificationAttachmentOptionsThumbnailClippingRectKey: CGRect(x: 0, y: 0, width: 1, height: 1)]
        )
        
        return [attachment]
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() async {
        let newMessageCategory = UNNotificationCategory(
            identifier: "NEW_MESSAGE",
            actions: [
                UNNotificationAction(identifier: "REPLY", title: "Reply", options: [.foreground]),
                UNNotificationAction(identifier: "MARK_READ", title: "Mark as Read", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let newMatchCategory = UNNotificationCategory(
            identifier: "NEW_MATCH",
            actions: [
                UNNotificationAction(identifier: "VIEW_PROFILE", title: "View Profile", options: [.foreground]),
                UNNotificationAction(identifier: "SEND_MESSAGE", title: "Send Message", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let interestCategory = UNNotificationCategory(
            identifier: "INTEREST_RECEIVED",
            actions: [
                UNNotificationAction(identifier: "VIEW_PROFILE", title: "View Profile", options: [.foreground]),
                UNNotificationAction(identifier: "ACCEPT", title: "Accept", options: []),
                UNNotificationAction(identifier: "DECLINE", title: "Decline", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        await notificationCenter.setNotificationCategories([
            newMessageCategory,
            newMatchCategory,
            interestCategory
        ])
    }
    
    // MARK: - Settings
    
    private func updateNotificationSettings() async {
        notificationSettings = await notificationCenter.notificationSettings()
    }
    
    func updateBadgeCount(_ count: Int) async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    // MARK: - Deep Linking
    
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle deep linking
        if let deepLink = userInfo["deepLink"] as? String {
            await handleDeepLink(deepLink)
        }
        
        // Handle action responses
        switch response.actionIdentifier {
        case "REPLY":
            if let conversationID = userInfo["conversationID"] as? String {
                await handleReplyAction(conversationID: conversationID)
            }
        case "VIEW_PROFILE":
            if let userID = userInfo["userID"] as? String {
                await handleViewProfileAction(userID: userID)
            }
        case "SEND_MESSAGE":
            if let userID = userInfo["userID"] as? String {
                await handleSendMessageAction(userID: userID)
            }
        case "ACCEPT":
            if let interestID = userInfo["interestID"] as? String {
                await handleAcceptInterestAction(interestID: interestID)
            }
        case "DECLINE":
            if let interestID = userInfo["interestID"] as? String {
                await handleDeclineInterestAction(interestID: interestID)
            }
        default:
            break
        }
    }
    
    private func handleDeepLink(_ deepLink: String) async {
        // Navigate to appropriate screen based on deep link
        NotificationCenter.default.post(
            name: .deepLinkReceived,
            object: nil,
            userInfo: ["deepLink": deepLink]
        )
    }
    
    private func handleReplyAction(conversationID: String) async {
        NotificationCenter.default.post(
            name: .replyToMessage,
            object: nil,
            userInfo: ["conversationID": conversationID]
        )
    }
    
    private func handleViewProfileAction(userID: String) async {
        NotificationCenter.default.post(
            name: .viewProfile,
            object: nil,
            userInfo: ["userID": userID]
        )
    }
    
    private func handleSendMessageAction(userID: String) async {
        NotificationCenter.default.post(
            name: .sendMessage,
            object: nil,
            userInfo: ["userID": userID]
        )
    }
    
    private func handleAcceptInterestAction(interestID: String) async {
        NotificationCenter.default.post(
            name: .acceptInterest,
            object: nil,
            userInfo: ["interestID": interestID]
        )
    }
    
    private func handleDeclineInterestAction(interestID: String) async {
        NotificationCenter.default.post(
            name: .declineInterest,
            object: nil,
            userInfo: ["interestID": interestID]
        )
    }
    
    // MARK: - Setup
    
    private func setupNotificationDelegate() {
        notificationCenter.delegate = self
        Task {
            await setupNotificationCategories()
            await updateNotificationSettings()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

@available(iOS 17, *)
extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await handleNotificationResponse(response)
            completionHandler()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
    static let replyToMessage = Notification.Name("replyToMessage")
    static let viewProfile = Notification.Name("viewProfile")
    static let sendMessage = Notification.Name("sendMessage")
    static let acceptInterest = Notification.Name("acceptInterest")
    static let declineInterest = Notification.Name("declineInterest")
}

// MARK: - FCM Service Protocol

protocol FCMService {
    func registerDeviceToken(_ token: String) async throws
    func unregisterDeviceToken() async throws
    func subscribeToTopic(_ topic: String) async throws
    func unsubscribeFromTopic(_ topic: String) async throws
}

// MARK: - Default FCM Service

#if canImport(FirebaseMessaging)

class DefaultFCMService: FCMService {
    private let messaging = Messaging.messaging()
    private let logger = Logger.shared
    
    func registerDeviceToken(_ token: String) async throws {
        logger.info("Registering FCM device token")
        
        do {
            // Get current user ID from your authentication service
            guard let userID = getCurrentUserID() else {
                throw FCMError.userNotAuthenticated
            }
            
            // Save the FCM token to Firestore for the current user
            let db = Firestore.firestore()
            try await db.collection("users").document(userID).setData([
                "fcmToken": token,
                "tokenUpdatedAt": Timestamp(date: Date()),
                "platform": "ios"
            ], merge: true)
            
            // Subscribe to general topics
            try await subscribeToTopic("all_users")
            try await subscribeToTopic("ios_users")
            
            // Subscribe to user-specific topic
            try await subscribeToTopic("user_\(userID)")
            
            logger.info("Successfully registered FCM token for user: \(userID)")
            
        } catch {
            logger.error("Failed to register FCM token: \(error.localizedDescription)")
            throw FCMError.registrationFailed
        }
    }
    
    func unregisterDeviceToken() async throws {
        logger.info("Unregistering FCM device token")
        
        do {
            guard let userID = getCurrentUserID() else {
                throw FCMError.userNotAuthenticated
            }
            
            // Remove FCM token from Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(userID).setData([
                "fcmToken": FieldValue.delete(),
                "tokenUpdatedAt": FieldValue.delete()
            ], merge: true)
            
            // Unsubscribe from topics
            try await unsubscribeFromTopic("all_users")
            try await unsubscribeFromTopic("ios_users")
            try await unsubscribeFromTopic("user_\(userID)")
            
            logger.info("Successfully unregistered FCM token for user: \(userID)")
            
        } catch {
            logger.error("Failed to unregister FCM token: \(error.localizedDescription)")
            throw FCMError.unregistrationFailed
        }
    }
    
    func subscribeToTopic(_ topic: String) async throws {
        logger.info("Subscribing to FCM topic: \(topic)")
        
        do {
            try await messaging.subscribe(toTopic: topic)
            logger.info("Successfully subscribed to topic: \(topic)")
        } catch {
            logger.error("Failed to subscribe to topic \(topic): \(error.localizedDescription)")
            throw FCMError.subscriptionFailed
        }
    }
    
    func unsubscribeFromTopic(_ topic: String) async throws {
        logger.info("Unsubscribing from FCM topic: \(topic)")
        
        do {
            try await messaging.unsubscribe(fromTopic: topic)
            logger.info("Successfully unsubscribed from topic: \(topic)")
        } catch {
            logger.error("Failed to unsubscribe from topic \(topic): \(error.localizedDescription)")
            throw FCMError.unsubscriptionFailed
        }
    }
    
    private func getCurrentUserID() -> String? {
        // This should get the current user ID from your authentication service
        return Auth.auth().currentUser?.uid
    }
}

#else

// Fallback implementation for when Firebase Messaging is not available
class DefaultFCMService: FCMService {
    private let logger = Logger.shared
    
    func registerDeviceToken(_ token: String) async throws {
        logger.info("FCM not available - using fallback token registration")
        print("Registering FCM token: \(token)")
    }
    
    func unregisterDeviceToken() async throws {
        logger.info("FCM not available - using fallback token unregistration")
        print("Unregistering FCM token")
    }
    
    func subscribeToTopic(_ topic: String) async throws {
        logger.info("FCM not available - using fallback topic subscription")
        print("Subscribing to FCM topic: \(topic)")
    }
    
    func unsubscribeFromTopic(_ topic: String) async throws {
        logger.info("FCM not available - using fallback topic unsubscription")
        print("Unsubscribing from FCM topic: \(topic)")
    }
}

#endif

// MARK: - FCM Errors

enum FCMError: Error, LocalizedError {
    case userNotAuthenticated
    case registrationFailed
    case unregistrationFailed
    case subscriptionFailed
    case unsubscriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated. Please sign in to enable notifications."
        case .registrationFailed:
            return "Failed to register for push notifications. Please try again."
        case .unregistrationFailed:
            return "Failed to unregister from push notifications. Please try again."
        case .subscriptionFailed:
            return "Failed to subscribe to notification topic. Please try again."
        case .unsubscriptionFailed:
            return "Failed to unsubscribe from notification topic. Please try again."
        }
    }
}

#endif
