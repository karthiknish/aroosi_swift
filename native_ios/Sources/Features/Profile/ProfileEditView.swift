#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct EditProfileView: View {
    let userID: String
    let profile: ProfileSummary
    let onSave: () -> Void
    
    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String
    @State private var age: String
    @State private var location: String
    @State private var bio: String
    @State private var selectedInterests: Set<String>
    @State private var showingMediaUpload = false
    @State private var profileMediaURLs: [URL] = []
    
    @MainActor
    init(userID: String, profile: ProfileSummary, onSave: @escaping () -> Void) {
        self.userID = userID
        self.profile = profile
        self.onSave = onSave
        
        _displayName = State(initialValue: profile.displayName)
        _age = State(initialValue: profile.age?.description ?? "")
        _location = State(initialValue: profile.location ?? "")
        _bio = State(initialValue: profile.bio ?? "")
        _selectedInterests = State(initialValue: Set(profile.interests))
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(userID: userID, profile: profile))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                mediaSection
                interestsSection
                bioSection
                privacySection
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.custom(20))
            .scrollContentBackground(.hidden)
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(viewModel.state.isSaving || !isFormValid)
                }
                
                if viewModel.state.isSaving {
                    ToolbarItem(placement: .principal) {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .overlay(alignment: .top) {
                if let errorMessage = viewModel.state.errorMessage {
                    errorBanner(errorMessage)
                }
            }
        }
        .tint(AroosiColors.primary)
        .sheet(isPresented: $showingMediaUpload) {
            MediaUploadView(
                maxImages: 6,
                uploadedMediaURLs: $profileMediaURLs
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("Display Name", text: $displayName)
                .textInputAutocapitalization(.words)
            
            TextField("Age", text: $age)
                .keyboardType(.numberPad)
            
            TextField("Location", text: $location)
                .textInputAutocapitalization(.words)
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var mediaSection: some View {
        Section("Photos") {
            Button {
                showingMediaUpload = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundStyle(AroosiColors.primary)
                    Text("Manage Photos")
                    Spacer()
                    Text("\(profileMediaURLs.count) photos")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            if !profileMediaURLs.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(Array(profileMediaURLs.enumerated()), id: \.offset) { index, url in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var interestsSection: some View {
        Section("Interests") {
            if viewModel.state.isLoadingInterests {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Loading interests...")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.muted)
                }
            } else {
                ForEach(viewModel.state.availableInterests, id: \.self) { interest in
                    Toggle(isOn: Binding(
                        get: { selectedInterests.contains(interest) },
                        set: { isSelected in
                            if isSelected {
                                selectedInterests.insert(interest)
                            } else {
                                selectedInterests.remove(interest)
                            }
                        }
                    )) {
                        Text(interest.capitalized)
                    }
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var bioSection: some View {
        Section("About Me") {
            TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var privacySection: some View {
        Section("Privacy") {
            Toggle(isOn: Binding(
                get: { viewModel.state.profileVisibility == .public },
                set: { viewModel.updateProfileVisibility($0 ? .public : .private) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Public Profile")
                        .font(AroosiTypography.body())
                    Text("Allow others to find and view your profile")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.showAge },
                set: { viewModel.updateShowAge($0) }
            )) {
                Text("Show Age")
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.showLocation },
                set: { viewModel.updateShowLocation($0) }
            )) {
                Text("Show Location")
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.isEmpty &&
        Int(age) != nil &&
        Int(age)! >= 18 &&
        Int(age)! <= 100
    }
    
    private func saveProfile() {
        Task {
            do {
                let updatedProfile = ProfileSummary(
                    id: viewModel.state.profile?.id ?? "",
                    displayName: viewModel.state.profile?.displayName ?? "",
                    age: viewModel.state.profile?.age ?? 0,
                    bio: viewModel.state.profile?.bio ?? "",
                    interests: Array(selectedInterests),
                    avatarURL: profileMediaURLs.first,
                    location: viewModel.state.profile?.location,
                    lastActiveAt: Date()
                )
                
                try await viewModel.updateProfile(updatedProfile, mediaURLs: profileMediaURLs)
                onSave()
                
                // Show success toast
                ToastManager.shared.showSuccess("Profile updated successfully!")
                
                dismiss()
                
            } catch {
                viewModel.state.errorMessage = "Failed to save profile: \(error.localizedDescription)"
            }
        }
    }
    
    private func errorBanner(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.red.opacity(0.85))
                .clipShape(Capsule())
                .padding(.top, 8)
                .onTapGesture {
                    viewModel.clearError()
                }
            Spacer()
        }
    }
}

@available(iOS 17, *)
#Preview {
    EditProfileView(
        userID: "test-user",
        profile: ProfileSummary.mock,
        onSave: {}
    )
    .environmentObject(NavigationCoordinator())
}

#endif
