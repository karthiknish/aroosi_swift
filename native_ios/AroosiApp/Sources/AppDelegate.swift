import UIKit
import FirebaseCore
import AroosiKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        if #available(iOS 15.0, *) {
            FirebaseConfigurator.configureIfNeeded()
        } else {
            FirebaseApp.configure()
        }
        
        // Configure Analytics for Aroosi Matrimony
        if #available(iOS 17.0, *) {
            AnalyticsConfiguration.configure()
            AnalyticsConfiguration.configureMatrimonyTracking()
        }
        
        return true
    }
}
