import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
@MainActor
public final class FamilyApprovalService: ObservableObject {
    @Published public private(set) var receivedRequests: [FamilyApprovalRequest] = []
    @Published public private(set) var sentRequests: [FamilyApprovalRequest] = []
    @Published public private(set) var familyMembers: [FamilyMember] = []
    @Published public private(set) var summary: FamilyApprovalSummary?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    private let repository: FamilyApprovalRepository
    private let profileRepository: ProfileRepository
    private let analytics: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        repository: FamilyApprovalRepository = FamilyApprovalRepository(),
        profileRepository: ProfileRepository = FirestoreProfileRepository(),
        analytics: AnalyticsService = .shared
    ) {
        self.repository = repository
        self.profileRepository = profileRepository
        self.analytics = analytics
    }
    
    // MARK: - Load Data
    
    public func loadRequests(userId: String) async {
        isLoading = true
        error = nil
        
        do {
            async let received = repository.fetchReceivedRequests(userId: userId)
            async let sent = repository.fetchSentRequests(userId: userId)
            
            receivedRequests = try await received
            sentRequests = try await sent
            
            // Enrich with profile data
            await enrichRequestsWithProfiles()
            
            analytics.track(AnalyticsEvent(
                name: "family_approval_requests_loaded",
                parameters: [
                    "received_count": "\(receivedRequests.count)",
                    "sent_count": "\(sentRequests.count)"
                ]
            ))
        } catch {
            self.error = error
            Logger.shared.error("Failed to load family approval requests: \(error)")
        }
        
        isLoading = false
    }
    
    public func loadFamilyMembers(userId: String) async {
        do {
            familyMembers = try await repository.fetchFamilyMembers(userId: userId)
            
            analytics.track(AnalyticsEvent(
                name: "family_members_loaded",
                parameters: [
                    "count": "\(familyMembers.count)"
                ]
            ))
        } catch {
            Logger.shared.error("Failed to load family members: \(error)")
        }
    }
    
    public func loadSummary(userId: String) async {
        do {
            summary = try await repository.fetchSummary(userId: userId)
        } catch {
            Logger.shared.error("Failed to load summary: \(error)")
        }
    }
    
    public func refreshAll(userId: String) async {
        await loadRequests(userId: userId)
        await loadFamilyMembers(userId: userId)
        await loadSummary(userId: userId)
    }
    
    // MARK: - Create Request
    
    public func createRequest(
        requesterId: String,
        targetUserId: String,
        message: String,
        selectedMembers: [FamilyMember]
    ) async -> Bool {
        guard !selectedMembers.isEmpty else {
            error = NSError(domain: "FamilyApproval", code: -1, 
                          userInfo: [NSLocalizedDescriptionKey: "Please select at least one family member"])
            return false
        }
        
        isLoading = true
        error = nil
        
        do {
            _ = try await repository.createRequest(
                requesterId: requesterId,
                targetUserId: targetUserId,
                message: message,
                familyMembers: selectedMembers
            )
            
            analytics.track(AnalyticsEvent(
                name: "family_approval_request_created",
                parameters: [
                    "target_user_id": targetUserId,
                    "family_members_count": "\(selectedMembers.count)"
                ]
            ))
            
            await loadRequests(userId: requesterId)
            isLoading = false
            return true
        } catch {
            self.error = error
            Logger.shared.error("Failed to create approval request: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Respond to Request
    
    public func respondToRequest(
        requestId: String,
        decision: ApprovalDecision,
        response: String?,
        userId: String
    ) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await repository.respondToRequest(
                requestId: requestId,
                decision: decision,
                response: response
            )
            
            analytics.track(AnalyticsEvent(
                name: "family_approval_response_submitted",
                parameters: [
                    "request_id": requestId,
                    "decision": decision.rawValue
                ]
            ))
            
            await loadRequests(userId: userId)
            isLoading = false
            return true
        } catch {
            self.error = error
            Logger.shared.error("Failed to respond to request: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Cancel Request
    
    public func cancelRequest(requestId: String, userId: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await repository.cancelRequest(requestId: requestId)
            
            analytics.track(AnalyticsEvent(
                name: "family_approval_request_cancelled",
                parameters: [
                    "request_id": requestId
                ]
            ))
            
            await loadRequests(userId: userId)
            isLoading = false
            return true
        } catch {
            self.error = error
            Logger.shared.error("Failed to cancel request: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Family Members
    
    public func addFamilyMember(
        userId: String,
        name: String,
        relation: FamilyRelation,
        email: String?,
        phone: String?,
        canApprove: Bool = true
    ) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let member = try await repository.addFamilyMember(
                userId: userId,
                name: name,
                relation: relation,
                email: email,
                phone: phone,
                canApprove: canApprove
            )
            
            familyMembers.append(member)
            
            analytics.track(AnalyticsEvent(
                name: "family_member_added",
                parameters: [
                    "relation": relation.rawValue
                ]
            ))
            
            isLoading = false
            return true
        } catch {
            self.error = error
            Logger.shared.error("Failed to add family member: \(error)")
            isLoading = false
            return false
        }
    }
    
    public func updateFamilyMember(member: FamilyMember) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await repository.updateFamilyMember(member: member)
            
            if let index = familyMembers.firstIndex(where: { $0.id == member.id }) {
                familyMembers[index] = member
            }
            
            analytics.track(AnalyticsEvent(
                name: "family_member_updated",
                parameters: [
                    "member_id": member.id
                ]
            ))
            
            isLoading = false
            return true
        } catch {
            self.error = error
            Logger.shared.error("Failed to update family member: \(error)")
            isLoading = false
            return false
        }
    }
    
    public func deleteFamilyMember(memberId: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            try await repository.deleteFamilyMember(memberId: memberId)
            
            familyMembers.removeAll { $0.id == memberId }
            
            analytics.track(AnalyticsEvent(
                name: "family_member_deleted",
                parameters: [
                    "member_id": memberId
                ]
            ))
            
            isLoading = false
            return true
        } catch {
            self.error = error
            Logger.shared.error("Failed to delete family member: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Helpers
    
    private func enrichRequestsWithProfiles() async {
        // Collect unique user IDs
        var userIds = Set<String>()
        receivedRequests.forEach { request in
            userIds.insert(request.requesterId)
            userIds.insert(request.targetUserId)
        }
        sentRequests.forEach { request in
            userIds.insert(request.requesterId)
            userIds.insert(request.targetUserId)
        }
        
        // Fetch profiles
        var profiles: [String: ProfileSummary] = [:]
        for userId in userIds {
            if let profile = try? await profileRepository.fetchProfile(id: userId) {
                profiles[userId] = profile
            }
        }
        
        // Enrich requests
        receivedRequests = receivedRequests.map { request in
            var enriched = request
            enriched.requesterProfile = profiles[request.requesterId]
            enriched.targetUserProfile = profiles[request.targetUserId]
            return enriched
        }
        
        sentRequests = sentRequests.map { request in
            var enriched = request
            enriched.requesterProfile = profiles[request.requesterId]
            enriched.targetUserProfile = profiles[request.targetUserId]
            return enriched
        }
    }
    
    public func getPendingCount() -> Int {
        receivedRequests.filter { $0.isPending }.count
    }
    
    public func getApprovalRate() -> Double {
        summary?.approvalRate ?? 0.0
    }
}
#endif
