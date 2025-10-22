import 'package:flutter/material.dart';
import 'package:aroosi_flutter/features/chat/chat_models.dart';
import 'package:aroosi_flutter/features/chat/delivery_receipt_service.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/widgets/voice_message_bubble.dart';

/// Enhanced chat message widget with modern UI/UX
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final VoidCallback? onReactionTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onImageTap;
  final VoidCallback? onVoiceTap;
  final DeliveryReceipt? deliveryReceipt;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.onReactionTap,
    this.onLongPress,
    this.onImageTap,
    this.onVoiceTap,
    this.deliveryReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.isMine;
    final messageColor = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Timestamp (if enabled and first message of group)
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
            ),

          // Message content
          GestureDetector(
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isMe
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : AppColors.borderPrimary,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: _buildMessageContent(context),
            ),
          ),

          // Read receipt and reactions
          if (isMe || message.hasReactions)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Read receipt
                  if (isMe) ...[
                    _buildDeliveryReceipt(context),
                    if (message.hasReactions) const SizedBox(width: 4),
                  ],

                  // Reactions
                  if (message.hasReactions) ...[
                    _buildReactionsRow(context),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {

    switch (message.type) {
      case 'image':
        return _buildImageMessage(context);
      case 'voice':
        return VoiceMessageBubble(message: message);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (message.hasReactions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildReactionsRow(context),
          ),
      ],
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return GestureDetector(
      onTap: onImageTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          maxHeight: 300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.imageUrl ?? message.text,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: AppColors.surfaceSecondary,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: AppColors.surfaceSecondary,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: AppColors.muted,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryReceipt(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use delivery receipt if available, otherwise fall back to message.isRead
    final status = deliveryReceipt?.status;
    final isRead = status == DeliveryStatus.read || message.isRead;
    final isDelivered = status == DeliveryStatus.delivered || status == null;
    
    if (isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 2),
          Text(
            'Read',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    } else if (isDelivered) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done,
            size: 14,
            color: AppColors.muted,
          ),
          const SizedBox(width: 2),
          Text(
            'Delivered',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.muted,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: AppColors.muted,
          ),
          const SizedBox(width: 2),
          Text(
            'Sending...',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.muted,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildReactionsRow(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 4,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value.length;

        return GestureDetector(
          onTap: () => onReactionTap?.call(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              '$emoji $count',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Chat message loading skeleton
class ChatMessageSkeleton extends StatelessWidget {
  const ChatMessageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Message skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text line 1
                Container(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                // Text line 2
                Container(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Typing indicator widget
class TypingIndicator extends StatelessWidget {
  final String userName;
  final bool isOnline;

  const TypingIndicator({
    super.key,
    required this.userName,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 12,
            backgroundColor: isOnline
                ? theme.colorScheme.primary
                : AppColors.muted,
            child: Text(
              userName.isNotEmpty ? userName[0] : '?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Typing animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotAnimation(),
                _DotAnimation(delay: 200),
                _DotAnimation(delay: 400),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Typing...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;

  const _DotAnimation({this.delay = 0});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.3 + (_animation.value * 0.7),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
