import SwiftUI
import AroosiKit

@main
struct AroosiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        AroosiTheme.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .tint(AroosiColors.primary)
        }
    }
}
