#if os(iOS)
import SwiftUI
import CoreLocation

@available(iOS 17, *)
struct AdvancedSearchFiltersView: View {
    @StateObject private var viewModel: AdvancedSearchFiltersViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: SearchFilters
    
    @MainActor
    init(initialFilters: SearchFilters) {
        _filters = Binding(initialValue: initialFilters)
        _viewModel = StateObject(wrappedValue: AdvancedSearchFiltersViewModel(initialFilters: initialFilters))
    }
    
    var body: some View {
        NavigationStack {
            List {
                basicFiltersSection
                locationSection
                interestsSection
                culturalPreferencesSection
                lifestyleSection
                advancedSection
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.custom(20))
            .scrollContentBackground(.hidden)
            .background(AroosiColors.groupedBackground)
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filters = viewModel.currentFilters
                        dismiss()
                    }
                    .disabled(viewModel.state.isApplying)
                }
                
                if viewModel.state.isApplying {
                    ToolbarItem(placement: .principal) {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .onAppear {
                viewModel.loadAvailableOptions()
            }
        }
        .tint(AroosiColors.primary)
    }
    
    private var basicFiltersSection: some View {
        Section("Basic Filters") {
            HStack {
                Text("Age Range")
                Spacer()
                Text("\(viewModel.currentFilters.minAge ?? 18) - \(viewModel.currentFilters.maxAge ?? 100)")
                    .foregroundStyle(AroosiColors.muted)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.showAgeRangePicker = true
            }
            
            Picker("Preferred Gender", selection: Binding(
                get: { viewModel.currentFilters.preferredGender ?? "any" },
                set: { viewModel.updateFilter(key: .preferredGender, value: $0 == "any" ? nil : $0) }
            )) {
                Text("Any").tag("any")
                Text("Male").tag("male")
                Text("Female").tag("female")
                Text("Non-binary").tag("non-binary")
            }
            .pickerStyle(.segmented)
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var locationSection: some View {
        Section("Location") {
            Toggle(isOn: Binding(
                get: { viewModel.state.locationBasedSearchEnabled },
                set: { viewModel.toggleLocationBasedSearch($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location-Based Search")
                        .font(AroosiTypography.body())
                    Text("Find profiles near your current location")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            if viewModel.state.locationBasedSearchEnabled {
                HStack {
                    Text("Search Radius")
                    Spacer()
                    Text("\(viewModel.state.searchRadius) miles")
                        .foregroundStyle(AroosiColors.muted)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.showRadiusPicker = true
                }
                
                if let location = viewModel.state.currentLocation {
                    HStack {
                        Text("Current Location")
                        Spacer()
                        Text("Lat: \(String(format: "%.4f", location.latitude)), Lon: \(String(format: "%.4f", location.longitude))")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.muted)
                    }
                }
                
                Toggle(isOn: Binding(
                    get: { viewModel.state.includeNearbyCities },
                    set: { viewModel.updateIncludeNearbyCities($0) }
                )) {
                    Text("Include Nearby Cities")
                }
            }
            
            TextField("City or Region", text: Binding(
                get: { viewModel.currentFilters.city ?? "" },
                set: { viewModel.updateFilter(key: .city, value: $0.isEmpty ? nil : $0) }
            ))
            .textInputAutocapitalization(.words)
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var interestsSection: some View {
        Section("Interests & Hobbies") {
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
                        get: { viewModel.state.selectedInterests.contains(interest) },
                        set: { viewModel.toggleInterest(interest, isSelected: $0) }
                    )) {
                        Text(interest.capitalized)
                    }
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var culturalPreferencesSection: some View {
        Section("Cultural Preferences") {
            Picker("Religious Preference", selection: Binding(
                get: { viewModel.state.religiousPreference ?? "any" },
                set: { viewModel.updateReligiousPreference($0 == "any" ? nil : $0) }
            )) {
                Text("Any").tag("any")
                Text("Muslim").tag("muslim")
                Text("Christian").tag("christian")
                Text("Jewish").tag("jewish")
                Text("Hindu").tag("hindu")
                Text("Buddhist").tag("buddhist")
                Text("Other").tag("other")
                Text("Non-religious").tag("non-religious")
            }
            
            Picker("Family Values", selection: Binding(
                get: { viewModel.state.familyValues ?? "any" },
                set: { viewModel.updateFamilyValues($0 == "any" ? nil : $0) }
            )) {
                Text("Any").tag("any")
                Text("Traditional").tag("traditional")
                Text("Moderate").tag("moderate")
                Text("Liberal").tag("liberal")
                Text("Progressive").tag("progressive")
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.familyApprovalRequired },
                set: { viewModel.updateFamilyApprovalRequired($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Approval Required")
                        .font(AroosiTypography.body())
                    Text("Only show profiles requiring family approval")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var lifestyleSection: some View {
        Section("Lifestyle") {
            Picker("Education Level", selection: Binding(
                get: { viewModel.state.educationLevel ?? "any" },
                set: { viewModel.updateEducationLevel($0 == "any" ? nil : $0) }
            )) {
                Text("Any").tag("any")
                Text("High School").tag("high_school")
                Text("Some College").tag("some_college")
                Text("Bachelor's Degree").tag("bachelors")
                Text("Master's Degree").tag("masters")
                Text("PhD/Doctorate").tag("phd")
                Text("Professional Degree").tag("professional")
            }
            
            Picker("Occupation", selection: Binding(
                get: { viewModel.state.occupation ?? "any" },
                set: { viewModel.updateOccupation($0 == "any" ? nil : $0) }
            )) {
                Text("Any").tag("any")
                Text("Technology").tag("technology")
                Text("Healthcare").tag("healthcare")
                Text("Education").tag("education")
                Text("Business").tag("business")
                Text("Creative Arts").tag("creative")
                Text("Legal").tag("legal")
                Text("Finance").tag("finance")
                Text("Engineering").tag("engineering")
                Text("Other").tag("other")
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.smokerFriendly },
                set: { viewModel.updateSmokerFriendly($0) }
            )) {
                Text("Smoker Friendly")
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.drinksAlcohol },
                set: { viewModel.updateDrinksAlcohol($0) }
            )) {
                Text("Drinks Alcohol")
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
    
    private var advancedSection: some View {
        Section("Advanced Options") {
            Toggle(isOn: Binding(
                get: { viewModel.state.includeInactiveProfiles },
                set: { viewModel.updateIncludeInactiveProfiles($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Include Inactive Profiles")
                        .font(AroosiTypography.body())
                    Text("Show profiles that haven't been active recently")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Toggle(isOn: Binding(
                get: { viewModel.state.onlyVerifiedProfiles },
                set: { viewModel.updateOnlyVerifiedProfiles($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Only Verified Profiles")
                        .font(AroosiTypography.body())
                    Text("Show only profiles with verified information")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            HStack {
                Text("Results Per Page")
                Spacer()
                Picker("Results", selection: Binding(
                    get: { viewModel.currentFilters.pageSize ?? 20 },
                    set: { viewModel.updateFilter(key: .pageSize, value: $0) }
                )) {
                    Text("10").tag(10)
                    Text("20").tag(20)
                    Text("30").tag(30)
                    Text("50").tag(50)
                }
                .pickerStyle(.segmented)
            }
        }
        .listRowBackground(AroosiColors.groupedSecondaryBackground)
    }
}

@available(iOS 17, *)
#Preview {
    AdvancedSearchFiltersView(initialFilters: SearchFilters())
        .environmentObject(NavigationCoordinator())
}

#endif
