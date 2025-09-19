import 'package:equatable/equatable.dart';

/// Chat message model with enhanced properties for better UI/UX
class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String fromUserId;
  final String? toUserId;
  final String text;
  final String type; // 'text', 'image', 'voice'
  final DateTime createdAt;
  final bool isMine;
  final bool isRead;
  final Map<String, List<String>> reactions; // emoji -> [userIds]
  final int? duration; // for voice messages in seconds
  final String? imageUrl; // for image messages
  final String? audioUrl; // for voice messages

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.fromUserId,
    this.toUserId,
    required this.text,
    this.type = 'text',
    required this.createdAt,
    this.isMine = false,
    this.isRead = false,
    this.reactions = const {},
    this.duration,
    this.imageUrl,
    this.audioUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      fromUserId: json['fromUserId']?.toString() ?? '',
      toUserId: json['toUserId']?.toString(),
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      isMine: json['isMine'] == true,
      isRead: json['isRead'] == true,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String>.from(value ?? [])),
      ) ?? {},
      duration: json['duration'] as int?,
      imageUrl: json['imageUrl']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'text': text,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isMine': isMine,
      'isRead': isRead,
      'reactions': reactions,
      'duration': duration,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        fromUserId,
        toUserId,
        text,
        type,
        createdAt,
        isMine,
        isRead,
        reactions,
        duration,
        imageUrl,
        audioUrl,
      ];

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? fromUserId,
    String? toUserId,
    String? text,
    String? type,
    DateTime? createdAt,
    bool? isMine,
    bool? isRead,
    Map<String, List<String>>? reactions,
    int? duration,
    String? imageUrl,
    String? audioUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      text: text ?? this.text,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  // Helper methods for UI
  bool get hasReactions => reactions.isNotEmpty;
  int get totalReactions => reactions.values.fold(0, (sum, list) => sum + list.length);
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

/// Conversation summary model for chat list
class ConversationSummary extends Equatable {
  final String id;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen;

  const ConversationSummary({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      partnerName: json['partnerName']?.toString() ?? '',
      partnerAvatarUrl: json['partnerAvatarUrl']?.toString(),
      lastMessageText: json['lastMessageText']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        partnerName,
        partnerAvatarUrl,
        lastMessageText,
        lastMessageAt,
        unreadCount,
        isOnline,
        lastSeen,
      ];
}

/// Typing presence model
class TypingPresence extends Equatable {
  final String conversationId;
  final List<String> typingUsers;
  final bool isOnline;
  final DateTime? lastSeen;

  const TypingPresence({
    required this.conversationId,
    this.typingUsers = const [],
    this.isOnline = false,
    this.lastSeen,
  });

  factory TypingPresence.fromJson(Map<String, dynamic> json) {
    return TypingPresence(
      conversationId: json['conversationId']?.toString() ?? '',
      typingUsers: List<String>.from(json['typingUsers'] ?? []),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
    );
  }

  @override
  List<Object?> get props => [conversationId, typingUsers, isOnline, lastSeen];

  bool get isTyping => typingUsers.isNotEmpty;
}