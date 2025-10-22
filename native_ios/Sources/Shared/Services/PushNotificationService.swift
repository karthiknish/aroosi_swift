import Foundation
#if canImport(UserNotifications)
import UserNotifications

@available(iOS 10.0, macOS 10.14, *)
public protocol PushNotificationHandling: AnyObject {
    func registerForPushNotifications() async
    func handleDeviceToken(_ token: Data)
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async
    func handleAuthorizationStatusChange(_ status: UNAuthorizationStatus)
}

@available(iOS 15.0, macOS 12.0, *)
public final class PushNotificationService: NSObject, PushNotificationHandling {
    private let notificationCenter: UNUserNotificationCenter
    private let logger = Logger.shared

    public init(center: UNUserNotificationCenter = .current()) {
        self.notificationCenter = center
        super.init()
        center.delegate = self
    }

    public func registerForPushNotifications() async {
        do {
            let settings = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            handleAuthorizationStatusChange(settings ? .authorized : .denied)
        } catch {
            logger.error("Push notification authorization failed: \(error.localizedDescription)")
        }
    }

    public func handleDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        logger.info("Received APNs device token: \(tokenString)")
    }

    public func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        logger.info("Received remote notification payload: \(userInfo)")
    }

    public func handleAuthorizationStatusChange(_ status: UNAuthorizationStatus) {
        logger.info("Push authorization status changed: \(status.rawValue)")
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension PushNotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        logger.info("User interacted with notification: \(response.notification.request.identifier)")
        completionHandler()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        logger.info("Foreground notification: \(notification.request.identifier)")
        return [.banner, .sound, .badge]
    }
}
#endif
