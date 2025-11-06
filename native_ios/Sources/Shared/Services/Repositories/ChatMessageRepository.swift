import Foundation

#if os(iOS)

@available(iOS 17.0, *)
public protocol ChatMessageRepository {
    func streamMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error>
    func sendMessage(conversationID: String,
                     authorID: String,
                     text: String,
                     sentAt: Date) async throws -> ChatMessage
    func sendImageMessage(conversationID: String,
                          authorID: String,
                          imageData: Data,
                          fileName: String,
                          contentType: String,
                          caption: String?,
                          sentAt: Date,
                          progress: ((Double) -> Void)?) async throws -> ChatMessage
    func sendVoiceMessage(conversationID: String,
                          authorID: String,
                          audioData: Data,
                          fileName: String,
                          contentType: String,
                          duration: TimeInterval,
                          sentAt: Date,
                          progress: ((Double) -> Void)?) async throws -> ChatMessage
    func sendReactionMessage(conversationID: String,
                             authorID: String,
                             reaction: String,
                             targetMessageID: String,
                             sentAt: Date) async throws -> ChatMessage
    func markMessageAsRead(conversationID: String,
                           messageID: String,
                           readerID: String) async throws
    func deleteMessage(conversationID: String,
                       messageID: String) async throws
    func addReaction(conversationID: String,
                     messageID: String,
                     emoji: String,
                     userID: String) async throws
    func removeReaction(conversationID: String,
                        messageID: String,
                        emoji: String,
                        userID: String) async throws
}

public extension ChatMessageRepository {
    func sendImageMessage(conversationID: String,
                          authorID: String,
                          imageData: Data,
                          fileName: String,
                          contentType: String,
                          caption: String?,
                          sentAt: Date) async throws -> ChatMessage {
        try await sendImageMessage(conversationID: conversationID,
                                   authorID: authorID,
                                   imageData: imageData,
                                   fileName: fileName,
                                   contentType: contentType,
                                   caption: caption,
                                   sentAt: sentAt,
                                   progress: nil)
    }

    func sendVoiceMessage(conversationID: String,
                          authorID: String,
                          audioData: Data,
                          fileName: String,
                          contentType: String,
                          duration: TimeInterval,
                          sentAt: Date) async throws -> ChatMessage {
        try await sendVoiceMessage(conversationID: conversationID,
                                   authorID: authorID,
                                   audioData: audioData,
                                   fileName: fileName,
                                   contentType: contentType,
                                   duration: duration,
                                   sentAt: sentAt,
                                   progress: nil)
    }
}

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseStorage

@available(iOS 17.0.0, *)
public final class FirestoreChatMessageRepository: ChatMessageRepository {
    private enum Constants {
        static let conversations = "conversations"
        static let messages = "messages"
        static let sentAt = "sentAt"
        static let authorID = "authorID"
        static let text = "text"
        static let type = "type"
        static let imageUrl = "imageUrl"
        static let audioUrl = "audioUrl"
        static let duration = "duration"
        static let reactions = "reactions"
        static let reactionValue = "reaction"
        static let reactionTargetID = "reactionTargetID"
        static let readReceipts = "readReceipts"
        static let lastActivityAt = "lastActivityAt"
        static let lastMessage = "lastMessage"
        static let unreadCounts = "unreadCounts"
        static let mediaImagesFolder = "images"
        static let mediaAudioFolder = "audio"
    }

    private let db: Firestore
    private let storage: Storage
    private let logger = Logger.shared

    public init(db: Firestore = .firestore(), storage: Storage = .storage()) {
        self.db = db
        self.storage = storage
    }

    public func streamMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
            let listeners = ListenerStore()

            let query = db.collection(Constants.conversations)
                .document(conversationID)
                .collection(Constants.messages)
                .order(by: Constants.sentAt, descending: false)

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.yield(with: .failure(self.mapError(error)))
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let messages = documents.compactMap { document -> ChatMessage? in
                    let normalized = self.normalizeMessage(document.data())
                    return ChatMessage(id: document.documentID,
                                       conversationID: conversationID,
                                       data: normalized)
                }

                continuation.yield(messages)
            }

            listeners.add(listener)

            continuation.onTermination = { _ in
                listeners.removeAll()
            }
        }
    }

    public func sendMessage(conversationID: String,
                             authorID: String,
                             text: String,
                             sentAt: Date) async throws -> ChatMessage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RepositoryError.invalidData }

        let payload: [String: Any] = [
            Constants.text: trimmed,
            Constants.type: ChatMessage.MessageType.text.rawValue
        ]

        return try await persistMessage(conversationID: conversationID,
                                        authorID: authorID,
                                        messageID: UUID().uuidString,
                                        sentAt: sentAt,
                                        payload: payload)
    }

    public func sendImageMessage(conversationID: String,
                                 authorID: String,
                                 imageData: Data,
                                 fileName: String,
                                 contentType: String,
                                 caption: String?,
                                 sentAt: Date,
                                 progress: ((Double) -> Void)?) async throws -> ChatMessage {
        let remoteURL = try await uploadMedia(data: imageData,
                                              conversationID: conversationID,
                                              messageID: UUID().uuidString,
                                              fileName: fileName,
                                              folder: Constants.mediaImagesFolder,
                                              contentType: contentType,
                                              progress: progress)

        let captionValue = caption?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let payload: [String: Any] = [
            Constants.text: captionValue,
            Constants.type: ChatMessage.MessageType.image.rawValue,
            Constants.imageUrl: remoteURL.absoluteString
        ]

        return try await persistMessage(conversationID: conversationID,
                                        authorID: authorID,
                                        messageID: UUID().uuidString,
                                        sentAt: sentAt,
                                        payload: payload)
    }

    public func sendVoiceMessage(conversationID: String,
                                 authorID: String,
                                 audioData: Data,
                                 fileName: String,
                                 contentType: String,
                                 duration: TimeInterval,
                                 sentAt: Date,
                                 progress: ((Double) -> Void)?) async throws -> ChatMessage {
        let remoteURL = try await uploadMedia(data: audioData,
                                              conversationID: conversationID,
                                              messageID: UUID().uuidString,
                                              fileName: fileName,
                                              folder: Constants.mediaAudioFolder,
                                              contentType: contentType,
                                              progress: progress)

        let payload: [String: Any] = [
            Constants.text: "Voice message",
            Constants.type: ChatMessage.MessageType.voice.rawValue,
            Constants.audioUrl: remoteURL.absoluteString,
            Constants.duration: duration
        ]

        return try await persistMessage(conversationID: conversationID,
                                        authorID: authorID,
                                        messageID: UUID().uuidString,
                                        sentAt: sentAt,
                                        payload: payload)
    }

    public func sendReactionMessage(conversationID: String,
                                    authorID: String,
                                    reaction: String,
                                    targetMessageID: String,
                                    sentAt: Date) async throws -> ChatMessage {
        try await updateReaction(conversationID: conversationID,
                                 messageID: targetMessageID,
                                 emoji: reaction,
                                 userID: authorID,
                                 inserting: true)

        let payload: [String: Any] = [
            Constants.text: "Reacted with \(reaction)",
            Constants.type: ChatMessage.MessageType.system.rawValue,
            Constants.reactionValue: reaction,
            Constants.reactionTargetID: targetMessageID
        ]

        return try await persistMessage(conversationID: conversationID,
                                        authorID: authorID,
                                        messageID: UUID().uuidString,
                                        sentAt: sentAt,
                                        payload: payload)
    }

    public func addReaction(conversationID: String,
                            messageID: String,
                            emoji: String,
                            userID: String) async throws {
        try await updateReaction(conversationID: conversationID,
                                 messageID: messageID,
                                 emoji: emoji,
                                 userID: userID,
                                 inserting: true)
    }

    public func removeReaction(conversationID: String,
                               messageID: String,
                               emoji: String,
                               userID: String) async throws {
        try await updateReaction(conversationID: conversationID,
                                 messageID: messageID,
                                 emoji: emoji,
                                 userID: userID,
                                 inserting: false)
    }

    public func markMessageAsRead(conversationID: String,
                                  messageID: String,
                                  readerID: String) async throws {
        let messageRef = db.collection(Constants.conversations)
            .document(conversationID)
            .collection(Constants.messages)
            .document(messageID)

        do {
            try await messageRef.setData([
                Constants.readReceipts: [readerID: FieldValue.serverTimestamp()]
            ], merge: true)
        } catch {
            throw mapError(error)
        }
    }

    public func deleteMessage(conversationID: String,
                              messageID: String) async throws {
        let messageRef = db.collection(Constants.conversations)
            .document(conversationID)
            .collection(Constants.messages)
            .document(messageID)

        do {
            try await messageRef.delete()
        } catch {
            throw mapError(error)
        }
    }

    private func persistMessage(conversationID: String,
                                authorID: String,
                                messageID: String,
                                sentAt: Date,
                                payload: [String: Any]) async throws -> ChatMessage {
        let conversationRef = db.collection(Constants.conversations).document(conversationID)
        let messageRef = conversationRef.collection(Constants.messages).document(messageID)

        var data = payload
        data[Constants.authorID] = authorID
        data[Constants.sentAt] = sentAt

        do {
            try await messageRef.setData(data)

            let lastMessagePreview = previewText(for: data)
            try await conversationRef.setData([
                Constants.lastActivityAt: sentAt,
                Constants.lastMessage: [
                    Constants.authorID: authorID,
                    Constants.text: lastMessagePreview,
                    Constants.sentAt: sentAt
                ]
            ], merge: true)
        } catch {
            throw mapError(error)
        }

        let normalized = normalizeMessage(data)
        guard let message = ChatMessage(id: messageID,
                                        conversationID: conversationID,
                                        data: normalized) else {
            throw RepositoryError.invalidData
        }

        return message
    }

    private func uploadMedia(data: Data,
                             conversationID: String,
                             messageID: String,
                             fileName: String,
                             folder: String,
                             contentType: String,
                             progress: ((Double) -> Void)? = nil) async throws -> URL {
        let sanitized = fileName.isEmpty ? UUID().uuidString : fileName
        let path = "\(Constants.conversations)/\(conversationID)/\(folder)/\(messageID)_\(sanitized)"
        let reference = storage.reference(withPath: path)

        let metadata = StorageMetadata()
        metadata.contentType = contentType

        var uploadTask: StorageUploadTask?

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                uploadTask = reference.putData(data, metadata: metadata)

                guard let uploadTask else {
                    logger.error("Failed to initiate upload task for conversation \(conversationID)")
                    continuation.resume(throwing: RepositoryError.unknown)
                    return
                }

                var progressHandle: String?
                var successHandle: String?
                var failureHandle: String?

                let cleanup = {
                    if let handle = progressHandle {
                        uploadTask.removeObserver(withHandle: handle)
                    }
                    if let handle = successHandle {
                        uploadTask.removeObserver(withHandle: handle)
                    }
                    if let handle = failureHandle {
                        uploadTask.removeObserver(withHandle: handle)
                    }
                }

                if let progress {
                    progressHandle = uploadTask.observe(.progress) { snapshot in
                        guard let fraction = snapshot.progress?.fractionCompleted else { return }
                        progress(fraction)
                    }
                }

                failureHandle = uploadTask.observe(.failure) { snapshot in
                    cleanup()

                    if let nsError = snapshot.error as NSError?,
                       let code = StorageErrorCode(rawValue: nsError.code),
                       code == .cancelled {
                        self.logger.info("Upload cancelled for conversation \(conversationID)")
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    if let error = snapshot.error {
                        self.logger.error("Failed to upload media for conversation \(conversationID): \(error.localizedDescription)")
                        continuation.resume(throwing: self.mapError(error))
                    } else {
                        self.logger.error("Failed to upload media for conversation \(conversationID): unknown error")
                        continuation.resume(throwing: RepositoryError.unknown)
                    }
                }

                successHandle = uploadTask.observe(.success) { _ in
                    cleanup()
                    progress?(1.0)

                    reference.downloadURL { url, error in
                        if let error {
                            self.logger.error("Failed to fetch download URL for conversation \(conversationID): \(error.localizedDescription)")
                            continuation.resume(throwing: self.mapError(error))
                            return
                        }

                        guard let url else {
                            self.logger.error("Download URL missing after upload for conversation \(conversationID)")
                            continuation.resume(throwing: RepositoryError.unknown)
                            return
                        }

                        continuation.resume(returning: url)
                    }
                }
            }
        } onCancel: {
            uploadTask?.cancel()
        }
    }

    private func updateReaction(conversationID: String,
                                messageID: String,
                                emoji: String,
                                userID: String,
                                inserting: Bool) async throws {
        let messageRef = db.collection(Constants.conversations)
            .document(conversationID)
            .collection(Constants.messages)
            .document(messageID)

        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(messageRef)
                    let data = snapshot.data() ?? [:]
                    var reactions = data[Constants.reactions] as? [String: [String]] ?? [:]
                    var users = Set(reactions[emoji] ?? [])

                    if inserting {
                        users.insert(userID)
                    } else {
                        users.remove(userID)
                    }

                    if users.isEmpty {
                        reactions.removeValue(forKey: emoji)
                    } else {
                        reactions[emoji] = Array(users)
                    }

                    transaction.updateData([Constants.reactions: reactions], forDocument: messageRef)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
        } catch {
            throw mapError(error)
        }
    }

    private func previewText(for payload: [String: Any]) -> String {
        if let text = payload[Constants.text] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }

        if let typeRaw = payload[Constants.type] as? String,
           let type = ChatMessage.MessageType(rawValue: typeRaw) {
            switch type {
            case .image:
                return "Shared an image"
            case .voice:
                return "Sent a voice message"
            case .system:
                return "System message"
            case .unknown:
                return "New message"
            case .text:
                return "New message"
            }
        }

        return "New message"
    }

    private func mapError(_ error: Error) -> Error {
        if let storageError = error as NSError?,
           storageError.domain == StorageErrorDomain,
           let storageCode = StorageErrorCode(rawValue: storageError.code) {
            switch storageCode {
            case .unauthorized, .unauthenticated:
                return RepositoryError.permissionDenied
            case .objectNotFound, .bucketNotFound:
                return RepositoryError.notFound
            case .cancelled:
                return CancellationError()
            case .quotaExceeded, .retryLimitExceeded, .unknown:
                return RepositoryError.networkFailure
            default:
                break
            }
        }

        if let firestoreError = error as NSError?,
           let codeValue = FirestoreErrorCode.Code(rawValue: firestoreError.code) {
            switch codeValue {
            case .permissionDenied:
                return RepositoryError.permissionDenied
            case .notFound:
                return RepositoryError.notFound
            case .alreadyExists:
                return RepositoryError.alreadyExists
            case .unavailable, .deadlineExceeded:
                return RepositoryError.networkFailure
            default:
                break
            }
        }

        logger.error("Chat message repository error: \(error.localizedDescription)")
        return RepositoryError.unknown
    }

    private func normalizeMessage(_ data: [String: Any]) -> [String: Any] {
        var normalized = data

        if let timestamp = data[Constants.sentAt] as? Timestamp {
            normalized[Constants.sentAt] = timestamp.dateValue()
        }

        if let durationNumber = data[Constants.duration] as? NSNumber {
            normalized[Constants.duration] = durationNumber.doubleValue
        }

        if let reactions = data[Constants.reactions] as? [String: Any] {
            var safeReactions: [String: [String]] = [:]
            for (emoji, value) in reactions {
                if let identifiers = value as? [String] {
                    safeReactions[emoji] = identifiers
                }
            }
            normalized[Constants.reactions] = safeReactions
        }

        return normalized
    }
}
#else
@available(iOS 17.0.0, *)
public final class FirestoreChatMessageRepository: ChatMessageRepository {
    public init() {}

    public func streamMessages(conversationID: String) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: RepositoryError.unknown)
        }
    }

    public func sendMessage(conversationID: String,
                             authorID: String,
                             text: String,
                             sentAt: Date) async throws -> ChatMessage {
        throw RepositoryError.unknown
    }

    public func sendImageMessage(conversationID: String,
                                 authorID: String,
                                 imageData: Data,
                                 fileName: String,
                                 contentType: String,
                                 caption: String?,
                                 sentAt: Date,
                                 progress: ((Double) -> Void)?) async throws -> ChatMessage {
        throw RepositoryError.unknown
    }

    public func sendVoiceMessage(conversationID: String,
                                 authorID: String,
                                 audioData: Data,
                                 fileName: String,
                                 contentType: String,
                                 duration: TimeInterval,
                                 sentAt: Date,
                                 progress: ((Double) -> Void)?) async throws -> ChatMessage {
        throw RepositoryError.unknown
    }

    public func sendReactionMessage(conversationID: String,
                                    authorID: String,
                                    reaction: String,
                                    targetMessageID: String,
                                    sentAt: Date) async throws -> ChatMessage {
        throw RepositoryError.unknown
    }

    public func markMessageAsRead(conversationID: String,
                                  messageID: String,
                                  readerID: String) async throws {
        throw RepositoryError.unknown
    }

    public func deleteMessage(conversationID: String,
                              messageID: String) async throws {
        throw RepositoryError.unknown
    }

    public func addReaction(conversationID: String,
                            messageID: String,
                            emoji: String,
                            userID: String) async throws {
        throw RepositoryError.unknown
    }

    public func removeReaction(conversationID: String,
                               messageID: String,
                               emoji: String,
                               userID: String) async throws {
        throw RepositoryError.unknown
    }
}
#endif
#endif
