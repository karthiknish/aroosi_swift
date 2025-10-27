import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class IslamicEducationRepository {
    private enum Constants {
        static let collection = "islamic_education"
        static let userProgressCollection = "user_education_progress"
        static let bookmarksCollection = "education_bookmarks"
    }
    
    private let db: Firestore
    private let logger = Logger.shared
    
    public init(db: Firestore = .firestore()) {
        self.db = db
    }
    
    // MARK: - Fetch Content
    
    public func fetchFeaturedContent() async throws -> [IslamicEducationalContent] {
        let snapshot = try await db.collection(Constants.collection)
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? parseContent(from: $0) }
    }
    
    public func fetchContentByCategory(_ category: EducationCategory) async throws -> [IslamicEducationalContent] {
        let snapshot = try await db.collection(Constants.collection)
            .whereField("category", isEqualTo: category.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? parseContent(from: $0) }
    }
    
    public func fetchContent(id: String) async throws -> IslamicEducationalContent {
        let document = try await db.collection(Constants.collection).document(id).getDocument()
        
        guard document.exists, let content = try? parseContent(from: document) else {
            throw RepositoryError.notFound
        }
        
        return content
    }
    
    public func searchContent(query: String) async throws -> [IslamicEducationalContent] {
        // Note: Firestore doesn't support full-text search natively
        // This is a basic implementation; consider using Algolia for production
        let snapshot = try await db.collection(Constants.collection)
            .order(by: "title")
            .getDocuments()
        
        let lowercaseQuery = query.lowercased()
        return snapshot.documents.compactMap { document -> IslamicEducationalContent? in
            guard let content = try? parseContent(from: document) else { return nil }
            let titleMatch = content.title.lowercased().contains(lowercaseQuery)
            let descMatch = content.description.lowercased().contains(lowercaseQuery)
            let tagMatch = content.tags?.contains(where: { $0.lowercased().contains(lowercaseQuery) }) ?? false
            return (titleMatch || descMatch || tagMatch) ? content : nil
        }
    }
    
    // MARK: - User Progress
    
    public func markContentAsViewed(contentId: String, userId: String) async throws {
        let progressRef = db.collection(Constants.userProgressCollection)
            .document(userId)
            .collection("viewed")
            .document(contentId)
        
        try await progressRef.setData([
            "contentId": contentId,
            "viewedAt": FieldValue.serverTimestamp(),
            "completed": false
        ], merge: true)
        
        // Increment view count
        try await db.collection(Constants.collection)
            .document(contentId)
            .updateData(["viewCount": FieldValue.increment(1.0)])
    }
    
    public func markContentAsCompleted(contentId: String, userId: String, quizScore: Int? = nil) async throws {
        let progressRef = db.collection(Constants.userProgressCollection)
            .document(userId)
            .collection("viewed")
            .document(contentId)
        
        var data: [String: Any] = [
            "completed": true,
            "completedAt": FieldValue.serverTimestamp()
        ]
        
        if let score = quizScore {
            data["quizScore"] = score
        }
        
        try await progressRef.setData(data, merge: true)
    }
    
    public func fetchUserProgress(userId: String) async throws -> [String: UserContentProgress] {
        let snapshot = try await db.collection(Constants.userProgressCollection)
            .document(userId)
            .collection("viewed")
            .getDocuments()
        
        var progress: [String: UserContentProgress] = [:]
        for document in snapshot.documents {
            let contentId = document.documentID
            let data = document.data()
            
            let viewed = data["viewedAt"] as? Timestamp
            let completed = data["completed"] as? Bool ?? false
            let completedAt = data["completedAt"] as? Timestamp
            let quizScore = data["quizScore"] as? Int
            
            progress[contentId] = UserContentProgress(
                contentId: contentId,
                viewedAt: viewed?.dateValue(),
                completed: completed,
                completedAt: completedAt?.dateValue(),
                quizScore: quizScore
            )
        }
        
        return progress
    }
    
    // MARK: - Bookmarks
    
    public func toggleBookmark(contentId: String, userId: String) async throws -> Bool {
        let bookmarkRef = db.collection(Constants.bookmarksCollection)
            .document(userId)
            .collection("items")
            .document(contentId)
        
        let snapshot = try await bookmarkRef.getDocument()
        
        if snapshot.exists {
            try await bookmarkRef.delete()
            try await db.collection(Constants.collection)
                .document(contentId)
                .updateData(["bookmarkCount": FieldValue.increment(-1.0)])
            return false
        } else {
            try await bookmarkRef.setData([
                "contentId": contentId,
                "bookmarkedAt": FieldValue.serverTimestamp()
            ])
            try await db.collection(Constants.collection)
                .document(contentId)
                .updateData(["bookmarkCount": FieldValue.increment(1.0)])
            return true
        }
    }
    
    public func fetchBookmarks(userId: String) async throws -> [IslamicEducationalContent] {
        let snapshot = try await db.collection(Constants.bookmarksCollection)
            .document(userId)
            .collection("items")
            .order(by: "bookmarkedAt", descending: true)
            .getDocuments()
        
        let contentIds = snapshot.documents.map { $0.documentID }
        
        // Optimized: Batch fetch content using whereField with in operator
        guard !contentIds.isEmpty else { return [] }
        
        // Firestore 'in' queries support up to 10 items per batch
        let batchSize = 10
        var allContents: [IslamicEducationalContent] = []
        
        for i in stride(from: 0, to: contentIds.count, by: batchSize) {
            let end = min(i + batchSize, contentIds.count)
            let batchIds = Array(contentIds[i..<end])
            
            let batchSnapshot = try await db.collection(Constants.collection)
                .whereField(FieldPath.documentID(), in: batchIds)
                .getDocuments()
            
            let contents = batchSnapshot.documents.compactMap { try? parseContent(from: $0) }
            allContents.append(contentsOf: contents)
        }
        
        // Maintain original order from bookmarks
        let contentDict = Dictionary(uniqueKeysWithValues: allContents.map { ($0.id, $0) })
        return contentIds.compactMap { contentDict[$0] }
    }
    
    public func isBookmarked(contentId: String, userId: String) async throws -> Bool {
        let bookmarkRef = db.collection(Constants.bookmarksCollection)
            .document(userId)
            .collection("items")
            .document(contentId)
        
        let snapshot = try await bookmarkRef.getDocument()
        return snapshot.exists
    }
    
    // MARK: - Likes
    
    public func toggleLike(contentId: String, userId: String) async throws -> Bool {
        let likeRef = db.collection(Constants.collection)
            .document(contentId)
            .collection("likes")
            .document(userId)
        
        let snapshot = try await likeRef.getDocument()
        
        if snapshot.exists {
            try await likeRef.delete()
            try await db.collection(Constants.collection)
                .document(contentId)
                .updateData(["likeCount": FieldValue.increment(-1.0)])
            return false
        } else {
            try await likeRef.setData([
                "userId": userId,
                "likedAt": FieldValue.serverTimestamp()
            ])
            try await db.collection(Constants.collection)
                .document(contentId)
                .updateData(["likeCount": FieldValue.increment(1.0)])
            return true
        }
    }
    
    // MARK: - Parsing
    
    private func parseContent(from document: DocumentSnapshot) throws -> IslamicEducationalContent {
        guard let data = document.data() else {
            throw RepositoryError.invalidData
        }
        
        let decoder = FirestoreDecoder()
        var content = try decoder.decode(IslamicEducationalContent.self, from: data)
        
        // Override ID with document ID
        content = IslamicEducationalContent(
            id: document.documentID,
            title: content.title,
            description: content.description,
            category: content.category,
            contentType: content.contentType,
            content: content.content,
            difficultyLevel: content.difficultyLevel,
            estimatedReadTime: content.estimatedReadTime,
            createdAt: content.createdAt,
            updatedAt: content.updatedAt,
            author: content.author,
            tags: content.tags,
            isFeatured: content.isFeatured,
            viewCount: content.viewCount,
            likeCount: content.likeCount,
            bookmarkCount: content.bookmarkCount,
            quiz: content.quiz,
            relatedContent: content.relatedContent
        )
        
        return content
    }
}

// MARK: - User Content Progress

public struct UserContentProgress: Equatable {
    public let contentId: String
    public let viewedAt: Date?
    public let completed: Bool
    public let completedAt: Date?
    public let quizScore: Int?
    
    public init(contentId: String, viewedAt: Date?, completed: Bool, completedAt: Date?, quizScore: Int?) {
        self.contentId = contentId
        self.viewedAt = viewedAt
        self.completed = completed
        self.completedAt = completedAt
        self.quizScore = quizScore
    }
}

// MARK: - Firestore Decoder Helper

private class FirestoreDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: [String: Any]) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let timestamp = try? container.decode(Timestamp.self) {
                return timestamp.dateValue()
            }
            if let string = try? container.decode(String.self) {
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: string) {
                    return date
                }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }
        return try decoder.decode(T.self, from: jsonData)
    }
}
#endif
