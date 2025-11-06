import Foundation

#if os(iOS)

@available(iOS 17, *)
@MainActor
final class EditProfileViewModel: ObservableObject {
    struct FormState: Equatable {
        var displayName: String
        var age: String
        var location: String
        var bio: String
        var interests: String
        var errorMessage: String?
        var isSaving: Bool = false
    }

    @Published private(set) var form: FormState

    private let userID: String
    private let profileRepository: ProfileRepository
    private var originalProfile: ProfileSummary?

    init(userID: String,
         profile: ProfileSummary?,
         profileRepository: ProfileRepository = FirestoreProfileRepository()) {
        self.userID = userID
        self.profileRepository = profileRepository

        let displayName = profile?.displayName ?? ""
        let age = profile?.age.flatMap { String($0) } ?? ""
        let location = profile?.location ?? ""
        let bio = profile?.bio ?? ""
        let interests = profile?.interests.joined(separator: ", ") ?? ""

        self.originalProfile = profile
        self.form = FormState(displayName: displayName,
                              age: age,
                              location: location,
                              bio: bio,
                              interests: interests,
                              errorMessage: nil)
    }

    func updateDisplayName(_ value: String) { form.displayName = value }
    func updateAge(_ value: String) { form.age = value }
    func updateLocation(_ value: String) { form.location = value }
    func updateBio(_ value: String) { form.bio = value }
    func updateInterests(_ value: String) { form.interests = value }

    func save() async -> Bool {
        form.errorMessage = nil
        let trimmedName = form.displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            form.errorMessage = "Display name is required."
            return false
        }

        var ageValue: Int?
        if !form.age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let converted = Int(form.age.trimmingCharacters(in: .whitespacesAndNewlines)), converted > 0 {
                ageValue = converted
            } else {
                form.errorMessage = "Age must be a positive number."
                return false
            }
        }

        let interests = form.interests
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        form.isSaving = true

        do {
            var updated = originalProfile ?? ProfileSummary(id: userID, displayName: trimmedName)
            updated.displayName = trimmedName
            updated.age = ageValue
            updated.location = form.location.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.bio = form.bio.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.interests = interests

            try await profileRepository.updateProfile(updated)
            form.isSaving = false
            originalProfile = updated
            return true
        } catch RepositoryError.permissionDenied {
            form.errorMessage = "You don't have permission to update this profile."
        } catch {
            form.errorMessage = "We couldn't save your profile. Please try again later."
        }

        form.isSaving = false
        return false
    }
    
    func updateProfileImage(url: String) async {
        do {
            var updated = originalProfile ?? ProfileSummary(id: userID, displayName: form.displayName)
            updated.avatarURL = url
            
            try await profileRepository.updateProfile(updated)
            originalProfile = updated
        } catch {
            form.errorMessage = "Failed to update profile image. Please try again."
        }
    }
}

#endif
