import Combine
import Foundation

@available(iOS 17, *)
@MainActor
final class ChatViewModel: ObservableObject {
    struct State: Equatable {
        var messages: [ChatMessage] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }

    @Published private(set) var state = State()
    @Published var draftMessage: String = ""

    private var conversationID: String?
    private let currentUserID: String
    private let messageRepository: ChatMessageRepository
    private let deliveryService: ChatDeliveryServicing?
    private let conversationParticipants: [String]
    private let logger = Logger.shared

    private var messageStreamTask: Task<Void, Never>?

    init(conversationID: String?,
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
        guard let conversationID, !conversationID.isEmpty else { return }

        state.isLoading = true
        state.errorMessage = nil

        let targetConversationID = conversationID

        messageStreamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await messages in self.messageRepository.streamMessages(conversationID: targetConversationID) {
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

    func updateConversationID(_ newConversationID: String) {
        stop()
        conversationID = newConversationID
        state = State(messages: [], isLoading: true, errorMessage: nil)
    }

    var hasConversation: Bool {
        if let conversationID, !conversationID.isEmpty {
            return true
        }
        return false
    }

    var conversationIdentifier: String? {
        conversationID
    }

    func sendMessage() async {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let text = trimmed
        draftMessage = ""

        do {
            guard let conversationID, !conversationID.isEmpty else {
                state.errorMessage = "This conversation is not available yet."
                draftMessage = text
                return
            }

            let sentAt = Date()
            _ = try await messageRepository.sendMessage(conversationID: conversationID,
                                                        authorID: currentUserID,
                                                        text: text,
                                                        sentAt: sentAt)
            
            // Show success toast for message sent
            ToastManager.shared.showInfo("Message sent")

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
        guard let deliveryService, let conversationID, !conversationID.isEmpty else { return }

        do {
            try await deliveryService.markConversationRead(conversationID: conversationID, userID: currentUserID)
        } catch {
            logger.error("Failed to mark conversation as read: \(error.localizedDescription)")
        }
    }
}
