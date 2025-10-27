import UIKit
import FirebaseCore
import AroosiKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if #available(iOS 15.0, *) {
            FirebaseConfigurator.configureIfNeeded()
        } else {
            FirebaseApp.configure()
        }
        return true
    }
}
