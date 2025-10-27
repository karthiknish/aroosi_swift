#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct MatrimonyOnboardingView: View {
    @StateObject private var viewModel: MatrimonyOnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void
    
    @MainActor
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: MatrimonyOnboardingViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            progressIndicator
            
            // Content
            TabView(selection: $viewModel.currentStep) {
                // Step 1: Welcome to Matrimony
                MatrimonyWelcomeStep(
                    onNext: { viewModel.nextStep() }
                )
                .tag(OnboardingStep.welcome)
                
                // Step 2: Marriage Intentions
                MarriageIntentionsStep(
                    selectedIntention: Binding(
                        get: { viewModel.marriageIntention },
                        set: { viewModel.marriageIntention = $0 }
                    ),
                    onNext: { viewModel.nextStep() }
                )
                .tag(OnboardingStep.intentions)
                
                // Step 3: Family Values
                FamilyValuesStep(
                    selectedValues: Binding(
                        get: { viewModel.familyValues },
                        set: { viewModel.familyValues = $0 }
                    ),
                    onNext: { viewModel.nextStep() }
                )
                .tag(OnboardingStep.familyValues)
                
                // Step 4: Religious Preferences
                ReligiousPreferencesStep(
                    selectedReligion: Binding(
                        get: { viewModel.religiousPreference },
                        set: { viewModel.religiousPreference = $0 }
                    ),
                    onNext: { viewModel.nextStep() }
                )
                .tag(OnboardingStep.religion)
                
                // Step 5: Partner Preferences
                PartnerPreferencesStep(
                    preferences: Binding(
                        get: { viewModel.partnerPreferences },
                        set: { viewModel.partnerPreferences = $0 }
                    ),
                    onNext: { viewModel.nextStep() }
                )
                .tag(OnboardingStep.preferences)
                
                // Step 6: Family Involvement
                FamilyInvolvementStep(
                    requiresApproval: Binding(
                        get: { viewModel.requiresFamilyApproval },
                        set: { viewModel.requiresFamilyApproval = $0 }
                    ),
                    onNext: { viewModel.nextStep() }
                )
                .tag(OnboardingStep.familyInvolvement)
                
                // Step 7: Complete
                MatrimonyCompletionStep(
                    onComplete: onComplete
                )
                .tag(OnboardingStep.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
        .background(AroosiColors.matrimonyBackground)
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.clearError()
                }
            }
        }
    }
    
    private var progressIndicator: some View {
        HStack {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step <= viewModel.currentStep ? AroosiColors.matrimonyPrimary : AroosiColors.matrimonySecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == viewModel.currentStep ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Welcome Step

@available(iOS 17, *)
struct MatrimonyWelcomeStep: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Logo and Title
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AroosiColors.matrimonyPrimary)
                
                VStack(spacing: 8) {
                    Text("Aroosi")
                        .font(AroosiTypography.heading(.h1, weight: .bold))
                        .foregroundStyle(AroosiColors.matrimonyPrimary)
                    
                    Text("Matrimony Services")
                        .font(AroosiTypography.heading(.h4))
                        .foregroundStyle(AroosiColors.matrimonySecondary)
                }
            }
            
            // Welcome Message
            VStack(spacing: 16) {
                Text("Find Your Life Partner")
                    .font(AroosiTypography.heading(.h2))
                    .foregroundStyle(AroosiColors.text)
                    .multilineTextAlignment(.center)
                
                Text("Connect with serious individuals seeking marriage. Our platform respects cultural values and family traditions.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Key Features
            VStack(spacing: 12) {
                FeatureRow(icon: "checkmark.shield.fill", title: "Verified Profiles", description: "All profiles are verified for authenticity")
                FeatureRow(icon: "heart.fill", title: "Marriage Focused", description: "Serious individuals seeking lifelong commitment")
                FeatureRow(icon: "person.3.fill", title: "Family Involvement", description: "Respect cultural and family values")
                FeatureRow(icon: "lock.fill", title: "Privacy Protected", description: "Your information is secure and confidential")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue Button
            Button {
                onNext()
            } label: {
                Text("Begin Your Journey")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AroosiColors.matrimonyPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Marriage Intentions Step

@available(iOS 17, *)
struct MarriageIntentionsStep: View {
    @Binding var selectedIntention: MarriageIntention
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Marriage Intentions")
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("Help us understand your marriage goals to find compatible matches")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach(MarriageIntention.allCases, id: \.self) { intention in
                    IntentionCard(
                        intention: intention,
                        isSelected: selectedIntention == intention,
                        onTap: { selectedIntention = intention }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                onNext()
            } label: {
                Text("Continue")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedIntention != nil ? AroosiColors.matrimonyPrimary : AroosiColors.muted)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedIntention == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Family Values Step

@available(iOS 17, *)
struct FamilyValuesStep: View {
    @Binding var selectedValues: Set<FamilyValue>
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Family Values")
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("Select the family values that are important to you")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(FamilyValue.allCases, id: \.self) { value in
                    FamilyValueCard(
                        value: value,
                        isSelected: selectedValues.contains(value),
                        onTap: {
                            if selectedValues.contains(value) {
                                selectedValues.remove(value)
                            } else {
                                selectedValues.insert(value)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                onNext()
            } label: {
                Text("Continue")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(!selectedValues.isEmpty ? AroosiColors.matrimonyPrimary : AroosiColors.muted)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedValues.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Religious Preferences Step

@available(iOS 17, *)
struct ReligiousPreferencesStep: View {
    @Binding var selectedReligion: Religion?
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Religious Preferences")
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("Select your religious preference for compatible matching")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Religion.allCases, id: \.self) { religion in
                        ReligionCard(
                            religion: religion,
                            isSelected: selectedReligion == religion,
                            onTap: { selectedReligion = religion }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Button {
                onNext()
            } label: {
                Text("Continue")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedReligion != nil ? AroosiColors.matrimonyPrimary : AroosiColors.muted)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedReligion == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Partner Preferences Step

@available(iOS 17, *)
struct PartnerPreferencesStep: View {
    @Binding var preferences: PartnerPreferences
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Partner Preferences")
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("Set your preferences for finding the right life partner")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Age Range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age Range")
                            .font(AroosiTypography.body(weight: .medium))
                            .foregroundStyle(AroosiColors.text)
                        
                        HStack {
                            Text("\(preferences.minAge) - \(preferences.maxAge)")
                                .font(AroosiTypography.body())
                                .foregroundStyle(AroosiColors.matrimonyPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AroosiColors.matrimonySecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Education Level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Education Level")
                            .font(AroosiTypography.body(weight: .medium))
                            .foregroundStyle(AroosiColors.text)
                        
                        Picker("Education", selection: $preferences.educationLevel) {
                            Text("No Preference").tag(EducationLevel?.none)
                            ForEach(EducationLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(EducationLevel?.some(level))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AroosiColors.matrimonySecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Occupation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Occupation Preference")
                            .font(AroosiTypography.body(weight: .medium))
                            .foregroundStyle(AroosiColors.text)
                        
                        TextField("Preferred occupation (optional)", text: $preferences.occupation)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AroosiColors.matrimonySecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Button {
                onNext()
            } label: {
                Text("Continue")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AroosiColors.matrimonyPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Family Involvement Step

@available(iOS 17, *)
struct FamilyInvolvementStep: View {
    @Binding var requiresApproval: Bool
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Family Involvement")
                .font(AroosiTypography.heading(.h2))
                .foregroundStyle(AroosiColors.text)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("Do you require family approval for marriage proposals?")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                FamilyInvolvementCard(
                    title: "Yes, Family Approval Required",
                    description: "My family must approve potential matches",
                    icon: "person.3.fill",
                    isSelected: requiresApproval,
                    onTap: { requiresApproval = true }
                )
                
                FamilyInvolvementCard(
                    title: "No, I Can Decide Independently",
                    description: "I can make my own marriage decisions",
                    icon: "person.fill",
                    isSelected: !requiresApproval,
                    onTap: { requiresApproval = false }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                onNext()
            } label: {
                Text("Complete Setup")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AroosiColors.matrimonyPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Completion Step

@available(iOS 17, *)
struct MatrimonyCompletionStep: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AroosiColors.matrimonyPrimary)
            
            VStack(spacing: 16) {
                Text("Welcome to Aroosi Matrimony")
                    .font(AroosiTypography.heading(.h2))
                    .foregroundStyle(AroosiColors.text)
                    .multilineTextAlignment(.center)
                
                Text("Your profile is ready. Start your journey to finding a life partner who shares your values and traditions.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Button {
                onComplete()
            } label: {
                Text("Find Your Life Partner")
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AroosiColors.matrimonyPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AroosiColors.matrimonyPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AroosiTypography.body(weight: .medium))
                    .foregroundStyle(AroosiColors.text)
                
                Text(description)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AroosiColors.matrimonySecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct IntentionCard: View {
    let intention: MarriageIntention
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: intention.icon)
                    .font(.title)
                    .foregroundStyle(isSelected ? .white : AroosiColors.matrimonyPrimary)
                
                VStack(spacing: 4) {
                    Text(intention.title)
                        .font(AroosiTypography.body(weight: .medium))
                        .foregroundStyle(isSelected ? .white : AroosiColors.text)
                    
                    Text(intention.description)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : AroosiColors.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? AroosiColors.matrimonyPrimary : AroosiColors.matrimonySecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct FamilyValueCard: View {
    let value: FamilyValue
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: value.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : AroosiColors.matrimonyPrimary)
                
                Text(value.displayName)
                    .font(AroosiTypography.body(weight: .medium))
                    .foregroundStyle(isSelected ? .white : AroosiColors.text)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? AroosiColors.matrimonyPrimary : AroosiColors.matrimonySecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ReligionCard: View {
    let religion: Religion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: religion.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : AroosiColors.matrimonyPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(religion.displayName)
                        .font(AroosiTypography.body(weight: .medium))
                        .foregroundStyle(isSelected ? .white : AroosiColors.text)
                    
                    Text(religion.description)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : AroosiColors.muted)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? AroosiColors.matrimonyPrimary : AroosiColors.matrimonySecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct FamilyInvolvementCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(isSelected ? .white : AroosiColors.matrimonyPrimary)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(AroosiTypography.body(weight: .medium))
                        .foregroundStyle(isSelected ? .white : AroosiColors.text)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : AroosiColors.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? AroosiColors.matrimonyPrimary : AroosiColors.matrimonySecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

@available(iOS 17, *)
#Preview {
    MatrimonyOnboardingView {
        print("Onboarding completed")
    }
}

#endif
