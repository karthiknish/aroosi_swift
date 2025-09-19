import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.createdAt,
    this.fromUserId,
    this.toUserId,
    this.type = 'text',
    this.audioStorageId,
    this.duration,
    this.fileSize,
    this.mimeType,
    this.readAt,
    this.isMine,
    this.reactions = const {},
  });

  final String id;
  final String conversationId;
  final String text;
  final int createdAt; // epoch millis
  final String? fromUserId;
  final String? toUserId;
  final String type; // 'text' | 'voice' | 'image'

  final String? audioStorageId; // for type 'voice'
  final int? duration; // voice duration seconds
  final int? fileSize; // bytes for voice/image
  final String? mimeType; // MIME type for files
  final int? readAt; // when message was read

  /// Convenience flag to mark author's side in UI; when null, compute from fromUserId externally
  final bool? isMine;

  /// Reactions on this message: {emoji: [userIds]}
  final Map<String, List<String>> reactions;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? text,
    int? createdAt,
    String? fromUserId,
    String? toUserId,
    String? type,
    bool? isMine,
    String? audioStorageId,
    int? duration,
    int? fileSize,
    String? mimeType,
    int? readAt,
    Map<String, List<String>>? reactions,
  }) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    text: text ?? this.text,
    createdAt: createdAt ?? this.createdAt,
    fromUserId: fromUserId ?? this.fromUserId,
    toUserId: toUserId ?? this.toUserId,
    type: type ?? this.type,
    isMine: isMine ?? this.isMine,
    audioStorageId: audioStorageId ?? this.audioStorageId,
    duration: duration ?? this.duration,
    fileSize: fileSize ?? this.fileSize,
    mimeType: mimeType ?? this.mimeType,
    readAt: readAt ?? this.readAt,
    reactions: reactions ?? this.reactions,
  );

  static ChatMessage fromJson(Map<String, dynamic> json) {
    // Accept various common shapes
    final created = json['createdAt'] ?? json['created'] ?? json['timestamp'];
    final text = json['text'] ?? json['message'] ?? json['content'] ?? '';
    final convId =
        json['conversationId'] ?? json['convId'] ?? json['threadId'] ?? '';
    final id =
        json['id']?.toString() ??
        json['_id']?.toString() ??
        '${convId}_${created ?? DateTime.now().millisecondsSinceEpoch}';
    
    // Parse reactions if present
    Map<String, List<String>> reactions = {};
    if (json['reactions'] is Map) {
      final reactionsMap = json['reactions'] as Map;
      reactionsMap.forEach((key, value) {
        if (value is List) {
          reactions[key.toString()] = value.map((e) => e.toString()).toList();
        }
      });
    }
    
    return ChatMessage(
      id: id,
      conversationId: convId.toString(),
      text: text.toString(),
      createdAt: created is int
          ? created
          : int.tryParse(created?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      fromUserId: json['fromUserId']?.toString() ?? json['from']?.toString(),
      toUserId: json['toUserId']?.toString() ?? json['to']?.toString(),
      type: json['type']?.toString() ?? 'text',
      isMine: json['isMine'] is bool ? json['isMine'] as bool : null,
      audioStorageId:
          json['audioStorageId']?.toString() ?? json['storageId']?.toString(),
      duration: _parseInt(json['duration']),
      fileSize: _parseInt(json['fileSize']),
      mimeType: json['mimeType']?.toString() ?? json['contentType']?.toString(),
      readAt: _parseInt(json['readAt']),
      reactions: reactions,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [
    id,
    conversationId,
    text,
    createdAt,
    fromUserId,
    toUserId,
    type,
    isMine,
    audioStorageId,
    duration,
    fileSize,
    mimeType,
    readAt,
    reactions,
  ];
}

class ConversationSummary extends Equatable {
  const ConversationSummary({
    required this.id,
    this.participants = const [],
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.unreadCount = 0,
  });

  final String id;
  final List<String> participants;
  final ChatMessage? lastMessage;
  final int? lastMessageAt;
  final int? createdAt;
  final String? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final int unreadCount;

  static ConversationSummary fromJson(Map<String, dynamic> json) {
    final id =
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['conversationId']?.toString() ??
        '';
    final participants = json['participants'] is List
        ? (json['participants'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final last = json['lastMessage'] is Map<String, dynamic>
        ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
        : null;
    return ConversationSummary(
      id: id,
      participants: participants,
      lastMessage: last,
      lastMessageAt: _parseInt(json['lastMessageAt']),
      createdAt: _parseInt(json['createdAt']),
      partnerId: json['partnerId']?.toString(),
      partnerName: json['partnerName']?.toString(),
      partnerAvatarUrl: json['partnerAvatarUrl']?.toString(),
      unreadCount: _parseInt(json['unreadCount']) ?? 0,
    );
  }

  ConversationSummary copyWith({
    String? id,
    List<String>? participants,
    ChatMessage? lastMessage,
    int? lastMessageAt,
    int? createdAt,
    String? partnerId,
    String? partnerName,
    String? partnerAvatarUrl,
    int? unreadCount,
  }) => ConversationSummary(
    id: id ?? this.id,
    participants: participants ?? this.participants,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    createdAt: createdAt ?? this.createdAt,
    partnerId: partnerId ?? this.partnerId,
    partnerName: partnerName ?? this.partnerName,
    partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [
    id,
    participants,
    lastMessage,
    lastMessageAt,
    createdAt,
    partnerId,
    partnerName,
    partnerAvatarUrl,
    unreadCount,
  ];
}
