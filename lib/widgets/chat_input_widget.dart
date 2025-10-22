import 'package:flutter/cupertino.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/core/permissions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:aroosi_flutter/features/engagement/icebreaker_service.dart';

/// Enhanced chat input widget with modern UI/UX
class ChatInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback? onImagePick;
  final VoidCallback? onVoiceRecord;
  final bool isSending;
  final bool canSendImage;
  final bool canSendVoice;

  const ChatInputWidget({
    super.key,
    required this.textController,
    required this.onSend,
    this.onImagePick,
    this.onVoiceRecord,
    this.isSending = false,
    this.canSendImage = true,
    this.canSendVoice = true,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _isRecording = false;
  bool _showEmoji = false;
  bool _showIcebreakers = false;
  List<IcebreakerQuestion> _icebreakers = [];
  bool _loadingIcebreakers = false;
  late final IcebreakerService _icebreakerService;

  @override
  void initState() {
    super.initState();
    _icebreakerService = IcebreakerService();
    _loadIcebreakers();
  }

  Future<void> _loadIcebreakers() async {
    if (_loadingIcebreakers) return;

    setState(() => _loadingIcebreakers = true);
    try {
      final icebreakers = await _icebreakerService.getDailyIcebreakers();
      setState(() {
        _icebreakers = icebreakers.where((i) => !i.answered).toList();
        _loadingIcebreakers = false;
      });
    } catch (e) {
      setState(() => _loadingIcebreakers = false);
    }
  }

  void _handleEmojiSelected() {
    // Hide emoji picker after selection
    setState(() {
      _showEmoji = false;
    });
  }

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
      _showIcebreakers = false;
    });
  }

  void _toggleIcebreakers() {
    setState(() {
      _showIcebreakers = !_showIcebreakers;
      _showEmoji = false;
    });
  }

  void _selectIcebreaker(IcebreakerQuestion icebreaker) {
    widget.textController.text = icebreaker.text;
    setState(() {
      _showIcebreakers = false;
    });
  }

  void _pickImage() async {
    final ok = await AppPermissions.ensurePhotoAccess();
    if (!ok) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        widget.onImagePick?.call();
      }
    } catch (e) {
      // Handle error
    }
  }

  void _toggleVoice() {
    setState(() {
      _isRecording = !_isRecording;
    });
    widget.onVoiceRecord?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.textController.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icebreaker picker
        if (_showIcebreakers)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: AppColors.borderPrimary)),
            ),
            child: _loadingIcebreakers
                ? const Center(child: CircularProgressIndicator())
                : _icebreakers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 48,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No conversation starters available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _icebreakers.length,
                    itemBuilder: (context, index) {
                      final icebreaker = _icebreakers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          title: Text(
                            icebreaker.text,
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: const Icon(Icons.add, size: 16),
                          onTap: () => _selectIcebreaker(icebreaker),
                        ),
                      );
                    },
                  ),
          ),

        // Emoji picker
        if (_showEmoji)
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: AppColors.borderPrimary)),
            ),
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                final text = widget.textController.text;
                final selection = widget.textController.selection;
                widget.textController.text = text.replaceRange(
                  selection.start,
                  selection.end,
                  emoji.emoji,
                );
                widget.textController.selection = TextSelection.collapsed(
                  offset: selection.start + emoji.emoji.length,
                );
                _handleEmojiSelected();
              },
              config: const Config(),
            ),
          ),

        // Main input container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: AppColors.borderPrimary)),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Icebreaker button
                IconButton(
                  onPressed: _toggleIcebreakers,
                  icon: Icon(
                    _showIcebreakers ? Icons.keyboard : Icons.lightbulb_outline,
                    color: _showIcebreakers
                        ? theme.colorScheme.primary
                        : AppColors.muted,
                  ),
                  tooltip: _showIcebreakers
                      ? 'Hide conversation starters'
                      : 'Conversation starters',
                ),

                const SizedBox(width: 4),

                // Emoji button
                IconButton(
                  onPressed: _toggleEmoji,
                  icon: Icon(
                    _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: _showEmoji
                        ? theme.colorScheme.primary
                        : AppColors.muted,
                  ),
                  tooltip: _showEmoji ? 'Hide emoji' : 'Emoji',
                ),

                const SizedBox(width: 4),

                // Image button
                if (widget.canSendImage)
                  IconButton(
                    onPressed: _pickImage,
                    icon: Icon(Icons.photo_outlined, color: AppColors.muted),
                    tooltip: 'Send image',
                  ),

                const SizedBox(width: 4),

                // Voice button
                if (widget.canSendVoice)
                  IconButton(
                    onPressed: _toggleVoice,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isRecording
                          ? Icon(
                              Icons.stop_circle,
                              key: const ValueKey('stop'),
                              color: AppColors.error,
                            )
                          : Icon(
                              Icons.mic,
                              key: const ValueKey('mic'),
                              color: AppColors.muted,
                            ),
                    ),
                    tooltip: _isRecording ? 'Stop recording' : 'Voice message',
                  ),

                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(128),
                        width: 1.0,
                      ),
                    ),
                    child: CupertinoTextField(
                      controller: widget.textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: hasText ? (_) => widget.onSend() : null,
                      maxLines: null,
                      enabled: !widget.isSending && !_isRecording,
                      placeholder: _isRecording
                          ? 'Recording...'
                          : 'Type a message...',
                      placeholderStyle: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.copyWith(color: AppColors.muted),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasText && !widget.isSending
                        ? theme.colorScheme.primary
                        : AppColors.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: hasText && !widget.isSending
                        ? widget.onSend
                        : null,
                    icon: widget.isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            color: hasText && !widget.isSending
                                ? theme.colorScheme.onPrimary
                                : AppColors.muted,
                            size: 20,
                          ),
                    tooltip: 'Send message',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Voice recording widget with visual feedback
class VoiceRecordingWidget extends StatefulWidget {
  final VoidCallback onStop;
  final VoidCallback? onCancel;
  final bool isRecording;

  const VoiceRecordingWidget({
    super.key,
    required this.onStop,
    this.onCancel,
    this.isRecording = false,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Recording indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(
                    alpha: 0.3 + (_pulseAnimation.value - 1.0) * 0.7,
                  ),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Recording...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Cancel button
          TextButton(
            onPressed: widget.onCancel,
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Stop button
          ElevatedButton.icon(
            onPressed: widget.onStop,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat input loading state
class ChatInputLoadingWidget extends StatelessWidget {
  const ChatInputLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Text('Loading...')),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
