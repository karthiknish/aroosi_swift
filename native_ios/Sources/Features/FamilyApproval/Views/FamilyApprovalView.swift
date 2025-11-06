import SwiftUI

#if os(iOS)

#if canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
struct FamilyApprovalView: View {
    @StateObject private var service = FamilyApprovalService()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var selectedTab = 0
    @State private var showCreateRequest = false
    @State private var showManageMembers = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Card
                if let summary = service.summary {
                    SummaryCardView(summary: summary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                
                // Tabs
                Picker("Requests", selection: $selectedTab) {
                    Text("Received (\(service.receivedRequests.count))").tag(0)
                    Text("Sent (\(service.sentRequests.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Content
                if service.isLoading {
                    ProgressView()
                        .tint(Color.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $selectedTab) {
                        ReceivedRequestsTab(requests: service.receivedRequests)
                            .environmentObject(service)
                            .tag(0)
                        
                        SentRequestsTab(requests: service.sentRequests)
                            .environmentObject(service)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Family Approval")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showCreateRequest = true }) {
                            Label("New Request", systemImage: "plus.circle")
                        }
                        
                        Button(action: { showManageMembers = true }) {
                            Label("Manage Family", systemImage: "person.2")
                        }
                        
                        Button(action: refresh) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showCreateRequest) {
                CreateRequestView()
                    .environmentObject(service)
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showManageMembers) {
                ManageFamilyMembersView()
                    .environmentObject(service)
                    .environmentObject(authService)
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        guard let userId = authService.currentUser?.uid else { return }
        await service.refreshAll(userId: userId)
    }
    
    private func refresh() {
        Task {
            await loadData()
        }
    }
}

// MARK: - Summary Card

private struct SummaryCardView: View {
    let summary: FamilyApprovalSummary
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatBox(
                    title: "Pending",
                    value: "\(summary.pendingRequests)",
                    color: .orange,
                    icon: "clock.fill"
                )
                
                StatBox(
                    title: "Approved",
                    value: "\(summary.approvedRequests)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatBox(
                    title: "Family",
                    value: "\(summary.familyMembers)",
                    color: .aroosi,
                    icon: "person.2.fill"
                )
                
                StatBox(
                    title: "Rate",
                    value: String(format: "%.0f%%", summary.approvalRate * 100),
                    color: .blue,
                    icon: "chart.bar.fill"
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Received Requests Tab

private struct ReceivedRequestsTab: View {
    let requests: [FamilyApprovalRequest]
    @EnvironmentObject var service: FamilyApprovalService
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedRequest: FamilyApprovalRequest?
    
    var body: some View {
        ScrollView {
            if requests.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No Received Requests",
                    message: "You haven't received any family approval requests yet"
                )
                .frame(height: 400)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(requests) { request in
                        RequestCard(request: request, isReceived: true)
                            .onTapGesture {
                                selectedRequest = request
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedRequest) { request in
            RequestDetailView(request: request, isReceived: true)
                .environmentObject(service)
                .environmentObject(authService)
        }
    }
}

// MARK: - Sent Requests Tab

private struct SentRequestsTab: View {
    let requests: [FamilyApprovalRequest]
    @EnvironmentObject var service: FamilyApprovalService
    @State private var selectedRequest: FamilyApprovalRequest?
    
    var body: some View {
        ScrollView {
            if requests.isEmpty {
                EmptyStateView(
                    icon: "paperplane",
                    title: "No Sent Requests",
                    message: "You haven't sent any family approval requests yet"
                )
                .frame(height: 400)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(requests) { request in
                        RequestCard(request: request, isReceived: false)
                            .onTapGesture {
                                selectedRequest = request
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedRequest) { request in
            RequestDetailView(request: request, isReceived: false)
                .environmentObject(service)
                .environmentObject(authService)
        }
    }
}

// MARK: - Request Card

private struct RequestCard: View {
    let request: FamilyApprovalRequest
    let isReceived: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Profile Image
                if let profile = isReceived ? request.requesterProfile : request.targetUserProfile {
                    AsyncImage(url: profile.photos.first.flatMap { URL(string: $0) }) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let profile = isReceived ? request.requesterProfile : request.targetUserProfile {
                        Text(profile.name)
                            .font(.headline)
                    }
                    
                    if let familyMemberName = request.familyMemberName {
                        Text("For: \(familyMemberName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(request.formattedCreatedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                StatusBadge(status: request.status)
            }
            
            // Message
            Text(request.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Response (if exists)
            if let response = request.response {
                HStack(spacing: 8) {
                    Image(systemName: request.isApproved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(request.isApproved ? .green : .red)
                    Text(response)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: ApprovalStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .cancelled: return Color(.gray)
        }
    }
}

// MARK: - Empty State

#if os(iOS)

@available(iOS 17.0.0, *)
private struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#endif

// MARK: - Previews

#if os(iOS)
@available(iOS 17.0.0, *)
#Preview {
    FamilyApprovalView()
        
}
#endif
#endif
#endif
