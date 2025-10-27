import Foundation

@available(iOS 17.0.0, *)
public struct CulturalProfileDetail: Equatable {
    public var religion: String?
    public var religiousPractice: String?
    public var motherTongue: String?
    public var languages: [String]
    public var familyValues: String?
    public var marriageViews: String?
    public var traditionalValues: String?
    public var familyApprovalImportance: String?
    public var religionImportance: Int?
    public var cultureImportance: Int?
    public var familyBackground: String?
    public var ethnicity: String?

    public init(religion: String? = nil,
                religiousPractice: String? = nil,
                motherTongue: String? = nil,
                languages: [String] = [],
                familyValues: String? = nil,
                marriageViews: String? = nil,
                traditionalValues: String? = nil,
                familyApprovalImportance: String? = nil,
                religionImportance: Int? = nil,
                cultureImportance: Int? = nil,
                familyBackground: String? = nil,
                ethnicity: String? = nil) {
        self.religion = religion
        self.religiousPractice = religiousPractice
        self.motherTongue = motherTongue
        self.languages = languages
        self.familyValues = familyValues
        self.marriageViews = marriageViews
        self.traditionalValues = traditionalValues
        self.familyApprovalImportance = familyApprovalImportance
        self.religionImportance = religionImportance
        self.cultureImportance = cultureImportance
        self.familyBackground = familyBackground
        self.ethnicity = ethnicity
    }
}

@available(iOS 17.0.0, *)
public struct MatchPreferencesDetail: Equatable {
    public var minAge: Int?
    public var maxAge: Int?
    public var location: String?
    public var religion: String?
    public var religiousPractice: String?
    public var familyValues: String?
    public var marriageViews: String?

    public init(minAge: Int? = nil,
                maxAge: Int? = nil,
                location: String? = nil,
                religion: String? = nil,
                religiousPractice: String? = nil,
                familyValues: String? = nil,
                marriageViews: String? = nil) {
        self.minAge = minAge
        self.maxAge = maxAge
        self.location = location
        self.religion = religion
        self.religiousPractice = religiousPractice
        self.familyValues = familyValues
        self.marriageViews = marriageViews
    }
}

@available(iOS 17.0.0, *)
public struct ProfileDetail: Equatable {
    public var summary: ProfileSummary
    public var about: String?
    public var headline: String?
    public var gallery: [URL]
    public var interests: [String]
    public var languages: [String]
    public var motherTongue: String?
    public var education: String?
    public var occupation: String?
    public var culturalProfile: CulturalProfileDetail?
    public var preferences: MatchPreferencesDetail?
    public var familyBackground: String?
    public var personalityTraits: [String]
    public var isFavorite: Bool
    public var isShortlisted: Bool

    public init(summary: ProfileSummary,
                about: String? = nil,
                headline: String? = nil,
                gallery: [URL] = [],
                interests: [String] = [],
                languages: [String] = [],
                motherTongue: String? = nil,
                education: String? = nil,
                occupation: String? = nil,
                culturalProfile: CulturalProfileDetail? = nil,
                preferences: MatchPreferencesDetail? = nil,
                familyBackground: String? = nil,
                personalityTraits: [String] = [],
                isFavorite: Bool = false,
                isShortlisted: Bool = false) {
        self.summary = summary
        self.about = about
        self.headline = headline
        self.gallery = gallery
        self.interests = interests
        self.languages = languages
        self.motherTongue = motherTongue
        self.education = education
        self.occupation = occupation
        self.culturalProfile = culturalProfile
        self.preferences = preferences
        self.familyBackground = familyBackground
        self.personalityTraits = personalityTraits
        self.isFavorite = isFavorite
        self.isShortlisted = isShortlisted
    }
}

@available(iOS 17.0.0, *)
extension ProfileDetail {
    static func build(summary: ProfileSummary,
                      data: [String: Any],
                      isFavorite: Bool,
                      isShortlisted: Bool) -> ProfileDetail {
        var gallery: [URL] = []

        if let images = data["images"] as? [Any] {
            gallery.append(contentsOf: images.compactMap { ($0 as? String)?.trimmedURL })
        }

        if gallery.isEmpty, let profileImage = data["profileImage"] as? String, let url = URL(string: profileImage) {
            gallery.append(url)
        }

        if gallery.isEmpty, let avatar = summary.avatarURL {
            gallery.append(avatar)
        }

        let about = (data["about"] as? String)?.validatedText ?? summary.bio
        let headline = (data["headline"] as? String)?.validatedText

        var languages = Set((data["languages"] as? [String]) ?? [])
        var motherTongue: String? = data["motherTongue"] as? String

        var culturalProfile: CulturalProfileDetail?
        if let cultural = data["culturalProfile"] as? [String: Any] {
            let culturalLanguages = (cultural["languages"] as? [String]) ?? []
            languages.formUnion(culturalLanguages)
            if motherTongue == nil {
                motherTongue = cultural["motherTongue"] as? String
            }

            culturalProfile = CulturalProfileDetail(
                religion: cultural["religion"] as? String,
                religiousPractice: cultural["religiousPractice"] as? String,
                motherTongue: cultural["motherTongue"] as? String,
                languages: culturalLanguages,
                familyValues: cultural["familyValues"] as? String,
                marriageViews: cultural["marriageViews"] as? String,
                traditionalValues: cultural["traditionalValues"] as? String,
                familyApprovalImportance: cultural["familyApprovalImportance"] as? String,
                religionImportance: cultural["religionImportance"] as? Int ?? (cultural["religionImportance"] as? NSNumber)?.intValue,
                cultureImportance: cultural["cultureImportance"] as? Int ?? (cultural["cultureImportance"] as? NSNumber)?.intValue,
                familyBackground: cultural["familyBackground"] as? String,
                ethnicity: cultural["ethnicity"] as? String
            )
        }

        let preferenceData = data["preferences"] as? [String: Any]
        var preferences: MatchPreferencesDetail?
        if let preferenceData {
            let ageRange = preferenceData["ageRange"] as? [String: Any]
            preferences = MatchPreferencesDetail(
                minAge: ageRange?["min"] as? Int ?? (ageRange?["min"] as? NSNumber)?.intValue,
                maxAge: ageRange?["max"] as? Int ?? (ageRange?["max"] as? NSNumber)?.intValue,
                location: preferenceData["location"] as? String,
                religion: preferenceData["religion"] as? String,
                religiousPractice: preferenceData["religiousPractice"] as? String,
                familyValues: preferenceData["familyValues"] as? String,
                marriageViews: preferenceData["marriageViews"] as? String
            )
        }

        let education = (data["education"] as? String)?.validatedText
            ?? (data["highestEducation"] as? String)?.validatedText
        let occupation = (data["occupation"] as? String)?.validatedText
            ?? (data["profession"] as? String)?.validatedText

        let familyBackground = (data["familyBackground"] as? String)?.validatedText
            ?? culturalProfile?.familyBackground

        let personalityTraits = (data["personalityTraits"] as? [String]) ?? []
        let interests = (data["interests"] as? [String]) ?? summary.interests

        return ProfileDetail(
            summary: summary,
            about: about,
            headline: headline,
            gallery: gallery,
            interests: interests,
            languages: Array(languages).sorted(),
            motherTongue: motherTongue,
            education: education,
            occupation: occupation,
            culturalProfile: culturalProfile,
            preferences: preferences,
            familyBackground: familyBackground,
            personalityTraits: personalityTraits,
            isFavorite: isFavorite,
            isShortlisted: isShortlisted
        )
    }
}

private extension String {
    var trimmedURL: URL? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: trimmed)
    }

    var capitalizedWords: String {
        split(separator: " ").map { substring in
            let token = substring
            if token.contains("-") {
                return token.split(separator: "-").map { $0.lowercased().capitalized }.joined(separator: "-")
            }
            return token.lowercased().capitalized
        }.joined(separator: " ")
    }

    var validatedText: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
