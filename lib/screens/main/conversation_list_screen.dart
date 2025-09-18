import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/features/chat/conversation_list_controller.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationListControllerProvider);
    ref.listen(conversationListControllerProvider, (prev, next) {
      // No-op for now; could show toasts on errors.
    });

    return AppScaffold(
      title: 'Conversations',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final controller = ref.read(
            conversationListControllerProvider.notifier,
          );
          final userId = await showDialog<String>(
            context: context,
            builder: (context) {
              final textController = TextEditingController();
              return AlertDialog(
                title: const Text('Start new message'),
                content: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'Enter user ID or email',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(textController.text.trim()),
                    child: const Text('Start'),
                  ),
                ],
              );
            },
          );
          if (userId != null && userId.isNotEmpty) {
            try {
              final convId = await controller.createConversationWith(userId);
              if (context.mounted) {
                context.push(
                  '/main/chat?conversationId=${Uri.encodeComponent(convId)}&toUserId=${Uri.encodeComponent(userId)}',
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to create conversation'),
                  ),
                );
              }
            }
          }
        },
        child: const Icon(Icons.chat),
      ),
      child: AdaptiveRefresh(
        onRefresh: () =>
            ref.read(conversationListControllerProvider.notifier).refresh(),
        child: Builder(
          builder: (context) {
            if (state.loading && state.items.isEmpty) {
              return Center(
                child: FadeScaleIn(
                  duration: AppMotionDurations.medium,
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            if (state.error != null) {
              return FadeIn(
                duration: AppMotionDurations.short,
                child: Center(
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              );
            }
            if (state.items.isEmpty) {
              // Trigger initial load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(conversationListControllerProvider.notifier).load();
              });
              return const FadeIn(
                duration: AppMotionDurations.short,
                child: Center(child: Text('No conversations yet.')),
              );
            }
            int tileIndex = 0;
            return FadeThrough(
              delay: AppMotionDurations.fast,
              child: ListView.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conv = state.items[index];
                  final title = conv.partnerName ?? 'Conversation';
                  final subtitle = conv.lastMessage?.text ?? 'Tap to open chat';
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 60 * (tileIndex++)),
                    beginOffset: const Offset(0, 0.04),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            conv.partnerAvatarUrl != null &&
                                conv.partnerAvatarUrl!.isNotEmpty
                            ? NetworkImage(conv.partnerAvatarUrl!)
                            : null,
                        child:
                            (conv.partnerAvatarUrl == null ||
                                conv.partnerAvatarUrl!.isEmpty)
                            ? Text(
                                title.isNotEmpty
                                    ? title
                                          .trim()
                                          .split(' ')
                                          .map((w) => w.isNotEmpty ? w[0] : '')
                                          .take(2)
                                          .join()
                                          .toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(title),
                      subtitle: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: conv.unreadCount > 0
                          ? CircleAvatar(
                              radius: 10,
                              child: Text(
                                '${conv.unreadCount}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          : null,
                      onTap: () => context.push(
                        '/main/chat?conversationId=${Uri.encodeComponent(conv.id)}${conv.partnerId != null ? '&toUserId=${Uri.encodeComponent(conv.partnerId!)}' : ''}',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
