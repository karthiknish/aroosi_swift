import XCTest
import FirebaseCore
@testable import AroosiKit

@available(iOS 17.0, *)
final class FirebaseConfigurationTests: XCTestCase {
    
    func testFirebaseConfigurationFromEnvironment() throws {
        // Test that Firebase can be configured using environment variables
        // This simulates what happens when the app starts
        
        // Clear any existing Firebase app
        if let existingApp = FirebaseApp.app() {
            existingApp.delete { _ in
                // Firebase app deleted
            }
        }
        
        // Configure Firebase using the configurator
        FirebaseConfigurator.configureIfNeeded()
        
        // Verify Firebase app is configured
        let firebaseApp = FirebaseApp.app()
        XCTAssertNotNil(firebaseApp, "Firebase should be configured with environment variables")
        
        // Verify the configuration values match our environment
        if let options = firebaseApp?.options {
            XCTAssertEqual(options.apiKey, "AIzaSyDBO0qloVCqP7su4WnBL72yUkH7KooGyzY")
            XCTAssertEqual(options.projectID, "aroosi-ios")
            XCTAssertEqual(options.googleAppID, "1:320943801797:ios:9698384f0913adeaf6b7ac")
            XCTAssertEqual(options.gcmSenderID, "320943801797")
            XCTAssertEqual(options.clientID, "762041256503-uc9qopr13761ictkgj53ba4gomtkvbha.apps.googleusercontent.com")
            XCTAssertEqual(options.bundleID, "com.aroosi.mobile")
            XCTAssertEqual(options.storageBucket, "aroosi-ios.firebasestorage.app")
        } else {
            XCTFail("Firebase options should be available")
        }
    }
    
    func testEnvironmentVariablesLoaded() throws {
        // Test that environment variables are properly loaded
        let config = FlutterEnvironmentConfig.shared
        
        XCTAssertEqual(config.environment, "production")
        XCTAssertEqual(config.apiBaseUrl, "https://www.aroosi.app/api")
        XCTAssertEqual(config.firebaseProjectID, "aroosi-ios")
        XCTAssertEqual(config.firebaseStorageBucket, "aroosi-ios.firebasestorage.app")
        XCTAssertEqual(config.googleClientID, "762041256503-uc9qopr13761ictkgj53ba4gomtkvbha.apps.googleusercontent.com")
    }
    
    func testChatServicesConfiguration() throws {
        // Test that chat services can be initialized with the Firebase configuration
        let messageRepository = FirestoreChatMessageRepository()
        let conversationService = FirestoreConversationService()
        let deliveryService = FirestoreChatDeliveryService()
        
        XCTAssertNotNil(messageRepository)
        XCTAssertNotNil(conversationService)
        XCTAssertNotNil(deliveryService)
    }
}
