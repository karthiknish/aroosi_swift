#if os(iOS)
import Foundation
import CoreData
import Network
import Combine
import SwiftUI

@available(iOS 17, *)
struct Conversation: Identifiable, Codable {
    var id: String
    var participantIDs: [String]
    var participantNames: [String]
    var lastMessageAt: Date?
    var unreadCount: Int

    init(id: String,
         participantIDs: [String] = [],
         participantNames: [String] = [],
         lastMessageAt: Date? = nil,
         unreadCount: Int = 0) {
        self.id = id
        self.participantIDs = participantIDs
        self.participantNames = participantNames
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
    }
}

@available(iOS 17, *)
class OfflineDataManager: ObservableObject {
    static let shared = OfflineDataManager()
    
    @Published var isOnline = true
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingOperations = 0
    @Published var cachedDataSize: Int64 = 0
    
    private let networkMonitor = NetworkMonitor()
    private let coreDataManager: CoreDataManager
    private let syncQueue = DispatchQueue(label: "com.aroosi.sync", qos: .utility)
    private var syncTimer: Timer?
    
    init(coreDataManager: CoreDataManager = DefaultCoreDataManager()) {
        self.coreDataManager = coreDataManager
        setupNetworkMonitoring()
        setupPeriodicSync()
        loadCachedDataSize()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.connectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.handleNetworkChange(isConnected: isConnected)
            }
            .store(in: &cancellables)
    }
    
    private func handleNetworkChange(isConnected: Bool) {
        isOnline = isConnected
        
        if isConnected {
            // Start sync when coming back online
            startSync()
        } else {
            // Stop sync when going offline
            stopSync()
        }
    }
    
    // MARK: - Message Caching
    
    func cacheMessage(_ message: ChatMessage) async {
        do {
            try await coreDataManager.saveMessage(message)
            updatePendingOperations()
        } catch {
            print("Failed to cache message: \(error)")
        }
    }
    
    func getCachedMessages(for conversationID: String, limit: Int = 50) async -> [ChatMessage] {
        do {
            return try await coreDataManager.fetchMessages(conversationID: conversationID, limit: limit)
        } catch {
            print("Failed to fetch cached messages: \(error)")
            return []
        }
    }
    
    func cacheConversation(_ conversation: Conversation) async {
        do {
            try await coreDataManager.saveConversation(conversation)
        } catch {
            print("Failed to cache conversation: \(error)")
        }
    }
    
    func getCachedConversations() async -> [Conversation] {
        do {
            return try await coreDataManager.fetchConversations()
        } catch {
            print("Failed to fetch cached conversations: \(error)")
            return []
        }
    }
    
    // MARK: - Profile Caching
    
    func cacheProfile(_ profile: ProfileSummary) async {
        do {
            try await coreDataManager.saveProfile(profile)
        } catch {
            print("Failed to cache profile: \(error)")
        }
    }
    
    func getCachedProfile(id: String) async -> ProfileSummary? {
        do {
            return try await coreDataManager.fetchProfile(id: id)
        } catch {
            print("Failed to fetch cached profile: \(error)")
            return nil
        }
    }
    
    func getCachedProfiles(userIDs: [String]) async -> [ProfileSummary] {
        do {
            return try await coreDataManager.fetchProfiles(userIDs: userIDs)
        } catch {
            print("Failed to fetch cached profiles: \(error)")
            return []
        }
    }
    
    // MARK: - Sync Operations
    
    private func setupPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.startSync()
            }
        }
    }
    
    private func startSync() {
        guard isOnline && syncStatus != .syncing else { return }
        
        syncStatus = .syncing
        
        syncQueue.async { [weak self] in
            Task { @MainActor in
                await self?.performSync()
            }
        }
    }
    
    private func stopSync() {
        syncStatus = .idle
    }
    
    private func performSync() async {
        do {
            // Sync pending messages
            await syncPendingMessages()
            
            // Sync conversations
            await syncConversations()
            
            // Sync profiles
            await syncProfiles()
            
            // Clean up old cached data
            await cleanupOldCachedData()
            
            syncStatus = .completed
            
            // Reset to idle after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.syncStatus = .idle
            }
            
        } catch {
            syncStatus = .failed
            print("Sync failed: \(error)")
        }
        
        updatePendingOperations()
    }
    
    private func syncPendingMessages() async {
        do {
            let pendingMessages = try await coreDataManager.fetchPendingMessages()
            
            for message in pendingMessages {
                // Try to send the message to server
                if await sendMessageToServer(message) {
                    // Mark as synced
                    try await coreDataManager.markMessageAsSynced(message.id)
                }
            }
        } catch {
            print("Failed to sync pending messages: \(error)")
        }
    }
    
    private func syncConversations() async {
        do {
            let cachedConversations = try await coreDataManager.fetchConversations()
            
            for conversation in cachedConversations {
                // Fetch latest conversation data from server
                if let latestConversation = await fetchConversationFromServer(conversation.id) {
                    try await coreDataManager.saveConversation(latestConversation)
                }
            }
        } catch {
            print("Failed to sync conversations: \(error)")
        }
    }
    
    private func syncProfiles() async {
        do {
            let cachedProfiles = try await coreDataManager.fetchAllProfiles()
            
            for profile in cachedProfiles {
                // Check if profile needs updating (older than 1 hour)
                if profile.lastActiveAt < Date().addingTimeInterval(-3600) {
                    if let latestProfile = await fetchProfileFromServer(profile.id) {
                        try await coreDataManager.saveProfile(latestProfile)
                    }
                }
            }
        } catch {
            print("Failed to sync profiles: \(error)")
        }
    }
    
    private func cleanupOldCachedData() async {
        do {
            // Remove messages older than 30 days
            let cutoffDate = Date().addingTimeInterval(-30 * 24 * 3600)
            try await coreDataManager.deleteOldMessages(before: cutoffDate)
            
            // Remove inactive profiles older than 7 days
            let profileCutoffDate = Date().addingTimeInterval(-7 * 24 * 3600)
            try await coreDataManager.deleteOldProfiles(before: profileCutoffDate)
            
            loadCachedDataSize()
        } catch {
            print("Failed to cleanup old cached data: \(error)")
        }
    }
    
    // MARK: - Server Operations (Mock)
    
    private func sendMessageToServer(_ message: ChatMessage) async -> Bool {
        // Mock implementation - would send to actual server
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        return Bool.random() // Simulate success/failure
    }
    
    private func fetchConversationFromServer(_ conversationID: String) async -> Conversation? {
        // Mock implementation - would fetch from actual server
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        return nil
    }
    
    private func fetchProfileFromServer(_ userID: String) async -> ProfileSummary? {
        // Mock implementation - would fetch from actual server
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        return nil
    }
    
    // MARK: - Cache Management
    
    private func loadCachedDataSize() {
        Task {
            do {
                cachedDataSize = try await coreDataManager.getCachedDataSize()
            } catch {
                print("Failed to load cached data size: \(error)")
            }
        }
    }
    
    func clearAllCachedData() async {
        do {
            try await coreDataManager.clearAllData()
            cachedDataSize = 0
            updatePendingOperations()
        } catch {
            print("Failed to clear cached data: \(error)")
        }
    }
    
    private func updatePendingOperations() {
        Task {
            do {
                pendingOperations = try await coreDataManager.getPendingOperationsCount()
            } catch {
                print("Failed to get pending operations count: \(error)")
            }
        }
    }
    
    // MARK: - Offline Indicators
    
    func getOfflineIndicatorState() -> OfflineIndicatorState {
        return OfflineIndicatorState(
            isOnline: isOnline,
            syncStatus: syncStatus,
            pendingOperations: pendingOperations,
            cachedDataSize: cachedDataSize
        )
    }
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Models

enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed
    
    var displayText: String {
        switch self {
        case .idle:
            return "Up to date"
        case .syncing:
            return "Syncing..."
        case .completed:
            return "Sync complete"
        case .failed:
            return "Sync failed"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return AroosiColors.success
        case .syncing:
            return AroosiColors.info
        case .completed:
            return AroosiColors.success
        case .failed:
            return AroosiColors.error
        }
    }
}

struct OfflineIndicatorState {
    let isOnline: Bool
    let syncStatus: SyncStatus
    let pendingOperations: Int
    let cachedDataSize: Int64
    
    var statusText: String {
        if !isOnline {
            return "Offline"
        }
        
        if pendingOperations > 0 {
            return "\(pendingOperations) pending"
        }
        
        return syncStatus.displayText
    }
    
    var statusColor: Color {
        if !isOnline {
            return .orange
        }
        
        if pendingOperations > 0 {
            return .yellow
        }
        
        return syncStatus.color
    }
}

// MARK: - Network Monitor

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var connectionStatusPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }
    
    private let subject = CurrentValueSubject<Bool, Never>(true)
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.subject.send(path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Core Data Manager Protocol

protocol CoreDataManager {
    func saveMessage(_ message: ChatMessage) async throws
    func fetchMessages(conversationID: String, limit: Int) async throws -> [ChatMessage]
    func fetchPendingMessages() async throws -> [ChatMessage]
    func markMessageAsSynced(_ messageID: String) async throws
    func saveConversation(_ conversation: Conversation) async throws
    func fetchConversations() async throws -> [Conversation]
    func saveProfile(_ profile: ProfileSummary) async throws
    func fetchProfile(id: String) async throws -> ProfileSummary?
    func fetchProfiles(userIDs: [String]) async throws -> [ProfileSummary]
    func fetchAllProfiles() async throws -> [ProfileSummary]
    func deleteOldMessages(before date: Date) async throws
    func deleteOldProfiles(before date: Date) async throws
    func clearAllData() async throws
    func getCachedDataSize() async throws -> Int64
    func getPendingOperationsCount() async throws -> Int
}

// MARK: - Default Core Data Manager

class DefaultCoreDataManager: CoreDataManager {
    private let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "AroosiOfflineData")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
    }
    
    func saveMessage(_ message: ChatMessage) async throws {
        let context = container.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                // Check if message already exists
                let fetchRequest: NSFetchRequest<CachedMessage> = CachedMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", message.id)
                
                do {
                    let existingMessages = try context.fetch(fetchRequest)
                    if let existingMessage = existingMessages.first {
                        // Update existing message
                        existingMessage.content = message.content
                        existingMessage.updatedAt = Date()
                        existingMessage.isSynced = true
                    } else {
                        // Create new message
                        let cachedMessage = CachedMessage(context: context)
                        cachedMessage.id = message.id
                        cachedMessage.content = message.content
                        cachedMessage.senderID = message.senderID
                        cachedMessage.senderName = message.senderName
                        cachedMessage.createdAt = message.createdAt
                        cachedMessage.updatedAt = Date()
                        cachedMessage.isFromCurrentUser = message.isFromCurrentUser
                        cachedMessage.messageType = message.messageType.rawValue
                        cachedMessage.isSynced = false // Mark as pending sync
                        
                        // Find or create conversation
                        let conversation = self.findOrCreateConversation(
                            conversationID: message.conversationID,
                            participantID: message.senderID,
                            participantName: message.senderName,
                            in: context
                        )
                        cachedMessage.conversation = conversation
                        
                        // Update conversation last message time
                        conversation.lastMessageAt = message.createdAt
                    }
                    
                    try context.save()
                    Logger.shared.info("Successfully saved message to Core Data: \(message.id)")
                    continuation.resume()
                    
                } catch {
                    Logger.shared.error("Failed to save message to Core Data: \(error.localizedDescription)")
                    continuation.resume(throwing: OfflineError.saveFailed)
                }
            }
        }
    }
    
    func fetchMessages(conversationID: String, limit: Int) async throws -> [ChatMessage] {
        let context = container.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<CachedMessage> = CachedMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "conversation.id == %@", conversationID)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
                fetchRequest.fetchLimit = limit
                
                do {
                    let cachedMessages = try context.fetch(fetchRequest)
                    let messages = cachedMessages.compactMap { cachedMessage -> ChatMessage? in
                        guard let id = cachedMessage.id,
                              let content = cachedMessage.content,
                              let senderID = cachedMessage.senderID,
                              let createdAt = cachedMessage.createdAt else {
                            return nil
                        }
                        
                        return ChatMessage(
                            id: id,
                            conversationID: conversationID,
                            senderID: senderID,
                            senderName: cachedMessage.senderName ?? "",
                            content: content,
                            messageType: MessageType(rawValue: cachedMessage.messageType ?? "text") ?? .text,
                            isFromCurrentUser: cachedMessage.isFromCurrentUser,
                            createdAt: createdAt,
                            isRead: true // Assume cached messages are read
                        )
                    }
                    
                    Logger.shared.info("Fetched \(messages.count) messages from Core Data for conversation: \(conversationID)")
                    continuation.resume(returning: messages)
                    
                } catch {
                    Logger.shared.error("Failed to fetch messages from Core Data: \(error.localizedDescription)")
                    continuation.resume(throwing: OfflineError.fetchFailed)
                }
            }
        }
    }
    
    func fetchPendingMessages() async throws -> [ChatMessage] {
        let context = container.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<CachedMessage> = CachedMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "isSynced == NO")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
                
                do {
                    let cachedMessages = try context.fetch(fetchRequest)
                    let messages = cachedMessages.compactMap { cachedMessage -> ChatMessage? in
                        guard let id = cachedMessage.id,
                              let content = cachedMessage.content,
                              let senderID = cachedMessage.senderID,
                              let createdAt = cachedMessage.createdAt,
                              let conversationID = cachedMessage.conversation?.id else {
                            return nil
                        }
                        
                        return ChatMessage(
                            id: id,
                            conversationID: conversationID,
                            senderID: senderID,
                            senderName: cachedMessage.senderName ?? "",
                            content: content,
                            messageType: MessageType(rawValue: cachedMessage.messageType ?? "text") ?? .text,
                            isFromCurrentUser: cachedMessage.isFromCurrentUser,
                            createdAt: createdAt,
                            isRead: true
                        )
                    }
                    
                    Logger.shared.info("Fetched \(messages.count) pending messages from Core Data")
                    continuation.resume(returning: messages)
                    
                } catch {
                    Logger.shared.error("Failed to fetch pending messages from Core Data: \(error.localizedDescription)")
                    continuation.resume(throwing: OfflineError.fetchFailed)
                }
            }
        }
    }
    
    func markMessageAsSynced(_ messageID: String) async throws {
        let context = container.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<CachedMessage> = CachedMessage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", messageID)
                
                do {
                    let cachedMessages = try context.fetch(fetchRequest)
                    if let cachedMessage = cachedMessages.first {
                        cachedMessage.isSynced = true
                        cachedMessage.updatedAt = Date()
                        try context.save()
                        
                        Logger.shared.info("Marked message as synced: \(messageID)")
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: OfflineError.messageNotFound)
                    }
                    
                } catch {
                    Logger.shared.error("Failed to mark message as synced: \(error.localizedDescription)")
                    continuation.resume(throwing: OfflineError.saveFailed)
                }
            }
        }
    }
    
    private func findOrCreateConversation(
        conversationID: String,
        participantID: String,
        participantName: String,
        in context: NSManagedObjectContext
    ) -> CachedConversation {
        let fetchRequest: NSFetchRequest<CachedConversation> = CachedConversation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", conversationID)
        
        do {
            let conversations = try context.fetch(fetchRequest)
            if let existingConversation = conversations.first {
                return existingConversation
            }
        } catch {
            Logger.shared.error("Failed to fetch conversation: \(error.localizedDescription)")
        }
        
        // Create new conversation
        let conversation = CachedConversation(context: context)
        conversation.id = conversationID
        conversation.participantID = participantID
        conversation.participantName = participantName
        conversation.unreadCount = 0
        conversation.updatedAt = Date()
        
        return conversation
    }
    
    func saveConversation(_ conversation: Conversation) async throws {
        // Mock Core Data implementation
        print("Saving conversation: \(conversation.id)")
    }
    
    func fetchConversations() async throws -> [Conversation] {
        // Mock Core Data implementation
        return []
    }
    
    func saveProfile(_ profile: ProfileSummary) async throws {
        // Mock Core Data implementation
        print("Saving profile: \(profile.id)")
    }
    
    func fetchProfile(id: String) async throws -> ProfileSummary? {
        // Mock Core Data implementation
        return nil
    }
    
    func fetchProfiles(userIDs: [String]) async throws -> [ProfileSummary] {
        // Mock Core Data implementation
        return []
    }
    
    func fetchAllProfiles() async throws -> [ProfileSummary] {
        // Mock Core Data implementation
        return []
    }
    
    func deleteOldMessages(before date: Date) async throws {
        // Mock Core Data implementation
        print("Deleting old messages before: \(date)")
    }
    
    func deleteOldProfiles(before date: Date) async throws {
        // Mock Core Data implementation
        print("Deleting old profiles before: \(date)")
    }
    
    func clearAllData() async throws {
        // Mock Core Data implementation
        print("Clearing all cached data")
    }
    
    func getCachedDataSize() async throws -> Int64 {
        // Mock Core Data implementation
        return 1024 * 1024 // 1MB
    }
    
    func getPendingOperationsCount() async throws -> Int {
        // Mock Core Data implementation
        return Int.random(in: 0...5)
    }
}

// MARK: - Offline Errors

enum OfflineError: Error, LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case messageNotFound
    case conversationNotFound
    case profileNotFound
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data to offline storage."
        case .fetchFailed:
            return "Failed to fetch data from offline storage."
        case .deleteFailed:
            return "Failed to delete data from offline storage."
        case .messageNotFound:
            return "Message not found in offline storage."
        case .conversationNotFound:
            return "Conversation not found in offline storage."
        case .profileNotFound:
            return "Profile not found in offline storage."
        case .syncFailed:
            return "Failed to sync data with server."
        }
    }
}

#endif
