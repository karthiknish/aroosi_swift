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
    this.isMine,
    this.imageUrl,
    this.caption,
    this.replyTo,
    this.reactions = const {},
    this.audioStorageId,
    this.duration,
    this.fileSize,
  });

  final String id;
  final String conversationId;
  final String text;
  final int createdAt; // epoch millis
  final String? fromUserId;
  final String? toUserId;
  final String type; // 'text' | 'voice' | 'image'

  /// Convenience flag to mark author's side in UI; when null, compute from fromUserId externally
  final bool? isMine;
  final String? imageUrl; // for type 'image'
  final String? caption; // optional caption for image
  final String? replyTo; // messageId being replied to
  // Map emoji -> list of userIds who reacted
  final Map<String, List<String>> reactions;

  final String? audioStorageId; // for type 'voice'
  final int? duration; // voice duration seconds
  final int? fileSize; // bytes for voice/image

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? text,
    int? createdAt,
    String? fromUserId,
    String? toUserId,
    String? type,
    bool? isMine,
    String? imageUrl,
    String? caption,
    String? replyTo,
    Map<String, List<String>>? reactions,
    String? audioStorageId,
    int? duration,
    int? fileSize,
  }) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    text: text ?? this.text,
    createdAt: createdAt ?? this.createdAt,
    fromUserId: fromUserId ?? this.fromUserId,
    toUserId: toUserId ?? this.toUserId,
    type: type ?? this.type,
    isMine: isMine ?? this.isMine,
    imageUrl: imageUrl ?? this.imageUrl,
    caption: caption ?? this.caption,
    replyTo: replyTo ?? this.replyTo,
    reactions: reactions ?? this.reactions,
    audioStorageId: audioStorageId ?? this.audioStorageId,
    duration: duration ?? this.duration,
    fileSize: fileSize ?? this.fileSize,
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
      imageUrl: json['imageUrl']?.toString() ?? json['url']?.toString(),
      caption: json['caption']?.toString(),
      replyTo:
          json['replyTo']?.toString() ?? json['replyMessageId']?.toString(),
      reactions: _parseReactions(json['reactions']),
      audioStorageId:
          json['audioStorageId']?.toString() ?? json['storageId']?.toString(),
      duration: _parseInt(json['duration']),
      fileSize: _parseInt(json['fileSize']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static Map<String, List<String>> _parseReactions(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return map.map((k, v) {
        final list =
            (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        return MapEntry(k.toString(), list);
      });
    }
    if (raw is List) {
      // Accept shape: [{ emoji: '👍', userId: 'u1' }, ...]
      final result = <String, List<String>>{};
      for (final item in raw) {
        if (item is Map) {
          final emoji = item['emoji']?.toString();
          final uid = item['userId']?.toString() ?? item['user']?.toString();
          if (emoji != null && uid != null) {
            result.putIfAbsent(emoji, () => <String>[]).add(uid);
          }
        }
      }
      return result;
    }
    return const {};
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
    imageUrl,
    caption,
    replyTo,
    reactions,
    audioStorageId,
    duration,
    fileSize,
  ];
}

class ConversationSummary extends Equatable {
  const ConversationSummary({
    required this.id,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.unreadCount = 0,
    this.lastMessage,
  });

  final String id;
  final String? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final int unreadCount;
  final ChatMessage? lastMessage;

  static ConversationSummary fromJson(Map<String, dynamic> json) {
    final id =
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['conversationId']?.toString() ??
        '';
    final unread = json['unread'] ?? json['unreadCount'] ?? 0;
    final last = json['lastMessage'] is Map<String, dynamic>
        ? ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
        : null;
    final avatar =
        json['partnerAvatar']?.toString() ??
        json['partnerAvatarUrl']?.toString() ??
        json['avatar']?.toString() ??
        json['avatarUrl']?.toString();
    return ConversationSummary(
      id: id,
      partnerId: json['partnerId']?.toString() ?? json['toUserId']?.toString(),
      partnerName:
          json['partnerName']?.toString() ?? json['toName']?.toString(),
      partnerAvatarUrl: avatar,
      unreadCount: unread is int ? unread : int.tryParse('$unread') ?? 0,
      lastMessage: last,
    );
  }

  @override
  List<Object?> get props => [
    id,
    partnerId,
    partnerName,
    partnerAvatarUrl,
    unreadCount,
    lastMessage,
  ];
}
