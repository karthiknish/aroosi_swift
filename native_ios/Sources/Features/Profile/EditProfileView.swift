#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: EditProfileViewModel
    let onSave: () -> Void
    
    @State private var selectedGender: String = ""
    @State private var selectedMaritalStatus: String = ""
    @State private var selectedDiet: String = ""
    @State private var selectedSmoking: String = ""
    @State private var selectedDrinking: String = ""
    @State private var dateOfBirth: Date = Date()
    
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
            Form {
                basicInfoSection
                personalDetailsSection
                aboutSection
                interestsSection
                lifestyleSection
                professionalSection
                partnerPreferencesSection
                
                if let error = viewModel.form.errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.form.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                if await viewModel.save() {
                                    onSave()
                                    dismiss()
                                }
                            }
                        }
                        .disabled(viewModel.form.isSaving)
                    }
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        Section(header: Text("Basic Information")) {
            TextField("Full Name", text: binding(
                get: { viewModel.form.displayName },
                set: viewModel.updateDisplayName
            ))
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            
            DatePicker("Date of Birth", 
                      selection: $dateOfBirth,
                      displayedComponents: .date)
            
            TextField("Age", text: binding(
                get: { viewModel.form.age },
                set: viewModel.updateAge
            ))
            .keyboardType(.numberPad)
            
            Picker("Gender", selection: $selectedGender) {
                ForEach(genderOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        }
    }
    
    private var personalDetailsSection: some View {
        Section(header: Text("Personal Details")) {
            TextField("City", text: binding(
                get: { viewModel.form.location },
                set: viewModel.updateLocation
            ))
            .textInputAutocapitalization(.words)
            
            TextField("Country", text: .constant("UK"))
                .disabled(true)
            
            HStack {
                TextField("Height (ft)", text: .constant(""))
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
                
                TextField("(in)", text: .constant(""))
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
            }
            
            Picker("Marital Status", selection: $selectedMaritalStatus) {
                ForEach(maritalStatusOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("About Me")) {
            TextEditor(text: binding(
                get: { viewModel.form.bio },
                set: viewModel.updateBio
            ))
            .frame(minHeight: 100)
        }
    }
    
    private var interestsSection: some View {
        Section(
            header: Text("Interests & Hobbies"),
            footer: Text("Separate each interest with a comma")
        ) {
            TextField("e.g. Travel, Reading, Cooking", text: binding(
                get: { viewModel.form.interests },
                set: viewModel.updateInterests
            ))
        }
    }
    
    private var lifestyleSection: some View {
        Section(header: Text("Lifestyle")) {
            Picker("Diet", selection: $selectedDiet) {
                ForEach(dietOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            
            Picker("Smoking", selection: $selectedSmoking) {
                ForEach(smokingOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            
            Picker("Drinking", selection: $selectedDrinking) {
                ForEach(drinkingOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            
            TextField("Religion", text: .constant(""))
            TextField("Mother Tongue", text: .constant(""))
            TextField("Ethnicity", text: .constant(""))
        }
    }
    
    private var professionalSection: some View {
        Section(header: Text("Professional")) {
            TextField("Education", text: .constant(""))
            TextField("Occupation", text: .constant(""))
            TextField("Annual Income", text: .constant(""))
                .keyboardType(.numberPad)
        }
    }
    
    private var partnerPreferencesSection: some View {
        Section(header: Text("Partner Preferences")) {
            HStack {
                TextField("Min Age", text: .constant(""))
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
                
                Text("to")
                    .foregroundStyle(.secondary)
                
                TextField("Max Age", text: .constant(""))
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
            }
            
            TextField("Preferred Cities", text: .constant(""))
                .textInputAutocapitalization(.words)
        }
    }

    private func binding<Value>(get: @escaping () -> Value,
                                set: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(get: get, set: set)
    }
}

#endif
