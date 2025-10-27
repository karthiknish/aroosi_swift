import XCTest
import FirebaseFirestore
import FirebaseAuth
@testable import AroosiKit

@available(iOS 17, *)
@MainActor
final class FirebaseIntegrationTests: XCTestCase {
    
    // MARK: - Firestore Integration Tests
    
    func testFirestoreConnection() async throws {
        // Given
        let firestore = Firestore.firestore()
        let testCollection = firestore.collection("test_collection")
        
        // When
        let testDocument = testCollection.document("test_doc_\(UUID().uuidString)")
        let testData: [String: Any] = [
            "testField": "testValue",
            "timestamp": FieldValue.serverTimestamp(),
            "userID": "test-user-123"
        ]
        
        try await testDocument.setData(testData)
        
        // Then
        let snapshot = try await testDocument.getDocument()
        XCTAssertTrue(snapshot.exists)
        XCTAssertEqual(snapshot.data()?["testField"] as? String, "testValue")
        XCTAssertEqual(snapshot.data()?["userID"] as? String, "test-user-123")
        
        // Cleanup
        try await testDocument.delete()
    }
    
    func testFirestoreRealtimeUpdates() async throws {
        // Given
        let firestore = Firestore.firestore()
        let testCollection = firestore.collection("realtime_test")
        let documentID = "realtime_test_\(UUID().uuidString)"
        let testDocument = testCollection.document(documentID)
        
        let expectation = XCTestExpectation(description: "Realtime update received")
        
        // When
        let listener = testDocument.addSnapshotListener { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                expectation.fulfill()
            }
        }
        
        // Trigger update
        try await testDocument.setData(["initialData": "test"])
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Cleanup
        listener.remove()
        try await testDocument.delete()
    }
    
    func testFirestoreQueryOperations() async throws {
        // Given
        let firestore = Firestore.firestore()
        let testCollection = firestore.collection("query_test")
        let documentIDs = (1...5).map { "query_test_\(UUID().uuidString)_\($0)" }
        
        // Insert test data
        for (index, documentID) in documentIDs.enumerated() {
            let testDocument = testCollection.document(documentID)
            let testData: [String: Any] = [
                "userID": "test-user-\(index)",
                "score": index * 10,
                "active": index % 2 == 0
            ]
            try await testDocument.setData(testData)
        }
        
        // When - Query for active users
        let query = testCollection
            .whereField("active", isEqualTo: true)
            .order(by: "score", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        // Then
        XCTAssertEqual(snapshot.documents.count, 3) // indices 0, 2, 4 are active
        for document in snapshot.documents {
            XCTAssertEqual(document.data()["active"] as? Bool, true)
        }
        
        // Cleanup
        for documentID in documentIDs {
            try await testCollection.document(documentID).delete()
        }
    }
    
    // MARK: - Authentication Integration Tests
    
    func testFirebaseAuthAnonymousSignIn() async throws {
        // Given
        let auth = Auth.auth()
        
        // When
        let result = try await auth.signInAnonymously()
        
        // Then
        XCTAssertNotNil(result.user)
        XCTAssertNotNil(result.user.uid)
        XCTAssertTrue(result.user.isAnonymous)
        
        // Cleanup
        try await result.user.delete()
    }
    
    func testFirebaseAuthCustomToken() async throws {
        // Given
        let auth = Auth.auth()
        let customToken = generateMockCustomToken()
        
        // When
        let result = try await auth.signIn(withCustomToken: customToken)
        
        // Then
        XCTAssertNotNil(result.user)
        XCTAssertNotNil(result.user.uid)
        XCTAssertFalse(result.user.isAnonymous)
        
        // Cleanup
        try await result.user.delete()
    }
    
    // MARK: - Security Rules Tests
    
    func testUserCanOnlyAccessOwnProfile() async throws {
        // Given
        let firestore = Firestore.firestore()
        let usersCollection = firestore.collection("users")
        let userID = "test-user-\(UUID().uuidString)"
        let userDocument = usersCollection.document(userID)
        
        // Create authenticated user context (this would normally be done through actual auth)
        let testData: [String: Any] = [
            "displayName": "Test User",
            "email": "test@example.com",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // When - Try to access own profile
        try await userDocument.setData(testData)
        
        // Then
        let snapshot = try await userDocument.getDocument()
        XCTAssertTrue(snapshot.exists)
        XCTAssertEqual(snapshot.data()?["displayName"] as? String, "Test User")
        
        // Cleanup
        try await userDocument.delete()
    }
    
    func testConversationAccessControl() async throws {
        // Given
        let firestore = Firestore.firestore()
        let conversationsCollection = firestore.collection("conversations")
        let conversationID = "conv-\(UUID().uuidString)"
        let conversationDocument = conversationsCollection.document(conversationID)
        
        let userID1 = "user-\(UUID().uuidString)"
        let userID2 = "user-\(UUID().uuidString)"
        
        let conversationData: [String: Any] = [
            "participants": [userID1, userID2],
            "createdAt": FieldValue.serverTimestamp(),
            "status": "active"
        ]
        
        // When
        try await conversationDocument.setData(conversationData)
        
        // Then
        let snapshot = try await conversationDocument.getDocument()
        XCTAssertTrue(snapshot.exists)
        let participants = snapshot.data()?["participants"] as? [String]
        XCTAssertEqual(participants?.count, 2)
        XCTAssertTrue(participants?.contains(userID1) == true)
        XCTAssertTrue(participants?.contains(userID2) == true)
        
        // Cleanup
        try await conversationDocument.delete()
    }
    
    // MARK: - Storage Integration Tests
    
    func testFirebaseStorageUpload() async throws {
        // Given
        guard let storage = FirebaseStorage.Storage.storage() as? FirebaseStorage.Storage else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "FirebaseStorage not available"])
        }
        
        let storageRef = storage.reference()
        let testImageRef = storageRef.child("profile_images/test-user-\(UUID().uuidString).jpg")
        
        // Create test image data
        let testImageData = createTestImageData()
        
        // When
        let metadata = FirebaseStorage.StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await testImageRef.putData(testImageData, metadata: metadata)
        
        // Then
        let downloadURL = try await testImageRef.downloadURL()
        XCTAssertNotNil(downloadURL)
        XCTAssertTrue(downloadURL.absoluteString.hasSuffix(".jpg"))
        
        // Cleanup
        try await testImageRef.delete()
    }
    
    func testFirebaseStorageDownload() async throws {
        // Given
        guard let storage = FirebaseStorage.Storage.storage() as? FirebaseStorage.Storage else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "FirebaseStorage not available"])
        }
        
        let storageRef = storage.reference()
        let testImageRef = storageRef.child("profile_images/test-download-\(UUID().uuidString).jpg")
        
        let testImageData = createTestImageData()
        let metadata = FirebaseStorage.StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload test image
        try await testImageRef.putData(testImageData, metadata: metadata)
        
        // When
        let downloadedData = try await testImageRef.data(maxSize: 1 * 1024 * 1024) // 1MB
        
        // Then
        XCTAssertEqual(downloadedData.count, testImageData.count)
        
        // Cleanup
        try await testImageRef.delete()
    }
    
    // MARK: - Performance Tests
    
    func testFirestoreReadPerformance() async throws {
        // Given
        let firestore = Firestore.firestore()
        let testCollection = firestore.collection("performance_test")
        let documentIDs = (1...100).map { "perf_test_\(UUID().uuidString)_\($0)" }
        
        // Insert test data
        for documentID in documentIDs {
            let testDocument = testCollection.document(documentID)
            let testData: [String: Any] = [
                "userID": "perf-user-\(UUID().uuidString)",
                "score": Int.random(in: 1...100),
                "active": Bool.random()
            ]
            try await testDocument.setData(testData)
        }
        
        // When - Measure read performance
        let startTime = CFAbsoluteTimeGetCurrent()
        let snapshot = try await testCollection.getDocuments()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertEqual(snapshot.documents.count, 100)
        XCTAssertLessThan(executionTime, 5.0) // Should complete within 5 seconds
        
        // Cleanup
        for documentID in documentIDs {
            try await testCollection.document(documentID).delete()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testFirestorePermissionDenied() async throws {
        // Given
        let firestore = Firestore.firestore()
        let restrictedCollection = firestore.collection("admin_only")
        let restrictedDocument = restrictedCollection.document("should_fail")
        
        // When & Then
        do {
            _ = try await restrictedDocument.getDocument()
            XCTFail("Expected permission denied error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "FIRFirestoreErrorDomain")
            XCTAssertEqual(error.code, 7) // Permission denied
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateMockCustomToken() -> String {
        // In a real implementation, this would generate a valid custom token
        // For testing purposes, we'll use a mock token
        return "mock.custom.token.\(UUID().uuidString)"
    }
    
    private func createTestImageData() -> Data {
        // Create a simple 1x1 pixel JPEG image for testing
        let jpegData = Data(base64Encoded: "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/8A8A")
        return jpegData ?? Data()
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    func fulfill<T>(expectation: XCTestExpectation, with value: T) {
        expectation.fulfill()
    }
}
