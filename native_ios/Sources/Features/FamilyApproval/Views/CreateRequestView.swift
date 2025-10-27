import SwiftUI

#if canImport(UIKit) && canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
struct CreateRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: FamilyApprovalService
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var targetUserId = ""
    @State private var message = ""
    @State private var selectedMembers: Set<String> = []
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Match Details") {
                    TextField("Target User ID", text: $targetUserId)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    TextEditor(text: $message)
                        .frame(height: 120)
                } header: {
                    Text("Request Message")
                } footer: {
                    Text("Explain why you're seeking family approval for this match")
                        .font(.caption)
                        .foregroundStyle(AroosiColors.muted)
                }
                
                Section {
                    if service.familyMembers.isEmpty {
                        VStack(spacing: 12) {
                            Text("No family members added yet")
                                .foregroundStyle(AroosiColors.muted)
                            
                            NavigationLink(destination: ManageFamilyMembersView()) {
                                Text("Add Family Members")
                                    .fontWeight(.medium)
                                    .foregroundStyle(AroosiColors.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(service.familyMembers.filter { $0.canApprove }) { member in
                            FamilyMemberRow(
                                member: member,
                                isSelected: selectedMembers.contains(member.id)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleMember(member.id)
                            }
                        }
                    }
                } header: {
                    Text("Select Family Members")
                } footer: {
                    Text("Select at least one family member to review this request")
                        .font(.caption)
                        .foregroundStyle(AroosiColors.muted)
                }
                
                Section {
                    Button(action: submitRequest) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Request")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AroosiColors.primary)
                    .disabled(isSubmitting || !isValid)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AroosiColors.groupedBackground)
            .navigationTitle("New Approval Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                guard let userId = authService.currentUser?.uid else { return }
                await service.loadFamilyMembers(userId: userId)
            }
        }
    }
    
    private var isValid: Bool {
        !targetUserId.isEmpty &&
        !message.isEmpty &&
        !selectedMembers.isEmpty
    }
    
    private func toggleMember(_ id: String) {
        if selectedMembers.contains(id) {
            selectedMembers.remove(id)
        } else {
            selectedMembers.insert(id)
        }
    }
    
    private func submitRequest() {
        guard let userId = authService.currentUser?.uid else { return }
        
        let members = service.familyMembers.filter { selectedMembers.contains($0.id) }
        
        guard !members.isEmpty else {
            errorMessage = "Please select at least one family member"
            showError = true
            return
        }
        
        isSubmitting = true
        
        Task {
            let success = await service.createRequest(
                requesterId: userId,
                targetUserId: targetUserId,
                message: message,
                selectedMembers: members
            )
            
            isSubmitting = false
            
            if success {
                dismiss()
            } else if let error = service.error {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Manage Family Members View

@available(iOS 17.0.0, *)
struct ManageFamilyMembersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: FamilyApprovalService
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var showAddMember = false
    @State private var editingMember: FamilyMember?
    
    var body: some View {
        NavigationStack {
            List {
                if service.familyMembers.isEmpty {
                    EmptyFamilyState()
                } else {
                    ForEach(service.familyMembers) { member in
                        FamilyMemberDetailRow(member: member)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteMember(member)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingMember = member
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .navigationTitle("Family Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMember = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddFamilyMemberView()
                    .environmentObject(service)
                    .environmentObject(authService)
            }
            .sheet(item: $editingMember) { member in
                EditFamilyMemberView(member: member)
                    .environmentObject(service)
                    .environmentObject(authService)
            }
            .task {
                guard let userId = authService.currentUser?.uid else { return }
                await service.loadFamilyMembers(userId: userId)
            }
        }
    }
    
    private func deleteMember(_ member: FamilyMember) {
        Task {
            await service.deleteFamilyMember(memberId: member.id)
        }
    }
}

// MARK: - Add Family Member View

@available(iOS 17.0.0, *)
private struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: FamilyApprovalService
    @EnvironmentObject private var authService: AuthenticationService
    
    @State private var name = ""
    @State private var relation: FamilyRelation = .father
    @State private var email = ""
    @State private var phone = ""
    @State private var canApprove = true
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Full Name", text: $name)
                    
                    Picker("Relation", selection: $relation) {
                        ForEach(FamilyRelation.allCases, id: \.self) { relation in
                            Text(relation.displayName).tag(relation)
                        }
                    }
                }
                
                Section("Contact (Optional)") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Toggle("Can Approve Matches", isOn: $canApprove)
                }
                
                Section {
                    Button(action: addMember) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add Family Member")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSubmitting || name.isEmpty)
                }
            }
            .navigationTitle("Add Family Member")
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
    
    private func addMember() {
        guard let userId = authService.currentUser?.uid else { return }
        
        isSubmitting = true
        
        Task {
            let success = await service.addFamilyMember(
                userId: userId,
                name: name,
                relation: relation,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                canApprove: canApprove
            )
            
            isSubmitting = false
            
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Edit Family Member View

@available(iOS 17.0.0, *)
private struct EditFamilyMemberView: View {
    let member: FamilyMember
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: FamilyApprovalService
    
    @State private var name: String
    @State private var relation: FamilyRelation
    @State private var email: String
    @State private var phone: String
    @State private var canApprove: Bool
    @State private var isSubmitting = false
    
    init(member: FamilyMember) {
        self.member = member
        _name = State(initialValue: member.name)
        _relation = State(initialValue: member.relation)
        _email = State(initialValue: member.email ?? "")
        _phone = State(initialValue: member.phone ?? "")
        _canApprove = State(initialValue: member.canApprove)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Full Name", text: $name)
                    
                    Picker("Relation", selection: $relation) {
                        ForEach(FamilyRelation.allCases, id: \.self) { relation in
                            Text(relation.displayName).tag(relation)
                        }
                    }
                }
                
                Section("Contact") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Toggle("Can Approve Matches", isOn: $canApprove)
                }
                
                Section {
                    Button(action: updateMember) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Update Family Member")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSubmitting || name.isEmpty)
                }
            }
            .navigationTitle("Edit Family Member")
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
    
    private func updateMember() {
        isSubmitting = true
        
        let updatedMember = FamilyMember(
            id: member.id,
            userId: member.userId,
            name: name,
            relation: relation,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            canApprove: canApprove,
            createdAt: member.createdAt
        )
        
        Task {
            let success = await service.updateFamilyMember(member: updatedMember)
            
            isSubmitting = false
            
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

private struct FamilyMemberRow: View {
    let member: FamilyMember
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: member.relation.icon)
                .foregroundStyle(.aroosi)
            
            VStack(alignment: .leading) {
                Text(member.name)
                    .font(.headline)
                Text(member.relation.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.aroosi)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.gray)
            }
        }
    }
}

private struct FamilyMemberDetailRow: View {
    let member: FamilyMember
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: member.relation.icon)
                    .foregroundStyle(.aroosi)
                
                Text(member.name)
                    .font(.headline)
                
                Spacer()
                
                if member.canApprove {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            Text(member.relation.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let email = member.email {
                Label(email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let phone = member.phone {
                Label(phone, systemImage: "phone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyFamilyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text("No Family Members")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Add family members who can review and approve your matches")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Create Request") {
    CreateRequestView()
        .environmentObject(FamilyApprovalService())
        
}

#Preview("Manage Members") {
    ManageFamilyMembersView()
        .environmentObject(FamilyApprovalService())
        
}
#endif

#endif // canImport(UIKit) && canImport(FirebaseFirestore)