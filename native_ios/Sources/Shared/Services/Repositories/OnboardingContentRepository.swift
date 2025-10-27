import Foundation

@available(iOS 17.0.0, *)
public protocol OnboardingContentRepository {
    func fetchContent() async throws -> OnboardingContent
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore

@available(iOS 17.0.0, *)
public final class FirestoreOnboardingContentRepository: OnboardingContentRepository {
    private enum Constants {
        static let collection = "app_content"
        static let document = "onboarding"
    }

    private let db: Firestore
    private let logger = Logger.shared

    public init(db: Firestore = .firestore()) {
        self.db = db
    }

    public func fetchContent() async throws -> OnboardingContent {
        do {
            let snapshot = try await db.collection(Constants.collection)
                .document(Constants.document)
                .getDocument()

            guard snapshot.exists, let data = snapshot.data(),
                  let content = OnboardingContent(data: normalize(data)) else {
                throw RepositoryError.notFound
            }

            return content
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> Error {
        if let firestoreError = error as NSError?,
           let code = FirestoreErrorCode.Code(rawValue: firestoreError.code) {
            switch code {
            case .notFound:
                return RepositoryError.notFound
            case .permissionDenied:
                return RepositoryError.permissionDenied
            case .unavailable, .deadlineExceeded:
                return RepositoryError.networkFailure
            default:
                break
            }
        }

        logger.error("Firestore onboarding content error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }
}

private func normalize(_ data: [String: Any]) -> [String: Any] {
    var normalized = data
    if let url = data["hero_image_url"] as? String, normalized["heroImageURL"] == nil {
        normalized["heroImageURL"] = url
    }
    if let cta = data["call_to_action_title"] as? String,
       normalized["callToActionTitle"] == nil {
        normalized["callToActionTitle"] = cta
    }
    return normalized
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreOnboardingContentRepository: OnboardingContentRepository {
    public init() {}
    public func fetchContent() async throws -> OnboardingContent {
        throw RepositoryError.unknown
    }
}
#endif
