#if os(iOS)
import SwiftUI

@available(iOS 17, *)
enum AroosiAsset {
    private static func image(_ name: String) -> Image {
        Image(name, bundle: .module)
    }

    static var onboardingHero: Image {
        image("Images/welcome")
    }

    static var avatarPlaceholder: Image {
        image("Images/placeholder")
    }
}
#endif
