import Combine
import Foundation

@available(iOS 17, macOS 13, *)
@MainActor
final class ChatViewModel: ObservableObject {
    struct State: Equatable {
        var messages: [ChatMessage] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()
    @Published var draftMessage: String = ""

    private let conversationID: String
    private let currentUserID: String
    private let messageRepository: ChatMessageRepository
    private let deliveryService: ChatDeliveryServicing?
    private let conversationParticipants: [String]
    private let logger = Logger.shared

    private var messageStreamTask: Task<Void, Never>?

    init(conversationID: String,
         currentUserID: String,
         participants: [String],
         messageRepository: ChatMessageRepository = FirestoreChatMessageRepository(),
         deliveryService: ChatDeliveryServicing? = FirestoreChatDeliveryService()) {
        self.conversationID = conversationID
        self.currentUserID = currentUserID
        self.messageRepository = messageRepository
        self.deliveryService = deliveryService
        self.conversationParticipants = participants
    }

    deinit {
        messageStreamTask?.cancel()
    }

    func observeMessages() {
        guard messageStreamTask == nil else { return }
        guard !conversationID.isEmpty else { return }

        state.isLoading = true
        state.errorMessage = nil

        messageStreamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await messages in self.messageRepository.streamMessages(conversationID: self.conversationID) {
                    try Task.checkCancellation()
                    let sorted = messages.sorted { $0.sentAt < $1.sentAt }
                    self.state.messages = sorted
                    self.state.isLoading = false
                }
            } catch {
                if (error as? CancellationError) != nil { return }
                self.logger.error("Failed to observe messages: \(error.localizedDescription)")
                self.state.errorMessage = "We couldn't load this conversation. Please try again."
                self.state.isLoading = false
            }
        }
    }

    func stop() {
        messageStreamTask?.cancel()
        messageStreamTask = nil
    }

    func refresh() async {
        stop()
        state.isLoading = true
        state.errorMessage = nil
        observeMessages()
    }

    func sendMessage() async {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let text = trimmed
        draftMessage = ""

        do {
            guard !conversationID.isEmpty else {
                state.errorMessage = "This conversation is not available yet."
                draftMessage = text
                return
            }

            let sentAt = Date()
            _ = try await messageRepository.sendMessage(conversationID: conversationID,
                                                        authorID: currentUserID,
                                                        text: text,
                                                        sentAt: sentAt)

            if let deliveryService {
                do {
                    try await deliveryService.handleMessageSent(conversationID: conversationID,
                                                                 senderID: currentUserID,
                                                                 participants: conversationParticipants,
                                                                 sentAt: sentAt)
                } catch {
                    logger.error("Failed to update delivery metadata: \(error.localizedDescription)")
                }
            }
        } catch {
            logger.error("Failed to send message: \(error.localizedDescription)")
            state.errorMessage = "We couldn't send that message."
            draftMessage = text
        }
    }

    func markConversationRead() async {
        guard let deliveryService, !conversationID.isEmpty else { return }

        do {
            try await deliveryService.markConversationRead(conversationID: conversationID, userID: currentUserID)
        } catch {
            logger.error("Failed to mark conversation as read: \(error.localizedDescription)")
        }
    }
}
