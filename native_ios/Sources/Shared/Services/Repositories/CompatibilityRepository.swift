import Foundation
import FirebaseFirestore

/// Repository for managing compatibility responses and reports in Firestore
@available(iOS 17, *)
public struct CompatibilityRepository {
    
    private let db = Firestore.firestore()
    
    // Collection references
    private var responsesCollection: CollectionReference {
        db.collection("compatibility_responses")
    }
    
    private var reportsCollection: CollectionReference {
        db.collection("compatibility_reports")
    }
    
    public init() {}
    
    // MARK: - Response Operations
    
    /// Save or update a user's compatibility response
    public func saveResponse(_ response: CompatibilityResponse) async throws {
        let data = try encodeResponse(response)
        try await responsesCollection.document(response.userId).setData(data)
    }
    
    /// Fetch a user's compatibility response
    public func fetchResponse(userId: String) async throws -> CompatibilityResponse? {
        let snapshot = try await responsesCollection.document(userId).getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }
        
        return try decodeResponse(from: data, userId: userId)
    }
    
    /// Check if user has completed questionnaire
    public func hasCompletedQuestionnaire(userId: String) async throws -> Bool {
        let snapshot = try await responsesCollection.document(userId).getDocument()
        return snapshot.exists
    }
    
    /// Delete a user's response
    public func deleteResponse(userId: String) async throws {
        try await responsesCollection.document(userId).delete()
    }
    
    // MARK: - Report Operations
    
    /// Save a compatibility report
    public func saveReport(_ report: CompatibilityReport) async throws {
        let data = try encodeReport(report)
        try await reportsCollection.document(report.id).setData(data)
    }
    
    /// Fetch compatibility reports for a user
    public func fetchReports(userId: String) async throws -> [CompatibilityReport] {
        // Optimized: Use Filter.or() instead of two separate queries
        let filter = Filter.orFilter([
            Filter.whereField("userId1", isEqualTo: userId),
            Filter.whereField("userId2", isEqualTo: userId)
        ])
        
        let snapshot = try await reportsCollection
            .whereFilter(filter)
            .order(by: "generatedAt", descending: true)
            .getDocuments()
        
        var reportsDict: [String: CompatibilityReport] = [:]
        
        for document in snapshot.documents {
            if let report = try? decodeReport(from: document.data(), id: document.documentID) {
                // Use dictionary to automatically handle duplicates
                reportsDict[document.documentID] = report
            }
        }
        
        return Array(reportsDict.values).sorted { $0.generatedAt > $1.generatedAt }
    }
    
    /// Fetch a specific report
    public func fetchReport(reportId: String) async throws -> CompatibilityReport? {
        let snapshot = try await reportsCollection.document(reportId).getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }
        
        return try decodeReport(from: data, id: reportId)
    }
    
    /// Share report with another user
    public func shareReport(reportId: String, withUserId: String) async throws {
        try await reportsCollection.document(reportId).updateData([
            "isShared": true,
            "sharedWith": FieldValue.arrayUnion([withUserId]),
            "sharedAt": FieldValue.serverTimestamp()
        ])
    }
    
    /// Delete a report
    public func deleteReport(reportId: String) async throws {
        try await reportsCollection.document(reportId).delete()
    }
    
    // MARK: - Family Feedback Operations
    
    /// Add family feedback to a report
    public func addFamilyFeedback(
        reportId: String,
        feedback: FamilyFeedback
    ) async throws {
        let feedbackData = try encodeFamilyFeedback(feedback)
        
        try await reportsCollection.document(reportId).updateData([
            "familyFeedback": FieldValue.arrayUnion([feedbackData])
        ])
    }
    
    /// Update approval status of family feedback
    public func updateFeedbackStatus(
        reportId: String,
        feedbackId: String,
        status: ApprovalStatus
    ) async throws {
        // Optimized: Use transaction for atomic read-modify-write
        _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let docRef = self.reportsCollection.document(reportId)
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = snapshot.data(),
                  var feedbackArray = data["familyFeedback"] as? [[String: Any]] else {
                return nil
            }
            
            if let index = feedbackArray.firstIndex(where: { ($0["id"] as? String) == feedbackId }) {
                feedbackArray[index]["approvalStatus"] = status.rawValue
                transaction.updateData([
                    "familyFeedback": feedbackArray
                ], forDocument: docRef)
            }
            
            return nil
        })
    }
    
    // MARK: - Encoding/Decoding Helpers
    
    private func encodeResponse(_ response: CompatibilityResponse) throws -> [String: Any] {
        var responsesData: [String: Any] = [:]
        
        for (key, value) in response.responses {
            switch value {
            case .single(let stringValue):
                responsesData[key] = stringValue
            case .multiple(let arrayValue):
                responsesData[key] = arrayValue
            }
        }
        
        return [
            "userId": response.userId,
            "responses": responsesData,
            "completedAt": Timestamp(date: response.completedAt)
        ]
    }
    
    private func decodeResponse(from data: [String: Any], userId: String) throws -> CompatibilityResponse {
        guard let responsesData = data["responses"] as? [String: Any],
              let completedAtTimestamp = data["completedAt"] as? Timestamp else {
            throw CompatibilityError.invalidResponse
        }
        
        var responses: [String: ResponseValue] = [:]
        
        for (key, value) in responsesData {
            if let stringValue = value as? String {
                responses[key] = .single(stringValue)
            } else if let arrayValue = value as? [String] {
                responses[key] = .multiple(arrayValue)
            }
        }
        
        return CompatibilityResponse(
            userId: userId,
            responses: responses,
            completedAt: completedAtTimestamp.dateValue()
        )
    }
    
    private func encodeReport(_ report: CompatibilityReport) throws -> [String: Any] {
        var data: [String: Any] = [
            "id": report.id,
            "userId1": report.userId1,
            "userId2": report.userId2,
            "generatedAt": Timestamp(date: report.generatedAt),
            "isShared": report.isShared,
            "scores": encodeScore(report.scores)
        ]
        
        if let familyFeedback = report.familyFeedback {
            data["familyFeedback"] = try familyFeedback.map { try encodeFamilyFeedback($0) }
        }
        
        return data
    }
    
    private func decodeReport(from data: [String: Any], id: String) throws -> CompatibilityReport {
        guard let userId1 = data["userId1"] as? String,
              let userId2 = data["userId2"] as? String,
              let generatedAtTimestamp = data["generatedAt"] as? Timestamp,
              let scoresData = data["scores"] as? [String: Any] else {
            throw CompatibilityError.invalidResponse
        }
        
        let isShared = data["isShared"] as? Bool ?? false
        let scores = try decodeScore(from: scoresData, userId1: userId1, userId2: userId2)
        
        var familyFeedback: [FamilyFeedback]?
        if let feedbackArray = data["familyFeedback"] as? [[String: Any]] {
            familyFeedback = try feedbackArray.compactMap { try decodeFamilyFeedback(from: $0) }
        }
        
        return CompatibilityReport(
            id: id,
            userId1: userId1,
            userId2: userId2,
            scores: scores,
            generatedAt: generatedAtTimestamp.dateValue(),
            familyFeedback: familyFeedback,
            isShared: isShared
        )
    }
    
    private func encodeScore(_ score: CompatibilityScore) -> [String: Any] {
        var data: [String: Any] = [
            "userId1": score.userId1,
            "userId2": score.userId2,
            "overallScore": score.overallScore,
            "categoryScores": score.categoryScores,
            "calculatedAt": Timestamp(date: score.calculatedAt)
        ]
        
        if let breakdown = score.detailedBreakdown {
            data["detailedBreakdown"] = breakdown
        }
        
        return data
    }
    
    private func decodeScore(from data: [String: Any], userId1: String, userId2: String) throws -> CompatibilityScore {
        guard let overallScore = data["overallScore"] as? Double,
              let categoryScores = data["categoryScores"] as? [String: Double],
              let calculatedAtTimestamp = data["calculatedAt"] as? Timestamp else {
            throw CompatibilityError.invalidResponse
        }
        
        let detailedBreakdown = data["detailedBreakdown"] as? [String: Double]
        
        return CompatibilityScore(
            userId1: userId1,
            userId2: userId2,
            overallScore: overallScore,
            categoryScores: categoryScores,
            calculatedAt: calculatedAtTimestamp.dateValue(),
            detailedBreakdown: detailedBreakdown
        )
    }
    
    private func encodeFamilyFeedback(_ feedback: FamilyFeedback) throws -> [String: Any] {
        return [
            "id": feedback.id,
            "reportId": feedback.reportId,
            "familyMemberName": feedback.familyMemberName,
            "relationship": feedback.relationship,
            "feedback": feedback.feedback,
            "createdAt": Timestamp(date: feedback.createdAt),
            "approvalStatus": feedback.approvalStatus.rawValue
        ]
    }
    
    private func decodeFamilyFeedback(from data: [String: Any]) throws -> FamilyFeedback {
        guard let id = data["id"] as? String,
              let reportId = data["reportId"] as? String,
              let familyMemberName = data["familyMemberName"] as? String,
              let relationship = data["relationship"] as? String,
              let feedbackText = data["feedback"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let statusString = data["approvalStatus"] as? String,
              let status = FamilyFeedbackApprovalStatus(rawValue: statusString) else {
            throw CompatibilityError.invalidResponse
        }
        
        return FamilyFeedback(
            id: id,
            reportId: reportId,
            familyMemberName: familyMemberName,
            relationship: relationship,
            feedback: feedbackText,
            createdAt: createdAtTimestamp.dateValue(),
            approvalStatus: status
        )
    }
}
