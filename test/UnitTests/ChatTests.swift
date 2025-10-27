import XCTest
@testable import AroosiKit

@available(iOS 17, *)
@MainActor
final class ChatTests: XCTestCase {
    
    // MARK: - Message Sending Tests
    
    func testSendMessageSuccess() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        let mockDeliveryService = MockChatDeliveryService()
        let conversationID = "conv-123"
        let currentUserID = "user-123"
        let participants = ["user-123", "user-456"]
        
        let chatViewModel = ChatViewModel(
            conversationID: conversationID,
            currentUserID: currentUserID,
            participants: participants,
            messageRepository: mockMessageRepo,
            deliveryService: mockDeliveryService
        )
        
        let testMessage = "Hello, this is a test message!"
        chatViewModel.draftMessage = testMessage
        
        // When
        await chatViewModel.sendMessage()
        
        // Then
        XCTAssertTrue(mockMessageRepo.sendMessageCalled)
        XCTAssertEqual(mockMessageRepo.lastSentMessage?.text, testMessage)
        XCTAssertEqual(mockMessageRepo.lastSentMessage?.authorID, currentUserID)
        XCTAssertTrue(mockDeliveryService.markAsDeliveredCalled)
        XCTAssertEqual(chatViewModel.draftMessage, "")
    }
    
    func testSendMessageEmptyText() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        let chatViewModel = ChatViewModel(
            conversationID: "conv-123",
            currentUserID: "user-123",
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        chatViewModel.draftMessage = ""
        
        // When
        await chatViewModel.sendMessage()
        
        // Then
        XCTAssertFalse(mockMessageRepo.sendMessageCalled)
        XCTAssertNil(mockMessageRepo.lastSentMessage)
    }
    
    func testSendMessageFailure() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        mockMessageRepo.shouldFailSendMessage = true
        
        let chatViewModel = ChatViewModel(
            conversationID: "conv-123",
            currentUserID: "user-123",
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        chatViewModel.draftMessage = "Test message"
        
        // When
        await chatViewModel.sendMessage()
        
        // Then
        XCTAssertTrue(mockMessageRepo.sendMessageCalled)
        XCTAssertNotNil(chatViewModel.state.errorMessage)
        XCTAssertNotEqual(chatViewModel.draftMessage, "") // Message should not be cleared on failure
    }
    
    // MARK: - Message Loading Tests
    
    func testLoadMessagesSuccess() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        let conversationID = "conv-123"
        let currentUserID = "user-123"
        
        let expectedMessages = [
            ChatMessage(
                id: "msg-1",
                conversationID: conversationID,
                authorID: "user-456",
                text: "Hi there!",
                sentAt: Date().addingTimeInterval(-3600),
                deliveredAt: Date().addingTimeInterval(-3590),
                readAt: nil
            ),
            ChatMessage(
                id: "msg-2",
                conversationID: conversationID,
                authorID: currentUserID,
                text: "Hello back!",
                sentAt: Date().addingTimeInterval(-1800),
                deliveredAt: Date().addingTimeInterval(-1790),
                readAt: nil
            )
        ]
        
        mockMessageRepo.messagesToReturn = expectedMessages
        
        let chatViewModel = ChatViewModel(
            conversationID: conversationID,
            currentUserID: currentUserID,
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        // When
        await chatViewModel.refresh()
        
        // Then
        XCTAssertEqual(chatViewModel.state.messages.count, 2)
        XCTAssertEqual(chatViewModel.state.messages.first?.text, "Hi there!")
        XCTAssertEqual(chatViewModel.state.messages.last?.text, "Hello back!")
        XCTAssertFalse(chatViewModel.state.isLoading)
        XCTAssertNil(chatViewModel.state.errorMessage)
    }
    
    func testLoadMessagesFailure() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        mockMessageRepo.shouldFailLoadMessages = true
        
        let chatViewModel = ChatViewModel(
            conversationID: "conv-123",
            currentUserID: "user-123",
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        // When
        await chatViewModel.refresh()
        
        // Then
        XCTAssertTrue(chatViewModel.state.messages.isEmpty)
        XCTAssertNotNil(chatViewModel.state.errorMessage)
        XCTAssertFalse(chatViewModel.state.isLoading)
    }
    
    // MARK: - Message Observation Tests
    
    func testObserveMessagesRealTimeUpdates() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        let chatViewModel = ChatViewModel(
            conversationID: "conv-123",
            currentUserID: "user-123",
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        let initialMessage = ChatMessage(
            id: "msg-1",
            conversationID: "conv-123",
            authorID: "user-456",
            text: "Initial message",
            sentAt: Date(),
            deliveredAt: nil,
            readAt: nil
        )
        
        mockMessageRepo.messagesToReturn = [initialMessage]
        
        // When
        await chatViewModel.observeMessages()
        
        // Then
        XCTAssertEqual(chatViewModel.state.messages.count, 1)
        XCTAssertEqual(chatViewModel.state.messages.first?.text, "Initial message")
    }
    
    // MARK: - Conversation Management Tests
    
    func testMarkConversationAsRead() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        let chatViewModel = ChatViewModel(
            conversationID: "conv-123",
            currentUserID: "user-123",
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        // When
        await chatViewModel.markConversationRead()
        
        // Then
        XCTAssertTrue(mockMessageRepo.markAsReadCalled)
    }
    
    func testUpdateConversationID() async throws {
        // Given
        let chatViewModel = ChatViewModel(
            conversationID: nil,
            currentUserID: "user-123",
            participants: ["user-123", "user-456"]
        )
        
        // When
        chatViewModel.updateConversationID("new-conv-456")
        
        // Then
        XCTAssertEqual(chatViewModel.conversationID, "new-conv-456")
    }
    
    // MARK: - Message State Tests
    
    func testMessageFromCurrentUser() async throws {
        // Given
        let currentUserID = "user-123"
        let messageFromCurrentUser = ChatMessage(
            id: "msg-1",
            conversationID: "conv-123",
            authorID: currentUserID,
            text: "My message",
            sentAt: Date(),
            deliveredAt: nil,
            readAt: nil
        )
        
        let messageFromOtherUser = ChatMessage(
            id: "msg-2",
            conversationID: "conv-123",
            authorID: "user-456",
            text: "Other message",
            sentAt: Date(),
            deliveredAt: nil,
            readAt: nil
        )
        
        // When & Then
        XCTAssertTrue(messageFromCurrentUser.isFromCurrentUser(currentUserID: currentUserID))
        XCTAssertFalse(messageFromOtherUser.isFromCurrentUser(currentUserID: currentUserID))
    }
    
    func testMessageTimestampFormatting() async throws {
        // Given
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let message = ChatMessage(
            id: "msg-1",
            conversationID: "conv-123",
            authorID: "user-123",
            text: "Test message",
            sentAt: pastDate,
            deliveredAt: nil,
            readAt: nil
        )
        
        // When
        let formattedTime = message.sentAtFormatted()
        
        // Then
        XCTAssertNotNil(formattedTime)
        XCTAssertFalse(formattedTime.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        mockMessageRepo.shouldFailSendMessage = true
        
        let chatViewModel = ChatViewModel(
            conversationID: "conv-123",
            currentUserID: "user-123",
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        // Trigger an error
        chatViewModel.draftMessage = "Test"
        await chatViewModel.sendMessage()
        XCTAssertNotNil(chatViewModel.state.errorMessage)
        
        // When
        chatViewModel.clearError()
        
        // Then
        XCTAssertNil(chatViewModel.state.errorMessage)
    }
    
    func testStopObservingMessages() async throws {
        // Given
        let mockMessageRepo = MockChatMessageRepository()
        let chatViewModel = ChatViewModel(
            conversationID: "conv-123",
            currentUserID: "user-123",
            participants: ["user-123", "user-456"],
            messageRepository: mockMessageRepo
        )
        
        // Start observing
        await chatViewModel.observeMessages()
        
        // When
        chatViewModel.stop()
        
        // Then
        XCTAssertTrue(mockMessageRepo.stopObservingCalled)
    }
}

// MARK: - Mock Classes

private class MockChatMessageRepository: ChatMessageRepository {
    var messagesToReturn: [ChatMessage] = []
    var shouldFailSendMessage = false
    var shouldFailLoadMessages = false
    var sendMessageCalled = false
    var markAsReadCalled = false
    var stopObservingCalled = false
    var lastSentMessage: ChatMessage?
    
    func sendMessage(_ message: ChatMessage) async throws {
        sendMessageCalled = true
        lastSentMessage = message
        
        if shouldFailSendMessage {
            throw ChatError.networkError
        }
    }
    
    func fetchMessages(conversationID: String, limit: Int) async throws -> [ChatMessage] {
        if shouldFailLoadMessages {
            throw ChatError.networkError
        }
        return messagesToReturn
    }
    
    func observeMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(messagesToReturn)
            continuation.finish()
        }
    }
    
    func markAsRead(conversationID: String, userID: String) async throws {
        markAsReadCalled = true
    }
    
    func stopObserving() {
        stopObservingCalled = true
    }
}

private class MockChatDeliveryService: ChatDeliveryServicing {
    var markAsDeliveredCalled = false
    
    func markAsDelivered(messageID: String) async throws {
        markAsDeliveredCalled = true
    }
}

private enum ChatError: Error {
    case networkError
}
