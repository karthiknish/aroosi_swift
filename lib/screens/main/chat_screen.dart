import 'package:flutter/material.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/features/chat/chat_controller.dart';
import 'package:aroosi_flutter/features/chat/chat_models.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:aroosi_flutter/features/chat/typing_presence_controller.dart';
import 'package:aroosi_flutter/core/realtime/realtime_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.conversationId, this.toUserId});

  final String? conversationId;
  final String? toUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;
  VoidCallback? _removeLoadMoreListener;
  bool _showJumpToLatest = false;
  bool _typing = false; // local echo of my typing for immediate UI
  bool _showEmoji = false;
  String? _replyToMessageId;
  String? _replyPreviewText;
  void Function(String, Map<String, dynamic>)? _onMsgHandler;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
      final notifier = ref.read(chatControllerProvider.notifier);
      notifier.setConversation(widget.conversationId!);
      notifier.setPeerUserId(widget.toUserId);
      // Hook realtime typing/presence
      final tp = ref.read(typingPresenceControllerProvider.notifier);
      tp.setConversation(widget.conversationId!, peerUserId: widget.toUserId);
      // Realtime incoming messages
      final rt = RealTimeService.instance;
      _onMsgHandler = (String convId, Map<String, dynamic> json) {
        if (convId == widget.conversationId) {
          final msg = ChatMessage.fromJson(json);
          ref.read(chatControllerProvider.notifier).appendIncoming(msg);
        }
      };
      rt.onMessage(_onMsgHandler!);
      // Load initial asynchronously after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadInitial();
      });
      // Attach load more listener for API-backed chat
      _removeLoadMoreListener = addLoadMoreListener(
        _scrollController,
        onLoadMore: () => ref.read(chatControllerProvider.notifier).loadMore(),
        canLoadMore: () {
          final s = ref.read(chatControllerProvider);
          return s.hasMore && !s.loading;
        },
      );
      _scrollController.addListener(_onScrollChange);
      // Auto-scroll when new messages arrive
      ref.listen<ChatState>(chatControllerProvider, (prev, next) {
        if (prev == null || next.messages.length > prev.messages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent + 80,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }
    // Local typing debounce: also inform realtime service
    _textController.addListener(() {
      final nowTyping = _textController.text.trim().isNotEmpty;
      if (nowTyping && !_typing) setState(() => _typing = true);
      if (!nowTyping && _typing) setState(() => _typing = false);
      if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
        ref
            .read(typingPresenceControllerProvider.notifier)
            .setMyTyping(nowTyping);
      }
    });
  }

  void _onScrollChange() {
    if (!_scrollController.hasClients) return;
    final nearBottom =
        _scrollController.position.pixels >=
        (_scrollController.position.maxScrollExtent - 120);
    final shouldShow = !nearBottom;
    if (shouldShow != _showJumpToLatest) {
      setState(() => _showJumpToLatest = shouldShow);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _removeLoadMoreListener?.call();
    if (_onMsgHandler != null) {
      RealTimeService.instance.offMessage(_onMsgHandler!);
      _onMsgHandler = null;
    }
    super.dispose();
  }

  void _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ToastService.instance.info('Type a message');
      return;
    }
    final isApiBacked =
        widget.conversationId != null && widget.conversationId!.isNotEmpty;
    if (isApiBacked) {
      final allowed = ref
          .read(featureUsageControllerProvider.notifier)
          .requestUsage(UsageMetric.messageSent);
      if (!allowed) {
        ToastService.instance.warning(
          'You\'ve reached your monthly message limit. Upgrade to Premium for unlimited messages.',
        );
        return;
      }
      try {
        await ref
            .read(chatControllerProvider.notifier)
            .send(text, toUserId: widget.toUserId);
        _textController.clear();
        setState(() {
          _showEmoji = false;
          _replyToMessageId = null;
          _replyPreviewText = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        ToastService.instance.success('Message sent');
      } catch (e) {
        ToastService.instance.error('Failed to send message.');
      }
      return;
    }
    setState(() => _sending = true);
    final allowed = ref
        .read(featureUsageControllerProvider.notifier)
        .requestUsage(UsageMetric.messageSent);
    if (!allowed) {
      ToastService.instance.warning(
        'You\'ve reached your monthly message limit. Upgrade to Premium for unlimited messages.',
      );
      setState(() => _sending = false);
      return;
    }
    try {
      // Simulate network send delay
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() {
        _messages.add(
          _ChatMessage(text: text, isMe: true, timestamp: DateTime.now()),
        );
        _textController.clear();
        _sending = false;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
      ToastService.instance.success('Message sent');
    } catch (e) {
      setState(() {
        _sending = false;
        _error = 'Failed to send message. Please try again.';
      });
      ToastService.instance.error('Failed to send message.');
    }
  }

  Future<void> _pickAndSendImage() async {
    final isApiBacked =
        widget.conversationId != null && widget.conversationId!.isNotEmpty;
    if (!isApiBacked) {
      ToastService.instance.info('Start a conversation to send images.');
      return;
    }
    final allowed = ref
        .read(featureUsageControllerProvider.notifier)
        .requestUsage(UsageMetric.messageSent);
    if (!allowed) {
      ToastService.instance.warning('Upgrade to send image messages.');
      return;
    }
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await ref
          .read(chatControllerProvider.notifier)
          .sendImage(
            bytes,
            filename: picked.name,
            contentType:
                'image/${picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'}',
            toUserId: widget.toUserId,
          );
      ToastService.instance.success('Image sent');
    } catch (e) {
      ToastService.instance.error('Failed to send image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApiBacked =
        widget.conversationId != null && widget.conversationId!.isNotEmpty;
    final chatState = isApiBacked ? ref.watch(chatControllerProvider) : null;
    final tpState = isApiBacked
        ? ref.watch(typingPresenceControllerProvider)
        : null;
    final me = ref.watch(authControllerProvider).profile;
    return AppScaffold(
      title: 'Chat',
      floatingActionButton: _showJumpToLatest
          ? FloatingActionButton.small(
              onPressed: () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: const Icon(Icons.arrow_downward),
            )
          : null,
      child: Column(
        children: [
          if (isApiBacked)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: (_typing || (tpState?.isTyping == true))
                  ? Container(
                      key: const ValueKey('typing'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Typing...',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    )
                  : (tpState != null)
                  ? Container(
                      key: const ValueKey('presence'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        (tpState.isOnline == true)
                            ? 'Online'
                            : (tpState.lastSeen != null
                                  ? 'Last seen ${DateTime.fromMillisecondsSinceEpoch(tpState.lastSeen!).toLocal()}'
                                  : ''),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          Expanded(
            child: isApiBacked
                ? AdaptiveRefresh(
                    onRefresh: () =>
                        ref.read(chatControllerProvider.notifier).refresh(),
                    child: Builder(
                      builder: (_) {
                        if (chatState?.error != null) {
                          return Center(
                            child: Text(
                              chatState!.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          );
                        }
                        if (chatState == null ||
                            (chatState.loading && chatState.messages.isEmpty)) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (chatState.messages.isEmpty) {
                          return const Center(
                            child: Text('No messages yet. Say hello!'),
                          );
                        }
                        return ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final ChatMessage msg = chatState.messages[index];
                            final isMe =
                                msg.isMine == true ||
                                (me != null && (msg.fromUserId == me.id));
                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPressStart: (details) async {
                                  final selected = await showMenu<String>(
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                      details.globalPosition.dx,
                                      details.globalPosition.dy,
                                      details.globalPosition.dx,
                                      details.globalPosition.dy,
                                    ),
                                    items: [
                                      const PopupMenuItem(
                                        value: 'reply',
                                        child: Text('Reply'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'react',
                                        child: Text('React'),
                                      ),
                                      if (isMe)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                    ],
                                  );
                                  if (selected == 'reply') {
                                    setState(() {
                                      _replyToMessageId = msg.id;
                                      _replyPreviewText = msg.text;
                                    });
                                    ref
                                        .read(chatControllerProvider.notifier)
                                        .setReplyTo(msg.id);
                                  } else if (selected == 'react') {
                                    // Open bottom sheet with full emoji categories
                                    final reaction =
                                        await showModalBottomSheet<String>(
                                          context: context,
                                          showDragHandle: true,
                                          builder: (ctx) => SizedBox(
                                            height: 360,
                                            child: EmojiPicker(
                                              onEmojiSelected:
                                                  (category, emoji) {
                                                    Navigator.pop(
                                                      ctx,
                                                      emoji.emoji,
                                                    );
                                                  },
                                              config: const Config(),
                                            ),
                                          ),
                                        );
                                    if (reaction != null) {
                                      ref
                                          .read(chatControllerProvider.notifier)
                                          .reactToMessage(
                                            messageId: msg.id,
                                            emoji: reaction,
                                          );
                                    }
                                  } else if (selected == 'delete' && isMe) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete message?'),
                                        content: const Text(
                                          'This can\'t be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref
                                          .read(chatControllerProvider.notifier)
                                          .deleteMessage(msg.id);
                                    }
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:
                                      (msg.type == 'image' &&
                                          (msg.imageUrl?.isNotEmpty ?? false))
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                msg.imageUrl!,
                                                fit: BoxFit.cover,
                                                width: 220,
                                                height: 220,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      size: 48,
                                                    ),
                                              ),
                                            ),
                                            if ((msg.caption ?? msg.text)
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  msg.caption?.isNotEmpty ==
                                                          true
                                                      ? msg.caption!
                                                      : msg.text,
                                                ),
                                              ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (msg.replyTo != null &&
                                                msg.replyTo!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: _ReplyPreview(
                                                  replyToId: msg.replyTo!,
                                                  messages: chatState.messages,
                                                ),
                                              ),
                                            Text(msg.text),
                                            if (msg.reactions.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Wrap(
                                                  spacing: 6,
                                                  children: [
                                                    for (final entry
                                                        in msg
                                                            .reactions
                                                            .entries)
                                                      InkWell(
                                                        onTap: () {
                                                          final myId = me?.id;
                                                          if (myId == null)
                                                            return;
                                                          final hasReacted =
                                                              entry.value
                                                                  .contains(
                                                                    myId,
                                                                  );
                                                          final notifier = ref.read(
                                                            chatControllerProvider
                                                                .notifier,
                                                          );
                                                          if (hasReacted) {
                                                            notifier
                                                                .removeReaction(
                                                                  messageId:
                                                                      msg.id,
                                                                  emoji:
                                                                      entry.key,
                                                                );
                                                          } else {
                                                            notifier
                                                                .reactToMessage(
                                                                  messageId:
                                                                      msg.id,
                                                                  emoji:
                                                                      entry.key,
                                                                );
                                                          }
                                                        },
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                        child: Chip(
                                                          label: Text(
                                                            '${entry.key} ${entry.value.length}',
                                                          ),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          materialTapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                              ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: chatState.messages.length,
                        );
                      },
                    ),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  )
                : _messages.isEmpty
                ? const Center(child: Text('No messages yet. Say hello!'))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: msg.isMe
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg.text),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: _messages.length,
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _showEmoji = !_showEmoji),
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    tooltip: 'Emoji',
                  ),
                  IconButton(
                    onPressed: _pickAndSendImage,
                    icon: const Icon(Icons.photo_outlined),
                    tooltip: 'Send image',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      enabled: isApiBacked
                          ? !(chatState?.sending ?? false)
                          : !_sending,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed:
                        (isApiBacked
                                ? (chatState?.sending ?? false)
                                : _sending) ||
                            _textController.text.trim().isEmpty
                        ? null
                        : _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
          if (_replyToMessageId != null)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyPreviewText ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _replyToMessageId = null;
                        _replyPreviewText = null;
                      });
                      ref
                          .read(chatControllerProvider.notifier)
                          .setReplyTo(null);
                    },
                  ),
                ],
              ),
            ),
          Offstage(
            offstage: !_showEmoji,
            child: SizedBox(
              height: 280,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _textController.text += emoji.emoji;
                  _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length),
                  );
                },
                // Use default config to maximize compatibility across versions
                config: const Config(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  _ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.replyToId, required this.messages});
  final String replyToId;
  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    final replied = messages.cast<ChatMessage?>().firstWhere(
      (m) => m?.id == replyToId,
      orElse: () => null,
    );
    if (replied == null) {
      return Text('Replying…', style: Theme.of(context).textTheme.labelSmall);
    }
    final isImage =
        replied.type == 'image' && (replied.imageUrl?.isNotEmpty ?? false);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isImage)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.image,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          Flexible(
            child: Text(
              isImage
                  ? (replied.caption?.isNotEmpty == true
                        ? replied.caption!
                        : '[Image]')
                  : replied.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
