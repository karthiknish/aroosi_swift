#if os(iOS)
import SwiftUI
import PhotosUI

/**
 * Edit Profile View
 * 
 * Enhanced edit profile screen using reusable form components
 * with proper validation, better UX, and consistent styling.
 */
@available(iOS 17, *)
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: EditProfileViewModel
    let onSave: () -> Void
    
    // MARK: - Form State
    @State private var selectedGender: String = ""
    @State private var selectedMaritalStatus: String = ""
    @State private var selectedDiet: String = ""
    @State private var selectedSmoking: String = ""
    @State private var selectedDrinking: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    
    // MARK: - Photo Picker State
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    
    // MARK: - Options
    private let genderOptions = ["Male", "Female", "Other"]
    private let maritalStatusOptions = ["Single", "Divorced", "Widowed"]
    private let dietOptions = ["Vegetarian", "Non-Vegetarian", "Vegan", "Halal"]
    private let smokingOptions = ["No", "Occasionally", "Yes"]
    private let drinkingOptions = ["No", "Occasionally", "Socially"]

    @MainActor
    init(userID: String,
         profile: ProfileSummary?,
         onSave: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(userID: userID, profile: profile))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Basic Information
                    basicInfoSection
                    
                    // Personal Details
                    personalDetailsSection
                    
                    // About Section
                    aboutSection
                    
                    // Interests Section
                    interestsSection
                    
                    // Lifestyle Section
                    lifestyleSection
                    
                    // Professional Section
                    professionalSection
                    
                    // Partner Preferences
                    partnerPreferencesSection
                    
                    // Error Display
                    if let error = viewModel.form.errorMessage {
                        errorSection(error: error)
                    }
                    
                    // Save Button
                    saveButtonSection
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Save Profile", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
            }
        }
    }
    
    // MARK: - Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImageView.profile(
                url: viewModel.originalProfile?.avatarURL
            )
            .overlay(
                Button(action: {
                    selectedPhotoItem = nil
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue, in: Circle())
                }
                .offset(x: 30, y: 30)
                .disabled(isUploadingPhoto)
            )
            .alignmentGuide(.bottom) { _ in 0 }
            .alignmentGuide(.trailing) { _ in 0 }
            
            Text("Profile Photo")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .photosPicker(
            isPresented: Binding(
                get: { selectedPhotoItem != nil },
                set: { _ in }
            ),
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await handlePhotoSelection(newItem)
            }
        }
    }
    
    // MARK: - Basic Information Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Basic Information", icon: "person.circle")
            
            VStack(spacing: 12) {
                AroosiTextField(
                    text: binding(
                        get: { viewModel.form.displayName },
                        set: viewModel.updateDisplayName
                    ),
                    placeholder: "Full Name",
                    validation: RequiredValidationRule(message: "Display name is required")
                )
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                
                AroosiTextField(
                    text: binding(
                        get: { viewModel.form.age },
                        set: viewModel.updateAge
                    ),
                    placeholder: "Age",
                    validation: MinLengthValidationRule(minLength: 1, message: "Age is required")
                )
                .keyboardType(.numberPad)
                
                // Gender Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(AroosiTypography.body(weight: .semibold))
                        .foregroundStyle(AroosiColors.text)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(genderOptions, id: \.self) { option in
                                GenderChipView(
                                    text: option,
                                    isSelected: selectedGender == option
                                ) {
                                    selectedGender = option
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Date of Birth
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(AroosiTypography.body(weight: .semibold))
                        .foregroundStyle(AroosiColors.text)
                    
                    DatePicker("",
                              selection: $dateOfBirth,
                              displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                        .background(AroosiColors.surface)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(AroosiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Personal Details Section
    
    private var personalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Personal Details", icon: "location.circle")
            
            VStack(spacing: 12) {
                AroosiTextField(
                    text: binding(
                        get: { viewModel.form.location },
                        set: viewModel.updateLocation
                    ),
                    placeholder: "City",
                    validation: RequiredValidationRule(message: "Location is required")
                )
                .textInputAutocapitalization(.words)
                
                // Country (disabled for now)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .font(AroosiTypography.body(weight: .semibold))
                        .foregroundStyle(AroosiColors.text)
                    
                    HStack {
                        Text("United Kingdom")
                            .font(AroosiTypography.body())
                            .foregroundStyle(AroosiColors.muted)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AroosiColors.muted)
                    }
                    .padding()
                    .background(AroosiColors.muted.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Height Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height")
                        .font(AroosiTypography.body(weight: .semibold))
                        .foregroundStyle(AroosiColors.text)
                    
                    HStack(spacing: 8) {
                        AroosiTextField(
                            text: .constant(""),
                            placeholder: "ft",
                            validation: nil
                        )
                        .keyboardType(.numberPad)
                        
                        Text("ft")
                            .font(AroosiTypography.body())
                            .foregroundStyle(AroosiColors.muted)
                        
                        AroosiTextField(
                            text: .constant(""),
                            placeholder: "in",
                            validation: nil
                        )
                        .keyboardType(.numberPad)
                        
                        Text("in")
                            .font(AroosiTypography.body())
                            .foregroundStyle(AroosiColors.muted)
                    }
                }
                
                // Marital Status Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Marital Status")
                        .font(AroosiTypography.body(weight: .semibold))
                        .foregroundStyle(AroosiColors.text)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(maritalStatusOptions, id: \.self) { option in
                                StatusChipView(
                                    text: option,
                                    isSelected: selectedMaritalStatus == option
                                ) {
                                    selectedMaritalStatus = option
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding()
        .background(AroosiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "About Me", icon: "text.alignleft")
            
            AroosiTextArea(
                text: binding(
                    get: { viewModel.form.bio },
                    set: viewModel.updateBio
                ),
                placeholder: "Tell us about yourself, your values, interests, and what you're looking for...",
                style: .large,
                validation: RequiredValidationRule(message: "Please tell us about yourself")
            )
        }
        .padding()
        .background(AroosiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Interests Section
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Interests & Hobbies", icon: "heart.circle")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Interests")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(AroosiColors.text)
                
                AroosiTextField(
                    text: binding(
                        get: { viewModel.form.interests },
                        set: viewModel.updateInterests
                    ),
                    placeholder: "e.g. Travel, Reading, Cooking, Sports",
                    validation: RequiredValidationRule(message: "Please add some interests")
                )
                
                Text("Separate each interest with a comma")
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
        }
        .padding()
        .background(AroosiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Lifestyle Section
    
    private var lifestyleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Lifestyle", icon: "leaf.circle")
            
            VStack(spacing: 12) {
                // Diet Picker
                lifestylePicker(title: "Diet", options: dietOptions, selection: $selectedDiet)
                
                // Smoking Picker
                lifestylePicker(title: "Smoking", options: smokingOptions, selection: $selectedSmoking)
                
                // Drinking Picker
                lifestylePicker(title: "Drinking", options: drinkingOptions, selection: $selectedDrinking)
                
                // Additional lifestyle fields (placeholder for now)
                AroosiTextField(
                    text: .constant(""),
                    placeholder: "Religion",
                    validation: nil
                )
                
                AroosiTextField(
                    text: .constant(""),
                    placeholder: "Mother Tongue",
                    validation: nil
                )
                
                AroosiTextField(
                    text: .constant(""),
                    placeholder: "Ethnicity",
                    validation: nil
                )
            }
        }
        .padding()
        .background(AroosiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Professional Section
    
    private var professionalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Professional", icon: "briefcase.circle")
            
            VStack(spacing: 12) {
                AroosiTextField(
                    text: .constant(""),
                    placeholder: "Education",
                    validation: nil
                )
                
                AroosiTextField(
                    text: .constant(""),
                    placeholder: "Occupation",
                    validation: nil
                )
                
                AroosiTextField(
                    text: .constant(""),
                    placeholder: "Annual Income",
                    validation: nil
                )
                .keyboardType(.numberPad)
            }
        }
        .padding()
        .background(AroosiColors.surface)
        .cornerRadius(16)
    }
    
    // MARK: - Partner Preferences Section
    
    private var partnerPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Partner Preferences", icon: "person.2.circle")
            
            VStack(spacing: 12) {
                // Age Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Age Range")
                        .font(AroosiTypography.body(weight: .semibold))
                        .foregroundStyle(AroosiColors.text)
                    
                    HStack(spacing: 8) {
                        AroosiTextField(
                            text: .constant(""),
                            placeholder: "Min",
                            validation: nil
                        )
                        .keyboardType(.numberPad)
                        
                        Text("to")
                            .font(AroosiTypography.body())
                            .foregroundStyle(AroosiColors.muted)
                        
                        AroosiTextField(
                            text: .constant(""),
                            placeholder: "Max",
                            validation: nil
                        )
                        .keyboardType(.numberPad)
                    }
                }
                
                AroosiTextField(
                    text: .constant(""),
                    placeholder: "Preferred Cities",
                    validation: nil
                )
                .textInputAutocapitalization(.words)
            }
        }
        .padding()
        .background(AroosiColors.surface)
        .cornerRadius(16)
    }

    // MARK: - Error Section
    
    private func errorSection(error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(AroosiColors.error)
            
            Text(error)
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.error)
            
            Spacer()
        }
        .padding()
        .background(AroosiColors.error.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    if await viewModel.save() {
                        onSave()
                        dismiss()
                    } else {
                        saveAlertMessage = viewModel.form.errorMessage ?? "Failed to save profile"
                        showingSaveAlert = true
                    }
                }
            }) {
                HStack {
                    if viewModel.form.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Save Profile")
                            .font(AroosiTypography.body(weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AroosiColors.primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.form.isSaving)
            
            Button("Cancel") {
                dismiss()
            }
            .font(AroosiTypography.body())
            .foregroundStyle(AroosiColors.muted)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AroosiColors.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helper Views
    
    private func lifestylePicker(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AroosiTypography.body(weight: .semibold))
                .foregroundStyle(AroosiColors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        LifestyleChipView(
                            text: option,
                            isSelected: selection.wrappedValue == option
                        ) {
                            selection.wrappedValue = option
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func binding<Value>(get: @escaping () -> Value,
                                set: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(get: get, set: set)
    }
}

// MARK: - Supporting Views

@available(iOS 17, *)
struct EditSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AroosiColors.primary)
            
            Text(title)
                .font(AroosiTypography.heading(size: 18, weight: .semibold))
                .foregroundStyle(AroosiColors.text)
            
            Spacer()
        }
    }
}

@available(iOS 17, *)
struct GenderChipView: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(AroosiTypography.body(weight: .medium))
                .foregroundStyle(isSelected ? .white : AroosiColors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AroosiColors.primary : AroosiColors.surface,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(AroosiColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17, *)
struct StatusChipView: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(AroosiTypography.body(weight: .medium))
                .foregroundStyle(isSelected ? .white : AroosiColors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AroosiColors.primary : AroosiColors.surface,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(AroosiColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17, *)
struct LifestyleChipView: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(AroosiTypography.body(weight: .medium))
                .foregroundStyle(isSelected ? .white : AroosiColors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AroosiColors.primary : AroosiColors.surface,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(AroosiColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Photo Handling

@available(iOS 17, *)
private extension EditProfileView {
    func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        
        do {
            // Load the image data
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                saveAlertMessage = "Failed to load image data"
                showingSaveAlert = true
                return
            }
            
            // Validate image size (max 10MB)
            let maxSize = 10 * 1024 * 1024 // 10MB
            guard imageData.count <= maxSize else {
                saveAlertMessage = "Image size must be less than 10MB"
                showingSaveAlert = true
                return
            }
            
            // Upload image using MediaUploadViewModel
            let mediaViewModel = MediaUploadViewModel()
            await mediaViewModel.processSelectedItems([item])
            
            if let url = mediaViewModel.state.uploadedMedia.first?.url {
                // Update the profile with new image URL
                await viewModel.updateProfileImage(url: url)
                saveAlertMessage = "Profile photo updated successfully!"
            } else if let error = mediaViewModel.state.errorMessage {
                saveAlertMessage = "Upload failed: \(error)"
            } else {
                saveAlertMessage = "Upload completed but no URL received"
            }
            
        } catch {
            saveAlertMessage = "Failed to process image: \(error.localizedDescription)"
        }
        
        showingSaveAlert = true
        selectedPhotoItem = nil
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    EditProfileView(
        userID: "test-user",
        profile: ProfileSummary(
            id: "test-user",
            displayName: "John Doe",
            age: 28,
            location: "London, UK",
            bio: "Software engineer passionate about technology.",
            avatarURL: URL(string: "https://picsum.photos/200/200"),
            interests: ["Technology", "Reading", "Travel"]
        ),
        onSave: { print("Profile saved!") }
    )
}

#endif
