#if canImport(FirebaseFirestore)
import XCTest
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
@testable import AroosiKit

// Integration tests talk to the local Firebase emulator suite. Launch the emulators before running.
@available(iOS 17, macOS 13, *)
class FirebaseIntegrationTestCase: XCTestCase {
    private static var isConfigured = false

    static let projectID = ProcessInfo.processInfo.environment["FIREBASE_PROJECT_ID"] ?? "aroosi-integration-tests"

    private static let firestoreConfig = hostAndPort(from: ProcessInfo.processInfo.environment["FIRESTORE_EMULATOR_HOST"], defaultPort: 8080)
    private static let authConfig = hostAndPort(from: ProcessInfo.processInfo.environment["FIREBASE_AUTH_EMULATOR_HOST"], defaultPort: 9099)
    private static let storageConfig = hostAndPort(from: ProcessInfo.processInfo.environment["FIREBASE_STORAGE_EMULATOR_HOST"], defaultPort: 9199)

    static var firestore: Firestore {
        Firestore.firestore()
    }

    static var auth: Auth {
        Auth.auth()
    }

    static var storage: Storage {
        Storage.storage()
    }

    override class func setUp() {
        super.setUp()
        guard !isConfigured else { return }

        let options = FirebaseOptions(googleAppID: "1:111111111111:ios:1111111111111111", gcmSenderID: "111111111111")
        options.projectID = projectID
        options.apiKey = "fake-api-key"
        options.storageBucket = "\(projectID).appspot.com"

        FirebaseApp.configure(options: options)

        let firestore = Firestore.firestore()
        firestore.useEmulator(withHost: firestoreConfig.host, port: firestoreConfig.port)
    let settings = FirestoreSettings()
    settings.host = "\(firestoreConfig.host):\(firestoreConfig.port)"
    settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        firestore.settings = settings

        Auth.auth().useEmulator(withHost: authConfig.host, port: authConfig.port)
        Storage.storage().useEmulator(withHost: storageConfig.host, port: storageConfig.port)

        isConfigured = true
    }

    override func setUp() async throws {
        try await super.setUp()
        do {
            try await Self.resetFirestore()
            try await Self.resetAuth()
        } catch IntegrationTestError.firestoreResetFailed {
            throw XCTSkip("Firestore emulator is not available at \(Self.firestoreConfig.host):\(Self.firestoreConfig.port). Start the emulator suite or set FIRESTORE_EMULATOR_HOST.")
        } catch IntegrationTestError.authResetFailed {
            throw XCTSkip("Firebase Auth emulator is not available at \(Self.authConfig.host):\(Self.authConfig.port). Start the emulator suite or set FIREBASE_AUTH_EMULATOR_HOST.")
        }
        Self.ensureSignedOut()
    }

    override func tearDown() async throws {
        Self.ensureSignedOut()
        try await super.tearDown()
    }

    private static func resetFirestore() async throws {
        let url = URL(string: "http://\(firestoreConfig.host):\(firestoreConfig.port)/emulator/v1/projects/\(projectID)/databases/(default)/documents")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw IntegrationTestError.firestoreResetFailed
            }
        } catch {
            throw IntegrationTestError.firestoreResetFailed
        }
    }

    private static func resetAuth() async throws {
        let url = URL(string: "http://\(authConfig.host):\(authConfig.port)/emulator/v1/projects/\(projectID)/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw IntegrationTestError.authResetFailed
            }
        } catch {
            throw IntegrationTestError.authResetFailed
        }
    }

    private static func ensureSignedOut() {
        do {
            if auth.currentUser != nil {
                try auth.signOut()
            }
        } catch {
            // Ignore sign-out failures so tests can proceed.
        }
    }

    private static func hostAndPort(from value: String?, defaultPort: Int) -> (host: String, port: Int) {
        guard let value, !value.isEmpty else {
            return ("localhost", defaultPort)
        }

        let parts = value.split(separator: ":")
        if parts.count == 2, let port = Int(parts[1]) {
            return (String(parts[0]), port)
        }

        return (value, defaultPort)
    }

    enum IntegrationTestError: Error, LocalizedError {
        case firestoreResetFailed
        case authResetFailed

        var errorDescription: String? {
            switch self {
            case .firestoreResetFailed:
                return "Failed to reset the Firestore emulator. Ensure the emulator is running on the expected host/port."
            case .authResetFailed:
                return "Failed to reset the Firebase Auth emulator. Ensure the emulator is running on the expected host/port."
            }
        }
    }
}

@available(iOS 17, macOS 13, *)
final class FirestoreProfileRepositoryIntegrationTests: FirebaseIntegrationTestCase {
    func testFetchProfileReturnsSummary() async throws {
        try await Self.firestore.collection("profiles").document("integration-user").setData([
            "displayName": "Integration Tester",
            "age": 30,
            "location": "Test City",
            "interests": ["hiking", "cooking"],
            "bio": "Testing profile fetch"
        ])

        let repository = FirestoreProfileRepository()
        let summary = try await repository.fetchProfile(id: "integration-user")

        XCTAssertEqual(summary.id, "integration-user")
        XCTAssertEqual(summary.displayName, "Integration Tester")
        XCTAssertEqual(summary.interests, ["hiking", "cooking"])
        XCTAssertEqual(summary.location, "Test City")
    }

    func testUpdateProfilePersistsChanges() async throws {
        try await Self.firestore.collection("profiles").document("profile-update").setData([
            "displayName": "Original",
            "interests": []
        ])

        let repository = FirestoreProfileRepository()
        let updatedProfile = ProfileSummary(
            id: "profile-update",
            displayName: "Updated",
            interests: ["travel"]
        )

        try await repository.updateProfile(updatedProfile)

        let snapshot = try await Self.firestore.collection("profiles").document("profile-update").getDocument()
        let data = snapshot.data()

        XCTAssertEqual(data?["displayName"] as? String, "Updated")
        XCTAssertEqual(data?["interests"] as? [String], ["travel"])
    }

    func testToggleShortlistAddsAndRemovesEntries() async throws {
        let authResult = try await Self.auth.signInAnonymously()
        let currentUserID = authResult.user.uid

        try await Self.firestore.collection("profiles").document(currentUserID).setData([
            "displayName": "Current User",
            "interests": []
        ])

        try await Self.firestore.collection("profiles").document("shortlist-target").setData([
            "displayName": "Target User",
            "interests": []
        ])

        let repository = FirestoreProfileRepository()

        let added = try await repository.toggleShortlist(userID: "shortlist-target")
        XCTAssertEqual(added.action, .added)

        var shortlistDoc = try await Self.firestore
            .collection("profiles")
            .document(currentUserID)
            .collection("shortlist")
            .document("shortlist-target")
            .getDocument()
        XCTAssertTrue(shortlistDoc.exists)

        let removed = try await repository.toggleShortlist(userID: "shortlist-target")
        XCTAssertEqual(removed.action, .removed)

        shortlistDoc = try await Self.firestore
            .collection("profiles")
            .document(currentUserID)
            .collection("shortlist")
            .document("shortlist-target")
            .getDocument()
        XCTAssertFalse(shortlistDoc.exists)
    }

    func testSetShortlistNoteWritesAndClearsNote() async throws {
        let authResult = try await Self.auth.signInAnonymously()
        let currentUserID = authResult.user.uid

        try await Self.firestore.collection("profiles").document(currentUserID).setData([
            "displayName": "Current User",
            "interests": []
        ])

        try await Self.firestore.collection("profiles").document("noted-user").setData([
            "displayName": "Noted User",
            "interests": []
        ])

        let repository = FirestoreProfileRepository()

        try await repository.setShortlistNote(userID: "noted-user", note: "Follow up next week")
        var shortlistDoc = try await Self.firestore
            .collection("profiles")
            .document(currentUserID)
            .collection("shortlist")
            .document("noted-user")
            .getDocument()
        if let data = shortlistDoc.data() {
            let storedNote = data["note"] as? String
            XCTAssertEqual(storedNote, "Follow up next week")
        } else {
            XCTFail("Expected shortlist document data to exist")
        }

        try await repository.setShortlistNote(userID: "noted-user", note: "")
        shortlistDoc = try await Self.firestore
            .collection("profiles")
            .document(currentUserID)
            .collection("shortlist")
            .document("noted-user")
            .getDocument()
        if let data = shortlistDoc.data() {
            XCTAssertNil(data["note"])
        } else {
            XCTFail("Expected shortlist document data to exist")
        }
    }

    func testFetchProfileDetailReflectsFavoriteAndShortlistState() async throws {
        let authResult = try await Self.auth.signInAnonymously()
        let currentUserID = authResult.user.uid

        try await Self.firestore.collection("profiles").document(currentUserID).setData([
            "displayName": "Current User",
            "interests": []
        ])

        try await Self.firestore.collection("profiles").document("detail-target").setData([
            "displayName": "Detail Target",
            "interests": ["board games"],
            "bio": "Detail testing"
        ])

        try await Self.firestore
            .collection("profiles")
            .document(currentUserID)
            .collection("favorites")
            .document("detail-target")
            .setData(["addedAt": FieldValue.serverTimestamp()])

        try await Self.firestore
            .collection("profiles")
            .document(currentUserID)
            .collection("shortlist")
            .document("detail-target")
            .setData(["addedAt": FieldValue.serverTimestamp()])

        let repository = FirestoreProfileRepository()
        let detail = try await repository.fetchProfileDetail(id: "detail-target")

        XCTAssertTrue(detail.isFavorite)
        XCTAssertTrue(detail.isShortlisted)
        XCTAssertEqual(detail.summary.displayName, "Detail Target")
    }
}
#endif
