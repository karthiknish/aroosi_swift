import Foundation

@available(iOS 17.0.0, *)
public protocol IcebreakerRepository {
    func fetchDailyIcebreakers(for userID: String) async throws -> [IcebreakerItem]
    func submitAnswer(_ answer: String, to questionID: String, userID: String) async throws
    func fetchAnswers(for userID: String) async throws -> [IcebreakerAnswer]
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@available(iOS 17.0.0, *)
public final class FirestoreIcebreakerRepository: IcebreakerRepository {
    private enum Constants {
        static let questionsCollection = "icebreaker_questions"
        static let answersCollection = "icebreaker_answers"
    }

    private let db: Firestore

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchDailyIcebreakers(for userID: String) async throws -> [IcebreakerItem] {
        async let questionsTask = db.collection(Constants.questionsCollection)
            .whereField("active", isEqualTo: true)
            .getDocuments()

        async let answersTask = db.collection(Constants.answersCollection)
            .whereField("userId", isEqualTo: userID)
            .getDocuments()

        let (questionsSnapshot, answersSnapshot) = try await (questionsTask, answersTask)

        let answers = answersSnapshot.documents.reduce(into: [String: IcebreakerAnswer]()) { partial, doc in
            if let answer = IcebreakerAnswer(document: doc) {
                partial[answer.questionId] = answer
            }
        }

        let items: [IcebreakerItem] = questionsSnapshot.documents.compactMap { doc in
            guard let question = IcebreakerQuestion(document: doc) else { return nil }
            let existingAnswer = answers[question.id]
            return IcebreakerItem(id: question.id,
                                  text: question.text,
                                  currentAnswer: existingAnswer?.answer ?? "",
                                  isAnswered: existingAnswer != nil)
        }

        return items.sorted { lhs, rhs in lhs.text < rhs.text }
    }

    public func submitAnswer(_ answer: String, to questionID: String, userID: String) async throws {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.invalidData }

        let answersCollection = db.collection(Constants.answersCollection)
        let query = answersCollection
            .whereField("userId", isEqualTo: userID)
            .whereField("questionId", isEqualTo: questionID)

        let snapshot = try await query.limit(to: 1).getDocuments()

        if let document = snapshot.documents.first {
            try await answersCollection.document(document.documentID).setData([
                "answer": trimmed,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        } else {
            try await answersCollection.addDocument(data: [
                "userId": userID,
                "questionId": questionID,
                "answer": trimmed,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }

    public func fetchAnswers(for userID: String) async throws -> [IcebreakerAnswer] {
        let snapshot = try await db.collection(Constants.answersCollection)
            .whereField("userId", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap(IcebreakerAnswer.init(document:))
    }
}

@available(iOS 17.0.0, *)
private extension IcebreakerQuestion {
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let text = data["text"] as? String else { return nil }
        let category = data["category"] as? String
        let weight = data["weight"] as? Int ?? 1
        let active = data["active"] as? Bool ?? true

        self.init(id: document.documentID,
                  text: text,
                  category: category,
                  weight: weight,
                  active: active)
    }
}

@available(iOS 17.0.0, *)
private extension IcebreakerAnswer {
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let questionId = data["questionId"] as? String,
              let userId = data["userId"] as? String,
              let answer = data["answer"] as? String else { return nil }

        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }

        let updatedAt: Date?
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = nil
        }

        self.init(id: document.documentID,
                  questionId: questionId,
                  userId: userId,
                  answer: answer,
                  createdAt: createdAt,
                  updatedAt: updatedAt)
    }
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreIcebreakerRepository: IcebreakerRepository {
    public init() {}

    public func fetchDailyIcebreakers(for userID: String) async throws -> [IcebreakerItem] { [] }
    public func submitAnswer(_ answer: String, to questionID: String, userID: String) async throws {}
    public func fetchAnswers(for userID: String) async throws -> [IcebreakerAnswer] { [] }
}
#endif
