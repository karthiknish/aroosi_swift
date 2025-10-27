import SwiftUI
import FirebaseAuth

#if canImport(FirebaseFirestore) && os(iOS)

@available(iOS 17.0, *)
struct RequestDetailView: View {
    let request: FamilyApprovalRequest
    let isReceived: Bool
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: FamilyApprovalService
    
    @State private var showRespondDialog = false
    @State private var selectedDecision: ApprovalDecision = .approve
    @State private var responseText = ""
    @State private var showCancelConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Profile Section
                    if let profile = isReceived ? request.requesterProfile : request.targetUserProfile {
                        ProfileHeaderView(profile: profile)
                    }
                    
                    Divider()
                    
                    // Request Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Status", value: request.status.displayName, icon: request.status.icon)
                        DetailRow(label: "Created", value: request.formattedCreatedDate, icon: "calendar")
                        
                        if let familyMemberName = request.familyMemberName,
                           let familyMemberRelation = request.familyMemberRelation {
                            DetailRow(
                                label: "Family Member",
                                value: "\(familyMemberName) (\(familyMemberRelation))",
                                icon: "person.fill"
                            )
                        }
                        
                        if let respondedDate = request.formattedRespondedDate {
                            DetailRow(label: "Responded", value: respondedDate, icon: "checkmark.circle")
                        }
                    }
                    
                    Divider()
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Message", systemImage: "envelope.fill")
                            .font(.headline)
                        
                        Text(request.message)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AroosiColors.mutedSystemBackground)
                            .cornerRadius(8)
                    }
                    
                    // Response (if exists)
                    if let response = request.response {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Response", systemImage: request.isApproved ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(request.isApproved ? .green : .red)
                            
                            Text(response)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AroosiColors.mutedSystemBackground)
                                .cornerRadius(8)
                        }
                    }
                    
                    // Actions
                    if isReceived && request.isPending {
                        VStack(spacing: 12) {
                            Button(action: { showRespondWithDecision(.approve) }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Approve Request")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showRespondWithDecision(.reject) }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Reject Request")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    if !isReceived && request.isPending {
                        Button(action: { showCancelConfirmation = true }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Cancel Request")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.red)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRespondDialog) {
                RespondToRequestView(
                    request: request,
                    isPresented: $showRespondDialog,
                    decision: $selectedDecision,
                    responseText: $responseText
                )
                .environmentObject(service)
                .onDisappear {
                    if service.receivedRequests.first(where: { $0.id == request.id })?.isPending == false {
                        dismiss()
                    }
                }
            }
            .alert("Cancel Request", isPresented: $showCancelConfirmation) {
                Button("Cancel Request", role: .destructive) {
                    cancelRequest()
                }
                Button("Keep Request", role: .cancel) {}
            } message: {
                Text("Are you sure you want to cancel this family approval request?")
            }
        }
    }
    
    private func showRespondWithDecision(_ decision: ApprovalDecision) {
        selectedDecision = decision
        responseText = ""
        showRespondDialog = true
    }
    
    private func cancelRequest() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let success = await service.cancelRequest(requestId: request.id, userId: userId)
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Profile Header

@available(iOS 17.0.0, *)
private struct ProfileHeaderView: View {
    let profile: ProfileSummary
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: profile.avatarURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let age = profile.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let location = profile.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                        Text(location)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Detail Row

@available(iOS 17.0.0, *)
private struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View{
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Respond to Request View

@available(iOS 17.0.0, *)
private struct RespondToRequestView: View {
    let request: FamilyApprovalRequest
    @Binding var isPresented: Bool
    @Binding var decision: ApprovalDecision
    @Binding var responseText: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: FamilyApprovalService
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: decision.icon)
                                .foregroundStyle(decision == .approve ? .green : .red)
                            Text("You are \(decision == .approve ? "approving" : "rejecting") this request")
                                .font(.headline)
                        }
                        
                        if let profile = request.requesterProfile {
                            Text("From: \(profile.displayName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Response Message (Optional)") {
                    TextEditor(text: $responseText)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: submitResponse) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Response")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("Respond to Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
    
    private func submitResponse() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isSubmitting = true
        
        Task { @MainActor in
            let success = await service.respondToRequest(
                requestId: request.id,
                decision: decision,
                response: responseText.isEmpty ? nil : responseText,
                userId: userId
            )
            
            isSubmitting = false
            
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Previews

#Preview {
    RequestDetailView(
        request: FamilyApprovalRequest(
            id: "1",
            requesterId: "user1",
            targetUserId: "user2",
            status: .pending,
            createdAt: Date(),
            message: "I would like to request your family's approval to proceed with this match.",
            familyMemberName: "Ahmed Khan",
            familyMemberRelation: "father"
        ),
        isReceived: true
    )
    .environmentObject(FamilyApprovalService())
    
}
#endif
