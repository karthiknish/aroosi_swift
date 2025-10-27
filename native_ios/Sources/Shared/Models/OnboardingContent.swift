import Foundation

public struct OnboardingContent: Equatable {
    public let title: String
    public let tagline: String
    public let heroImageURL: URL?
    public let callToActionTitle: String

    public init(title: String, tagline: String, heroImageURL: URL?, callToActionTitle: String) {
        self.title = title
        self.tagline = tagline
        self.heroImageURL = heroImageURL
        self.callToActionTitle = callToActionTitle
    }
}

public extension OnboardingContent {
    init?(data: [String: Any]) {
        guard let title = data["title"] as? String,
              let tagline = data["tagline"] as? String else {
            return nil
        }

        let heroURLString = data["heroImageURL"] as? String ?? data["hero_image_url"] as? String
        let cta = data["callToActionTitle"] as? String
            ?? data["call_to_action_title"] as? String
            ?? "Get Started"

        self.init(title: title,
                  tagline: tagline,
                  heroImageURL: heroURLString.flatMap(URL.init(string:)),
                  callToActionTitle: cta)
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "tagline": tagline,
            "callToActionTitle": callToActionTitle
        ]

        if let heroImageURL {
            dict["heroImageURL"] = heroImageURL.absoluteString
        }

        return dict
    }
}
