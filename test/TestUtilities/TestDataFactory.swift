import Foundation
@testable import AroosiKit

// MARK: - Test Data Factory

class TestDataFactory {
    
    // MARK: - User Profile Factory
    
    static func createUserProfile(
        id: String = UUID().uuidString,
        displayName: String = "Test User",
        email: String? = "test@example.com",
        avatarURL: URL? = nil
    ) -> UserProfile {
        return UserProfile(
            id: id,
            displayName: displayName,
            email: email,
            avatarURL: avatarURL
        )
    }
    
    static func createProfileSummary(
        id: String = UUID().uuidString,
        displayName: String = "Test Profile",
        age: Int = 28,
        location: String = "San Francisco, CA",
        bio: String = "Test bio for testing purposes",
        avatarURL: URL? = nil,
        interests: [String] = ["Travel", "Cooking", "Music"],
        lastActiveAt: Date = Date()
    ) -> ProfileSummary {
        return ProfileSummary(
            id: id,
            displayName: displayName,
            age: age,
            location: location,
            bio: bio,
            avatarURL: avatarURL,
            interests: interests,
            lastActiveAt: lastActiveAt
        )
    }
    
    // MARK: - Chat Message Factory
    
    static func createChatMessage(
        id: String = UUID().uuidString,
        conversationID: String = UUID().uuidString,
        authorID: String = UUID().uuidString,
        text: String = "Test message",
        sentAt: Date = Date(),
        deliveredAt: Date? = nil,
        readAt: Date? = nil
    ) -> ChatMessage {
        return ChatMessage(
            id: id,
            conversationID: conversationID,
            authorID: authorID,
            text: text,
            sentAt: sentAt,
            deliveredAt: deliveredAt,
            readAt: readAt
        )
    }
    
    static func createMessageThread(
        conversationID: String = UUID().uuidString,
        participantIDs: [String] = ["user-1", "user-2"],
        messageCount: Int = 5
    ) -> [ChatMessage] {
        var messages: [ChatMessage] = []
        
        for i in 0..<messageCount {
            let authorID = participantIDs[i % participantIDs.count]
            let message = createChatMessage(
                id: "msg-\(i)",
                conversationID: conversationID,
                authorID: authorID,
                text: "Message \(i + 1)",
                sentAt: Date().addingTimeInterval(TimeInterval(-i * 300)) // 5 minutes apart
            )
            messages.append(message)
        }
        
        return messages.sorted { $0.sentAt < $1.sentAt }
    }
    
    // MARK: - Match Factory
    
    static func createMatch(
        id: String = UUID().uuidString,
        participants: [Match.Participant] = [
            Match.Participant(userID: "user-1", isInitiator: true),
            Match.Participant(userID: "user-2", isInitiator: false)
        ],
        status: Match.Status = .active,
        lastMessagePreview: String = "Last message",
        lastUpdatedAt: Date = Date(),
        conversationID: String = UUID().uuidString
    ) -> Match {
        return Match(
            id: id,
            participants: participants,
            status: status,
            lastMessagePreview: lastMessagePreview,
            lastUpdatedAt: lastUpdatedAt,
            conversationID: conversationID
        )
    }
    
    static func createMatchListItem(
        match: Match = createMatch(),
        counterpartProfile: ProfileSummary = createProfileSummary(),
        unreadCount: Int = 0
    ) -> MatchListItem {
        return MatchListItem(
            id: match.id,
            match: match,
            counterpartProfile: counterpartProfile,
            unreadCount: unreadCount
        )
    }
    
    static func createMatchesList(count: Int = 10) -> [MatchListItem] {
        return (0..<count).map { index in
            let match = createMatch(
                id: "match-\(index)",
                lastMessagePreview: "Message \(index)",
                lastUpdatedAt: Date().addingTimeInterval(TimeInterval(-index * 3600))
            )
            
            let profile = createProfileSummary(
                id: "profile-\(index)",
                displayName: "User \(index)",
                age: 25 + (index % 20),
                location: "City \(index)"
            )
            
            return createMatchListItem(
                match: match,
                counterpartProfile: profile,
                unreadCount: index % 3
            )
        }
    }
    
    // MARK: - Dashboard Info Factory
    
    static func createDashboardInfo(
        activeMatchesCount: Int = 5,
        unreadMessagesCount: Int = 12,
        recentMatches: [MatchListItem] = [],
        quickPicks: [ProfileSummary] = []
    ) -> DashboardInfo {
        return DashboardInfo(
            activeMatchesCount: activeMatchesCount,
            unreadMessagesCount: unreadMessagesCount,
            recentMatches: recentMatches,
            quickPicks: quickPicks
        )
    }
    
    static func createDashboardInfoWithSampleData() -> DashboardInfo {
        let recentMatches = createMatchesList(count: 3)
        let quickPicks = (0..<5).map { index in
            createProfileSummary(
                id: "quickpick-\(index)",
                displayName: "Quick Pick \(index)",
                age: 26 + (index % 15),
                interests: ["Interest \(index)", "Common Interest"]
            )
        }
        
        return createDashboardInfo(
            activeMatchesCount: 8,
            unreadMessagesCount: 15,
            recentMatches: recentMatches,
            quickPicks: quickPicks
        )
    }
    
    // MARK: - Settings Factory
    
    static func createUserSettings(
        pushNotificationsEnabled: Bool = true,
        emailNotificationsEnabled: Bool = true,
        profileVisibility: ProfileVisibility = .public,
        discoveryPreferences: DiscoveryPreferences = createDiscoveryPreferences()
    ) -> UserSettings {
        return UserSettings(
            pushNotificationsEnabled: pushNotificationsEnabled,
            emailNotificationsEnabled: emailNotificationsEnabled,
            profileVisibility: profileVisibility,
            discoveryPreferences: discoveryPreferences
        )
    }
    
    static func createDiscoveryPreferences(
        ageRange: ClosedRange<Int> = 18...35,
        maxDistance: Int = 50,
        interests: [String] = []
    ) -> DiscoveryPreferences {
        return DiscoveryPreferences(
            ageRange: ageRange,
            maxDistance: maxDistance,
            interests: interests
        )
    }
    
    // MARK: - Family Approval Factory
    
    static func createFamilyApprovalRequest(
        id: String = UUID().uuidString,
        requesterID: String = UUID().uuidString,
        targetUserID: String = UUID().uuidString,
        familyMemberID: String = UUID().uuidString,
        familyMemberName: String = "Family Member",
        familyMemberRelation: String = "Sister",
        status: FamilyApprovalRequest.Status = .pending,
        message: String = "Please approve this match",
        createdAt: Date = Date(),
        respondedAt: Date? = nil
    ) -> FamilyApprovalRequest {
        return FamilyApprovalRequest(
            id: id,
            requesterID: requesterID,
            targetUserID: targetUserID,
            familyMemberID: familyMemberID,
            familyMemberName: familyMemberName,
            familyMemberRelation: familyMemberRelation,
            status: status,
            message: message,
            createdAt: createdAt,
            respondedAt: respondedAt
        )
    }
    
    // MARK: - Compatibility Factory
    
    static func createCompatibilityResponse(
        questionID: String = UUID().uuidString,
        answer: String = "Strongly Agree",
        weight: Double = 1.0,
        category: String = "Values"
    ) -> CompatibilityResponse {
        return CompatibilityResponse(
            questionID: questionID,
            answer: answer,
            weight: weight,
            category: category
        )
    }
    
    static func createCompatibilityResponses(count: Int = 10) -> [CompatibilityResponse] {
        let categories = ["Values", "Lifestyle", "Family", "Religion", "Goals"]
        let answers = ["Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"]
        
        return (0..<count).map { index in
            createCompatibilityResponse(
                questionID: "question-\(index)",
                answer: answers[index % answers.count],
                weight: Double.random(in: 0.5...1.5),
                category: categories[index % categories.count]
            )
        }
    }
    
    static func createCompatibilityReport(
        userID1: String = UUID().uuidString,
        userID2: String = UUID().uuidString,
        overallScore: Int = 85,
        categoryScores: [String: Int] = [
            "Values": 90,
            "Lifestyle": 80,
            "Family": 85,
            "Religion": 88,
            "Goals": 82
        ],
        insights: [String] = [
            "Strong alignment in family values",
            "Complementary lifestyle preferences",
            "Similar religious views"
        ],
        generatedAt: Date = Date()
    ) -> CompatibilityReport {
        return CompatibilityReport(
            userID1: userID1,
            userID2: userID2,
            overallScore: overallScore,
            categoryScores: categoryScores,
            insights: insights,
            generatedAt: generatedAt
        )
    }
    
    // MARK: - Icebreaker Factory
    
    static func createIcebreakerQuestion(
        id: String = UUID().uuidString,
        text: String = "What's your favorite way to spend a weekend?",
        category: String = "Lifestyle",
        weight: Double = 1.0,
        active: Bool = true
    ) -> IcebreakerQuestion {
        return IcebreakerQuestion(
            id: id,
            text: text,
            category: category,
            weight: weight,
            active: active,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func createIcebreakerQuestions(count: Int = 20) -> [IcebreakerQuestion] {
        let categories = ["Lifestyle", "Travel", "Personal", "Food", "Entertainment", "Career"]
        let questions = [
            "What's your favorite way to spend a weekend?",
            "If you could travel anywhere right now, where would you go?",
            "What's a skill you've always wanted to learn?",
            "What's your go-to comfort food?",
            "What's the most interesting place you've ever visited?",
            "If you could have dinner with any historical figure, who would it be?",
            "What's your favorite book or movie and why?",
            "What's something that always makes you laugh?",
            "What's your favorite season and what do you love about it?",
            "If you could instantly master any instrument, what would it be?"
        ]
        
        return (0..<count).map { index in
            createIcebreakerQuestion(
                id: "question-\(index)",
                text: questions[index % questions.count],
                category: categories[index % categories.count],
                weight: Double.random(in: 0.8...1.2)
            )
        }
    }
    
    // MARK: - Search Results Factory
    
    static func createProfileSearchPage(
        items: [ProfileSummary] = [],
        nextCursor: String? = nil
    ) -> ProfileSearchPage {
        return ProfileSearchPage(items: items, nextCursor: nextCursor)
    }
    
    static func createSearchResults(count: Int = 20, hasMore: Bool = true) -> ProfileSearchPage {
        let profiles = (0..<count).map { index in
            createProfileSummary(
                id: "search-\(index)",
                displayName: "Search Result \(index)",
                age: 22 + (index % 25),
                location: "Location \(index)",
                interests: ["Interest \(index)", "Common Interest"]
            )
        }
        
        return createProfileSearchPage(
            items: profiles,
            nextCursor: hasMore ? "cursor-\(count)" : nil
        )
    }
    
    // MARK: - Error Factory
    
    static func createNetworkError() -> Error {
        return NSError(
            domain: "TestError",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "Network connection failed"]
        )
    }
    
    static func createAuthError() -> Error {
        return NSError(
            domain: "AuthError",
            code: 1002,
            userInfo: [NSLocalizedDescriptionKey: "Authentication failed"]
        )
    }
    
    static func createValidationError(message: String = "Invalid input") -> Error {
        return NSError(
            domain: "ValidationError",
            code: 1003,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    
    // MARK: - Date Utilities
    
    static func createDate(daysAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
    
    static func createDate(hoursAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: Date()) ?? Date()
    }
    
    static func createDate(minutesAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: Date()) ?? Date()
    }
}

// MARK: - Test Extensions

extension Array where Element == ProfileSummary {
    static func mockProfiles(count: Int = 10) -> [ProfileSummary] {
        return (0..<count).map { index in
            TestDataFactory.createProfileSummary(
                id: "profile-\(index)",
                displayName: "User \(index)",
                age: 25 + (index % 20),
                location: "City \(index)",
                interests: ["Interest \(index)", "Common Interest"]
            )
        }
    }
}

extension Array where Element == ChatMessage {
    static func mockMessages(count: Int = 5) -> [ChatMessage] {
        return TestDataFactory.createMessageThread(messageCount: count)
    }
}

extension Array where Element == MatchListItem {
    static func mockMatches(count: Int = 10) -> [MatchListItem] {
        return TestDataFactory.createMatchesList(count: count)
    }
}
