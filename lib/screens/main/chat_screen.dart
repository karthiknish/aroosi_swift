import 'package:flutter/material.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/core/toast_helpers.dart';
import 'package:aroosi_flutter/features/chat/chat_controller.dart';
import 'package:aroosi_flutter/features/chat/chat_models.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/widgets/empty_states.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';
import 'package:aroosi_flutter/widgets/chat_message_widget.dart';
import 'package:aroosi_flutter/widgets/chat_input_widget.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aroosi_flutter/core/permissions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:aroosi_flutter/features/chat/typing_presence_controller.dart';
import 'package:aroosi_flutter/core/realtime/realtime_service.dart';
import 'package:aroosi_flutter/widgets/offline_states.dart';

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
      ref.showInfo('Type a message');
      return;
    }
    final isApiBacked =
        widget.conversationId != null && widget.conversationId!.isNotEmpty;
    if (isApiBacked) {
      final allowed = ref
          .read(featureUsageControllerProvider.notifier)
          .requestUsage(UsageMetric.messageSent);
      if (!allowed) {
        ref.showWarning(
          'You\'ve reached your monthly message limit. Upgrade to Premium for unlimited messages.',
        );
        return;
      }
      try {
        await ref
            .read(chatControllerProvider.notifier)
            .send(text, toUserId: widget.toUserId);
        _textController.clear();
        // No need to manage emoji state here anymore
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        ref.showSuccess('Message sent');
      } catch (e) {
        ref.showError(e, 'Failed to send message');
      }
      return;
    }
    setState(() => _sending = true);
    final allowed = ref
        .read(featureUsageControllerProvider.notifier)
        .requestUsage(UsageMetric.messageSent);
    if (!allowed) {
      ref.showWarning(
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
      ref.showSuccess('Message sent');
    } catch (e) {
      setState(() {
        _sending = false;
        _error = 'Failed to send message. Please try again.';
      });
      ref.showError(e, 'Failed to send message');
    }
  }

  Future<void> _pickAndSendImage() async {
    final isApiBacked =
        widget.conversationId != null && widget.conversationId!.isNotEmpty;
    if (!isApiBacked) {
      ref.showInfo('Start a conversation to send images.');
      return;
    }
    final ok = await AppPermissions.ensurePhotoAccess();
    if (!ok) return;
    final allowed = ref
        .read(featureUsageControllerProvider.notifier)
        .requestUsage(UsageMetric.messageSent);
    if (!allowed) {
      ref.showWarning('Upgrade to send image messages.');
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
      ref.showSuccess('Image sent');
    } catch (e) {
      ref.showError(e, 'Failed to send image');
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

    // Handle chat controller errors
    ref.listen(chatControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        final error = next.error.toString();
        final isOfflineError = error.toLowerCase().contains('network') ||
                              error.toLowerCase().contains('connection') ||
                              error.toLowerCase().contains('timeout');

        if (isOfflineError) {
          ref.showNetworkError(
            operation: 'load chat messages',
            onRetry: () => ref.read(chatControllerProvider.notifier).refresh(),
          );
        } else {
          ref.showError(error, 'Failed to load chat messages');
        }
      }
    });

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
          if (isApiBacked && tpState != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: (_typing || tpState.isTyping)
                  ? TypingIndicator(
                      key: const ValueKey('typing'),
                      userName: 'User',
                      isOnline: tpState.isOnline,
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
                          final error = chatState!.error.toString();
                          final isOfflineError = error.toLowerCase().contains('network') ||
                                                error.toLowerCase().contains('connection') ||
                                                error.toLowerCase().contains('timeout');

                          return isOfflineError
                              ? OfflineState(
                                  title: 'Connection Lost',
                                  subtitle: 'Unable to load messages',
                                  description: 'Check your internet connection and try again',
                                  onRetry: () => ref.read(chatControllerProvider.notifier).refresh(),
                                )
                              : ErrorState(
                                  title: 'Failed to Load Messages',
                                  subtitle: 'Something went wrong',
                                  errorMessage: error,
                                  onRetryPressed: () => ref.read(chatControllerProvider.notifier).refresh(),
                                );
                        }
                        if (chatState == null ||
                            (chatState.loading && chatState.messages.isEmpty)) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (chatState.messages.isEmpty) {
                          return const EmptyChatState();
                        }
                        return ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final ChatMessage msg = chatState.messages[index];
                            final isMe =
                                msg.isMine == true ||
                                (me != null && (msg.fromUserId == me.id));

                            return ChatMessageWidget(
                              message: msg,
                              onReactionTap: () async {
                                // Open emoji picker for reactions
                                final reaction = await showModalBottomSheet<String>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (ctx) => SizedBox(
                                    height: 360,
                                    child: EmojiPicker(
                                      onEmojiSelected: (category, emoji) {
                                        Navigator.of(ctx).pop(emoji.emoji);
                                      },
                                      config: const Config(),
                                    ),
                                  ),
                                );
                                if (reaction != null && reaction.isNotEmpty) {
                                  ref
                                      .read(chatControllerProvider.notifier)
                                      .reactToMessage(
                                        messageId: msg.id,
                                        emoji: reaction,
                                      );
                                }
                              },
                              onLongPress: () async {
                                if (isMe) {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete message?'),
                                      content: const Text(
                                        'This can\'t be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
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
                              onImageTap: () {
                                // Handle image tap - could show full screen image
                                debugPrint('Image tapped: ${msg.imageUrl ?? msg.text}');
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemCount: chatState.messages.length,
                        );
                      },
                    ),
                  )
                : _error != null
                ? ErrorState(
                    title: 'Message Error',
                    subtitle: 'Failed to send message',
                    errorMessage: _error,
                    onRetryPressed: _send,
                  )
                : _messages.isEmpty
                ? const EmptyChatState()
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatMessageWidget(
                        message: ChatMessage(
                          id: 'local_$index',
                          conversationId: widget.conversationId ?? '',
                          fromUserId: 'local',
                          text: msg.text,
                          type: 'text',
                          createdAt: msg.timestamp,
                          isMine: msg.isMe,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: _messages.length,
                  ),
          ),
          ChatInputWidget(
            textController: _textController,
            onSend: _send,
            onImagePick: _pickAndSendImage,
            isSending: isApiBacked ? (chatState?.sending ?? false) : _sending,
            canSendImage: isApiBacked,
            canSendVoice: isApiBacked,
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


