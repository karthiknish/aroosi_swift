# Phase 0 · Data Model Notes · Chat & Messaging

## Core Models (`lib/features/chat/chat_models.dart`)

### ChatMessage
- Fields: `id`, `conversationId`, `fromUserId`, optional `toUserId`, `text`, `type` (`text`/`image`/`voice`), `createdAt` (ISO8601 DateTime), booleans `isMine`, `isRead`, reactions map (emoji → [userId]), optional `duration`, `imageUrl`, `audioUrl`.
- Flutter parses `createdAt` via `DateTime.parse`; backend sometimes sends ISO strings, potentially numeric timestamps in other endpoints.
- **Swift Plan**:
  ```swift
  struct ChatMessage: Codable, Identifiable, Hashable {
      enum MessageType: String, Codable { case text, image, voice }
      var id: String
      var conversationId: String
      var fromUserId: String
      var toUserId: String?
      var text: String
      var type: MessageType
      var createdAt: Date
      var isMine: Bool
      var isRead: Bool
      var reactions: [String: [String]]
      var duration: Int?
      var imageURL: URL?
      var audioURL: URL?
  }
  ```
  - Provide custom decoder to accept ISO strings or millis epoch; fallback to `Date()` with logging.
  - Reaction map should leverage `[String: Set<String>]` for deduplication if desired.
  - Derive presentation helpers (e.g., `timeAgo`) in Swift extensions.

### ConversationSummary
- Represents chat list cells; backend may return either `participants` array or direct partner fields.
- Fields: `id`, `partnerId`, `partnerName`, `partnerAvatarUrl`, `lastMessageText`, `lastMessageAt`, `unreadCount`, `isOnline`, `lastSeen`.
- Flutter includes fallback logic to parse Next.js conversation format; Swift decoder must handle multiple shapes (ids in `_id`, `conversationId`, participants array).
- **Swift Plan**:
  ```swift
  struct ConversationSummary: Codable, Identifiable, Hashable {
      var id: String
      var partnerId: String
      var partnerName: String
      var partnerAvatarURL: URL?
      var lastMessageText: String?
      var lastMessageAt: Date?
      var unreadCount: Int
      var isOnline: Bool
      var lastSeen: Date?
  }
  ```
  - Build custom `init(from:)` to extract partner info from participants list (skip current user ID using auth context) or fallback fields.

### TypingPresence
- Minimal struct: `conversationId`, `typingUsers` array, `isOnline`, `lastSeen` optional `Date`.
- Swift can map directly to `TypingPresence` struct.

## Repositories & Services
- `chat_repository.dart` integrates with REST endpoints (`/chat/messages`, `/chat/conversations`) and Firestore listeners for real-time updates (verify inside file).
- `delivery_receipt_service.dart` ensures read receipts by writing to Firestore or hitting REST endpoint.
- `typing_presence_controller.dart` uses websockets or Firestore `typing` subcollection; map to Combine publishers.

## Storage & Sync Considerations
- Media uploads likely handled via Firebase Storage; confirm in repository. Swift should wrap `StorageReference` for image/audio.
- Voice message durations stored as seconds; ensure audio playback UI maps to `TimeInterval`.
- Reaction map uses emoji keys; adopt `String` keys in Swift (no specialized type needed).

## Outstanding Questions
1. Confirm message payload shape from backend (ISO vs epoch). Need sample JSON for accurate decoding.
2. Determine websocket or Firebase channel for typing presence and unread counts to plan Combine publishers.
3. Identify push notification payload structure for chat messages (likely from Firebase Cloud Messaging) to integrate background updates.
