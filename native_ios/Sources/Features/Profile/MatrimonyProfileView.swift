#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct MatrimonyProfileView: View {
    @StateObject private var viewModel: MatrimonyProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: MatrimonyProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Marriage Information
                    marriageInfoSection
                    
                    // Family Details
                    familyDetailsSection
                    
                    // Religious & Cultural Information
                    religiousSection
                    
                    // Education & Career
                    educationSection
                    
                    // Partner Preferences
                    partnerPreferencesSection
                    
                    // Contact Information
                    contactSection
                }
            }
            .background(MatrimonyColors.matrimonyBackground)
            .navigationTitle("Matrimony Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Profile") {
                            viewModel.showEditProfile()
                        }
                        
                        Button("Share Profile") {
                            viewModel.shareProfile()
                        }
                        
                        Button("Report Concern") {
                            viewModel.reportConcern()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(MatrimonyColors.matrimonyPrimary)
                    }
                }
            }
            .refreshable {
                await viewModel.refreshProfile()
            }
            .sheet(isPresented: $viewModel.showingEditProfile) {
                MatrimonyProfileEditView(profile: viewModel.profile)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile Photo
            AsyncImage(url: viewModel.profile?.profilePhotoURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 60)
                    .fill(MatrimonyColors.matrimonySecondary)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(MatrimonyColors.matrimonyPrimary)
                    }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay {
                // Verification Badge
                if viewModel.profile?.isVerified == true {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .background(MatrimonyColors.matrimonySuccess)
                                .clipShape(Circle())
                                .frame(width: 24, height: 24)
                        }
                        Spacer()
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 8)
                }
            }
            
            // Basic Information
            VStack(spacing: 8) {
                Text(viewModel.profile?.displayName ?? "Loading...")
                    .font(MatrimonyTypography.heading(.h2))
                    .foregroundStyle(MatrimonyColors.matrimonyText)
                
                HStack(spacing: 16) {
                    Label("\(viewModel.profile?.age ?? 0)", systemImage: "calendar")
                    Label(viewModel.profile?.height ?? "Not specified", systemImage: "ruler")
                    Label(viewModel.profile?.location ?? "Not specified", systemImage: "location")
                }
                .font(MatrimonyTypography.body())
                .foregroundStyle(MatrimonyColors.matrimonyTextSecondary)
            }
            
            // Marriage Status
            if let marriageIntention = viewModel.profile?.marriageIntention {
                HStack {
                    Image(systemName: marriageIntention.icon)
                        .foregroundStyle(MatrimonyColors.matrimonyPrimary)
                    Text(marriageIntention.title)
                        .font(MatrimonyTypography.body(weight: .medium))
                        .foregroundStyle(MatrimonyColors.matrimonyPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(MatrimonyColors.matrimonySecondary)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(MatrimonyColors.matrimonyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var marriageInfoSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Marriage Information", icon: "heart.fill")
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "heart.circle.fill",
                    title: "Marriage Intention",
                    value: viewModel.profile?.marriageIntention?.title ?? "Not specified"
                )
                
                InfoRow(
                    icon: "clock.fill",
                    title: "Preferred Marriage Time",
                    value: viewModel.profile?.preferredMarriageTime ?? "Not specified"
                )
                
                InfoRow(
                    icon: "person.3.fill",
                    title: "Family Approval Required",
                    value: viewModel.profile?.requiresFamilyApproval == true ? "Yes" : "No"
                )
                
                if let familyValues = viewModel.profile?.familyValues, !familyValues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(MatrimonyColors.matrimonyPrimary)
                                .frame(width: 20)
                            Text("Family Values")
                                .font(MatrimonyTypography.body(weight: .medium))
                                .foregroundStyle(MatrimonyColors.matrimonyText)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(familyValues, id: \.self) { value in
                                Text(value.displayName)
                                    .font(MatrimonyTypography.caption())
                                    .foregroundStyle(MatrimonyColors.matrimonyPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(MatrimonyColors.matrimonySecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(MatrimonyColors.matrimonyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var familyDetailsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Family Details", icon: "person.3.fill")
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "house.fill",
                    title: "Family Type",
                    value: viewModel.profile?.familyType ?? "Not specified"
                )
                
                InfoRow(
                    icon: "person.2.fill",
                    title: "Family Status",
                    value: viewModel.profile?.familyStatus ?? "Not specified"
                )
                
                InfoRow(
                    icon: "banknote.fill",
                    title: "Financial Status",
                    value: viewModel.profile?.financialStatus ?? "Not specified"
                )
                
                InfoRow(
                    icon: "person.crop.rectangle.stack.fill",
                    title: "Number of Siblings",
                    value: viewModel.profile?.numberOfSiblings ?? "Not specified"
                )
            }
        }
        .padding(20)
        .background(MatrimonyColors.matrimonyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var religiousSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Religious & Cultural", icon: "star.fill")
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "star.circle.fill",
                    title: "Religion",
                    value: viewModel.profile?.religion?.displayName ?? "Not specified"
                )
                
                InfoRow(
                    icon: "text.book.closed.fill",
                    title: "Mother Tongue",
                    value: viewModel.profile?.motherTongue ?? "Not specified"
                )
                
                InfoRow(
                    icon: "globe.americas.fill",
                    title: "Community",
                    value: viewModel.profile?.community ?? "Not specified"
                )
                
                InfoRow(
                    icon: "checkmark.shield.fill",
                    title: "Religious Practices",
                    value: viewModel.profile?.religiousPractices ?? "Not specified"
                )
            }
        }
        .padding(20)
        .background(MatrimonyColors.matrimonyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var educationSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Education & Career", icon: "book.fill")
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "graduationcap.fill",
                    title: "Education",
                    value: viewModel.profile?.educationLevel?.displayName ?? "Not specified"
                )
                
                InfoRow(
                    icon: "building.columns.fill",
                    title: "College/University",
                    value: viewModel.profile?.college ?? "Not specified"
                )
                
                InfoRow(
                    icon: "briefcase.fill",
                    title: "Occupation",
                    value: viewModel.profile?.occupation ?? "Not specified"
                )
                
                InfoRow(
                    icon: "building.2.fill",
                    title: "Company",
                    value: viewModel.profile?.company ?? "Not specified"
                )
                
                InfoRow(
                    icon: "banknote.fill",
                    title: "Annual Income",
                    value: viewModel.profile?.annualIncome ?? "Not specified"
                )
            }
        }
        .padding(20)
        .background(MatrimonyColors.matrimonyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var partnerPreferencesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Partner Preferences", icon: "heart.text.square.fill")
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "calendar",
                    title: "Age Range",
                    value: viewModel.profile?.partnerAgeRange ?? "Not specified"
                )
                
                InfoRow(
                    icon: "graduationcap.fill",
                    title: "Partner Education",
                    value: viewModel.profile?.partnerEducationPreference ?? "No preference"
                )
                
                InfoRow(
                    icon: "star.fill",
                    title: "Partner Religion",
                    value: viewModel.profile?.partnerReligionPreference ?? "No preference"
                )
                
                InfoRow(
                    icon: "globe",
                    title: "Partner Location",
                    value: viewModel.profile?.partnerLocationPreference ?? "No preference"
                )
            }
        }
        .padding(20)
        .background(MatrimonyColors.matrimonyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var contactSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Contact Information", icon: "envelope.fill")
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "phone.fill",
                    title: "Phone",
                    value: viewModel.profile?.phoneNumber ?? "Not provided"
                )
                
                InfoRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: viewModel.profile?.email ?? "Not provided"
                )
            }
        }
        .padding(20)
        .background(MatrimonyColors.matrimonyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(MatrimonyColors.matrimonyPrimary)
            
            Text(title)
                .font(MatrimonyTypography.heading(.h4))
                .foregroundStyle(MatrimonyColors.matrimonyText)
            
            Spacer()
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(MatrimonyColors.matrimonyPrimary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MatrimonyTypography.body(weight: .medium))
                    .foregroundStyle(MatrimonyColors.matrimonyText)
                
                Text(value)
                    .font(MatrimonyTypography.body())
                    .foregroundStyle(MatrimonyColors.matrimonyTextSecondary)
            }
            
            Spacer()
        }
    }
}

@available(iOS 17, *)
#Preview {
    MatrimonyProfileView(user: User.mock)
        .environmentObject(NavigationCoordinator())
}

#endif
