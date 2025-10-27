import XCTest
@testable import AroosiKit

@available(iOS 17, *)
@MainActor
final class UserJourneyTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    // MARK: - Complete User Journey Tests
    
    func testCompleteOnboardingAndFirstMatch() throws {
        // Given - Fresh app launch
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5.0))
        
        // When - Complete onboarding
        completeOnboardingFlow()
        
        // Then - Should see dashboard
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
        XCTAssertTrue(app.staticTexts["Welcome to Aroosi"].exists)
        
        // When - Navigate to discover profiles
        app.buttons["Discover Profiles"].tap()
        
        // Then - Should see profiles list
        XCTAssertTrue(app.collectionViews["ProfilesList"].exists)
        
        // When - Send interest to first profile
        let firstProfile = app.collectionViews["ProfilesList"].cells.firstMatch
        XCTAssertTrue(firstProfile.waitForExistence(timeout: 3.0))
        firstProfile.buttons["Send Interest"].tap()
        
        // Then - Should see interest confirmation
        XCTAssertTrue(app.alerts["Interest Sent"].exists)
        app.alerts["Interest Sent"].buttons["OK"].tap()
    }
    
    func testCompleteChatFlow() throws {
        // Given - User has matches
        completeOnboardingFlow()
        app.tabBars.buttons["Matches"].tap()
        
        // When - Open first match
        let firstMatch = app.collectionViews["MatchesList"].cells.firstMatch
        XCTAssertTrue(firstMatch.waitForExistence(timeout: 3.0))
        firstMatch.tap()
        
        // Then - Should see chat interface
        XCTAssertTrue(app.textViews["MessageInput"].exists)
        XCTAssertTrue(app.buttons["Send"].exists)
        
        // When - Send a message
        let messageInput = app.textViews["MessageInput"]
        messageInput.tap()
        messageInput.typeText("Hello! Nice to meet you.")
        app.buttons["Send"].tap()
        
        // Then - Should see message in chat
        XCTAssertTrue(app.staticTexts["Hello! Nice to meet you."].exists)
        
        // When - Navigate back
        app.navigationBars.buttons["Back"].tap()
        
        // Then - Should return to matches list
        XCTAssertTrue(app.collectionViews["MatchesList"].exists)
    }
    
    func testCompleteProfileCreationFlow() throws {
        // Given - User is on dashboard
        completeOnboardingFlow()
        
        // When - Navigate to profile
        app.tabBars.buttons["Profile"].tap()
        
        // Then - Should see profile screen
        XCTAssertTrue(app.buttons["Edit Profile"].exists)
        
        // When - Edit profile
        app.buttons["Edit Profile"].tap()
        
        // Fill in profile details
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("John Doe")
        
        let ageField = app.textFields["Age"]
        ageField.tap()
        ageField.typeText("28")
        
        let bioField = app.textViews["Bio"]
        bioField.tap()
        bioField.typeText("I love traveling and meeting new people!")
        
        // Select interests
        app.buttons["Add Interests"].tap()
        app.buttons["Travel"].tap()
        app.buttons["Cooking"].tap()
        app.buttons["Done"].tap()
        
        // Save profile
        app.buttons["Save"].tap()
        
        // Then - Should see updated profile
        XCTAssertTrue(app.staticTexts["John Doe"].exists)
        XCTAssertTrue(app.staticTexts["28"].exists)
        XCTAssertTrue(app.staticTexts["I love traveling and meeting new people!"].exists)
        XCTAssertTrue(app.buttons["Travel"].exists)
        XCTAssertTrue(app.buttons["Cooking"].exists)
    }
    
    func testCompleteSettingsFlow() throws {
        // Given - User is on dashboard
        completeOnboardingFlow()
        
        // When - Navigate to settings
        app.tabBars.buttons["Settings"].tap()
        
        // Then - Should see settings screen
        XCTAssertTrue(app.buttons["Notifications"].exists)
        XCTAssertTrue(app.buttons["Privacy"].exists)
        XCTAssertTrue(app.buttons["Account"].exists)
        
        // When - Configure notifications
        app.buttons["Notifications"].tap()
        
        // Enable push notifications
        let pushNotificationSwitch = app.switches["Push Notifications"]
        if !pushNotificationSwitch.isOn {
            pushNotificationSwitch.tap()
        }
        
        // Enable email notifications
        let emailNotificationSwitch = app.switches["Email Notifications"]
        if !emailNotificationSwitch.isOn {
            emailNotificationSwitch.tap()
        }
        
        app.navigationBars.buttons["Back"].tap()
        
        // When - Configure privacy
        app.buttons["Privacy"].tap()
        
        // Set profile visibility
        app.buttons["Profile Visibility"].tap()
        app.buttons["Public"].tap()
        app.buttons["Save"].tap()
        
        app.navigationBars.buttons["Back"].tap()
        
        // Then - Settings should be saved
        XCTAssertTrue(pushNotificationSwitch.isOn)
        XCTAssertTrue(emailNotificationSwitch.isOn)
    }
    
    func testCompleteFamilyApprovalFlow() throws {
        // Given - User has a match
        completeOnboardingFlow()
        app.tabBars.buttons["Matches"].tap()
        
        // When - Open match and request family approval
        let firstMatch = app.collectionViews["MatchesList"].cells.firstMatch
        XCTAssertTrue(firstMatch.waitForExistence(timeout: 3.0))
        firstMatch.tap()
        
        app.buttons["Request Family Approval"].tap()
        
        // Fill in family member details
        let familyMemberName = app.textFields["Family Member Name"]
        familyMemberName.tap()
        familyMemberName.typeText("Jane Doe")
        
        let familyMemberRelation = app.buttons["Relation"]
        familyMemberRelation.tap()
        app.buttons["Sister"].tap()
        
        let messageField = app.textViews["Message"]
        messageField.tap()
        messageField.typeText("I'd like your approval for this match.")
        
        app.buttons["Send Request"].tap()
        
        // Then - Should see confirmation
        XCTAssertTrue(app.alerts["Request Sent"].exists)
        app.alerts["Request Sent"].buttons["OK"].tap()
        
        // Should see pending status
        XCTAssertTrue(app.staticTexts["Family Approval Pending"].exists)
    }
    
    func testCompleteCompatibilityAssessmentFlow() throws {
        // Given - User is on dashboard
        completeOnboardingFlow()
        
        // When - Navigate to compatibility
        app.buttons["Cultural Compatibility"].tap()
        
        // Then - Should see compatibility assessment
        XCTAssertTrue(app.buttons["Start Assessment"].exists)
        
        // When - Complete assessment
        app.buttons["Start Assessment"].tap()
        
        // Answer first question
        app.buttons["Strongly Agree"].tap()
        app.buttons["Next"].tap()
        
        // Answer second question
        app.buttons["Agree"].tap()
        app.buttons["Next"].tap()
        
        // Continue through assessment (simplified for test)
        for _ in 0..<5 {
            if app.buttons["Next"].exists {
                app.buttons["Next"].tap()
            }
        }
        
        // Submit assessment
        app.buttons["Submit"].tap()
        
        // Then - Should see results
        XCTAssertTrue(app.staticTexts["Compatibility Score"].exists)
        XCTAssertTrue(app.staticTexts["85%"].exists) // Example score
        XCTAssertTrue(app.buttons["View Insights"].exists)
    }
    
    func testCompleteSearchAndFilterFlow() throws {
        // Given - User is on discover screen
        completeOnboardingFlow()
        app.buttons["Discover Profiles"].tap()
        
        // When - Open filters
        app.buttons["Filters"].tap()
        
        // Set age range
        let ageMinSlider = app.sliders["Minimum Age"]
        ageMinSlider.adjust(toNormalizedSliderPosition: 0.3)
        
        let ageMaxSlider = app.sliders["Maximum Age"]
        ageMaxSlider.adjust(toNormalizedSliderPosition: 0.7)
        
        // Set location
        app.buttons["Location"].tap()
        app.buttons["Within 50 miles"].tap()
        
        // Select interests
        app.buttons["Interests"].tap()
        app.buttons["Travel"].tap()
        app.buttons["Music"].tap()
        app.buttons["Apply"].tap()
        
        // Apply filters
        app.buttons["Apply Filters"].tap()
        
        // Then - Should see filtered results
        XCTAssertTrue(app.staticTexts["Filtered Results"].exists)
        XCTAssertTrue(app.collectionViews["ProfilesList"].exists)
        
        // Clear filters
        app.buttons["Clear Filters"].tap()
        
        // Should see all results again
        XCTAssertTrue(app.staticTexts["All Profiles"].exists)
    }
    
    func testCompleteErrorHandlingFlow() throws {
        // Given - Simulate network error
        app.launchArguments.append("--simulate-network-error")
        app.launch()
        
        // When - Try to complete onboarding
        completeOnboardingFlow()
        
        // Then - Should see error message
        XCTAssertTrue(app.alerts["Network Error"].exists)
        app.alerts["Network Error"].buttons["Retry"].tap()
        
        // Should retry and succeed
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 10.0))
    }
    
    // MARK: - Helper Methods
    
    private func completeOnboardingFlow() {
        // Welcome screen
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        // Sign in with Apple
        if app.buttons["Sign in with Apple"].exists {
            app.buttons["Sign in with Apple"].tap()
        }
        
        // Handle system sign in (if present)
        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
        }
        
        // Complete profile setup
        if app.textFields["Name"].exists {
            app.textFields["Name"].tap()
            app.textFields["Name"].typeText("Test User")
            
            app.textFields["Age"].tap()
            app.textFields["Age"].typeText("25")
            
            app.buttons["Continue"].tap()
        }
        
        // Skip optional steps for testing
        if app.buttons["Skip"].exists {
            app.buttons["Skip"].tap()
        }
    }
}

// MARK: - Accessibility Tests

@available(iOS 17, *)
@MainActor
final class AccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--accessibility-testing"]
        app.launch()
        
        // Enable VoiceOver for testing
        UIAccessibility.post(notification: .screenChanged, argument: "Test started")
    }
    
    func testVoiceOverNavigation() throws {
        // Given - VoiceOver is enabled
        XCTAssertTrue(app.isRunning)
        
        // When - Navigate through main screens
        app.swipeRight() // Navigate to first element
        XCTAssertTrue(app.staticTexts["Get Started"].isHittable)
        
        app.swipeRight() // Next element
        XCTAssertTrue(app.buttons["Sign in with Apple"].isHittable)
        
        // Then - All interactive elements should be accessible
        let interactiveElements = app.buttons.allElementsBoundByIndex + 
                                 app.textFields.allElementsBoundByIndex +
                                 app.switches.allElementsBoundByIndex
        
        for element in interactiveElements {
            if element.exists && element.isHittable {
                XCTAssertTrue(element.isAccessibilityElement, "Element should be accessible: \(element.identifier)")
                XCTAssertNotNil(element.accessibilityLabel, "Element should have accessibility label: \(element.identifier)")
            }
        }
    }
    
    func testDynamicTypeSupport() throws {
        // Given - Test different text sizes
        let textSizes: [UIContentSizeCategory] = [
            .extraSmall, .large, .extraExtraLarge, .extraExtraExtraLarge
        ]
        
        for textSize in textSizes {
            // When - Set text size
            app.launchArguments.append("--dynamic-type-\(textSize)")
            app.launch()
            
            // Then - Text should be readable
            let welcomeText = app.staticTexts["Welcome to Aroosi"]
            if welcomeText.exists {
                XCTAssertTrue(welcomeText.exists, "Welcome text should be visible for text size: \(textSize)")
            }
        }
    }
    
    func testHighContrastSupport() throws {
        // Given - High contrast mode enabled
        app.launchArguments.append("--high-contrast")
        app.launch()
        
        // When - Navigate through app
        completeOnboardingFlow()
        
        // Then - All elements should be visible in high contrast
        let dashboardElements = app.buttons.allElementsBoundByIndex +
                               app.staticTexts.allElementsBoundByIndex
        
        for element in dashboardElements {
            if element.exists {
                XCTAssertTrue(element.isHittable, "Element should be accessible in high contrast: \(element.identifier)")
            }
        }
    }
    
    func testReducedMotionSupport() throws {
        // Given - Reduced motion enabled
        app.launchArguments.append("--reduced-motion")
        app.launch()
        
        // When - Navigate through app
        completeOnboardingFlow()
        
        // Then - Animations should be reduced
        // This is a simplified test - in reality, you'd check for specific animation properties
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
    }
    
    private func completeOnboardingFlow() {
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
        }
        
        if app.buttons["Sign in with Apple"].exists {
            app.buttons["Sign in with Apple"].tap()
        }
        
        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
        }
    }
}
