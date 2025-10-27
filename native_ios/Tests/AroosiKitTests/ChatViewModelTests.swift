import Foundation
import XCTest
@testable import AroosiKit

@available(iOS 17, macOS 13, *)
@MainActor
final class ChatViewModelTests: XCTestCase {
    func testObserveMessagesPublishesSortedMessages() async {
        let repository = ChatMessageRepositoryStub()
        let deliveryService = ChatDeliveryServiceStub()
        let viewModel = ChatViewModel(conversationID: "conversation-1",
                                      currentUserID: "user-1",
                                      participants: ["user-1", "user-2"],
                                      messageRepository: repository,
                                      deliveryService: deliveryService)

        viewModel.observeMessages()
        await Task.yield()
        await Task.yield()

        let older = ChatMessage(id: "1",
                                conversationID: "conversation-1",
                                authorID: "user-2",
                                text: "Salam",
                                sentAt: Date(timeIntervalSince1970: 10))
        let newer = ChatMessage(id: "2",
                                conversationID: "conversation-1",
                                authorID: "user-1",
                                text: "Hi there",
                                sentAt: Date(timeIntervalSince1970: 20))

        repository.send([newer, older])

        await wait(for: viewModel) { $0.messages.count == 2 }

        XCTAssertEqual(viewModel.state.messages.first, older)
        XCTAssertEqual(viewModel.state.messages.last, newer)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testSendMessageDelegatesToRepository() async {
        let repository = ChatMessageRepositoryStub()
        let deliveryService = ChatDeliveryServiceStub()
        let viewModel = ChatViewModel(conversationID: "conversation-1",
                                      currentUserID: "user-1",
                                      participants: ["user-1", "user-2"],
                                      messageRepository: repository,
                                      deliveryService: deliveryService)

        viewModel.draftMessage = "  Hola  "
        await viewModel.sendMessage()

        XCTAssertEqual(repository.sentMessages.count, 1)
        XCTAssertEqual(repository.sentMessages.first?.conversationID, "conversation-1")
        XCTAssertEqual(repository.sentMessages.first?.authorID, "user-1")
        XCTAssertEqual(repository.sentMessages.first?.text, "Hola")
        XCTAssertEqual(viewModel.draftMessage, "")
        XCTAssertEqual(deliveryService.messageSentCalls.count, 1)
        XCTAssertEqual(deliveryService.messageSentCalls.first?.conversationID, "conversation-1")
        XCTAssertEqual(deliveryService.messageSentCalls.first?.senderID, "user-1")
        XCTAssertEqual(deliveryService.messageSentCalls.first?.participants.sorted(), ["user-1", "user-2"])
        XCTAssertEqual(deliveryService.messageSentCalls.first?.sentAt, repository.sentMessages.first?.sentAt)
    }

    func testMarkConversationReadDelegatesToRepository() async {
        let repository = ChatMessageRepositoryStub()
        let deliveryService = ChatDeliveryServiceStub()
        let viewModel = ChatViewModel(conversationID: "conversation-1",
                                      currentUserID: "user-1",
                                      participants: ["user-1", "user-2"],
                                      messageRepository: repository,
                                      deliveryService: deliveryService)

        await viewModel.markConversationRead()

        XCTAssertEqual(deliveryService.markReadCalls.count, 1)
        XCTAssertEqual(deliveryService.markReadCalls.first?.conversationID, "conversation-1")
        XCTAssertEqual(deliveryService.markReadCalls.first?.userID, "user-1")
    }

    private func wait(for viewModel: ChatViewModel,
                      timeout: TimeInterval = 1,
                      predicate: @escaping (ChatViewModel.State) -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate(viewModel.state) { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for chat view model state")
    }
}

@available(iOS 15.0, macOS 12.0, *)
@preconcurrency
private final class ChatMessageRepositoryStub: ChatMessageRepository {
    struct SentMessage: Equatable {
        let conversationID: String
        let authorID: String
        let text: String
        let sentAt: Date
    }

    var sentMessages: [SentMessage] = []

    private var continuation: AsyncThrowingStream<[ChatMessage], Error>.Continuation?

    func streamMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
        }
    }

    func sendMessage(conversationID: String,
                     authorID: String,
                     text: String,
                     sentAt: Date) async throws -> ChatMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = ChatMessage(id: UUID().uuidString,
                                  conversationID: conversationID,
                                  authorID: authorID,
                                  text: trimmed,
                                  sentAt: sentAt)
        sentMessages.append(SentMessage(conversationID: conversationID,
                                        authorID: authorID,
                                        text: trimmed,
                                        sentAt: sentAt))
        return message
    }

    func sendImageMessage(conversationID: String,
                          authorID: String,
                          imageData: Data,
                          fileName: String,
                          contentType: String,
                          caption: String?,
                          sentAt: Date) async throws -> ChatMessage {
        return try await sendMessage(conversationID: conversationID,
                                     authorID: authorID,
                                     text: caption ?? "",
                                     sentAt: sentAt)
    }

    func sendVoiceMessage(conversationID: String,
                          authorID: String,
                          audioData: Data,
                          fileName: String,
                          contentType: String,
                          duration: TimeInterval,
                          sentAt: Date) async throws -> ChatMessage {
        return try await sendMessage(conversationID: conversationID,
                                     authorID: authorID,
                                     text: "Voice message",
                                     sentAt: sentAt)
    }

    func addReaction(conversationID: String,
                     messageID: String,
                     emoji: String,
                     userID: String) async throws {}

    func removeReaction(conversationID: String,
                        messageID: String,
                        emoji: String,
                        userID: String) async throws {}

    func send(_ messages: [ChatMessage]) {
        continuation?.yield(messages)
    }
}

@available(iOS 15.0, macOS 12.0, *)
@preconcurrency
private final class ChatDeliveryServiceStub: ChatDeliveryServicing {
    struct MessageSentCall: Equatable {
        let conversationID: String
        let senderID: String
        let participants: [String]
        let sentAt: Date
    }

    struct MarkReadCall: Equatable {
        let conversationID: String
        let userID: String
    }

    var messageSentCalls: [MessageSentCall] = []
    var markReadCalls: [MarkReadCall] = []

    func handleMessageSent(conversationID: String,
                           senderID: String,
                           participants: [String],
                           sentAt: Date) async throws {
        messageSentCalls.append(MessageSentCall(conversationID: conversationID,
                                                senderID: senderID,
                                                participants: participants,
                                                sentAt: sentAt))
    }

    func markConversationRead(conversationID: String, userID: String) async throws {
        markReadCalls.append(MarkReadCall(conversationID: conversationID, userID: userID))
    }
}
