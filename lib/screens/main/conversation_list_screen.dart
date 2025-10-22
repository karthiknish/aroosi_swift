import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/widgets/empty_states.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';
import 'package:aroosi_flutter/widgets/offline_states.dart';
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
              final error = state.error.toString();
              final isOfflineError =
                  error.toLowerCase().contains('network') ||
                  error.toLowerCase().contains('connection') ||
                  error.toLowerCase().contains('timeout');

              return FadeIn(
                duration: AppMotionDurations.short,
                child: isOfflineError
                    ? OfflineState(
                        title: 'Connection Lost',
                        subtitle: 'Unable to load conversations',
                        description:
                            'Check your internet connection and try again',
                        onRetry: () => ref
                            .read(conversationListControllerProvider.notifier)
                            .refresh(),
                      )
                    : ErrorState(
                        title: 'Failed to Load Conversations',
                        subtitle: 'Something went wrong',
                        errorMessage: error,
                        onRetryPressed: () => ref
                            .read(conversationListControllerProvider.notifier)
                            .refresh(),
                      ),
              );
            }
            if (state.items.isEmpty) {
              // Trigger initial load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(conversationListControllerProvider.notifier).load();
              });
              return FadeIn(
                duration: AppMotionDurations.short,
                child: EmptyChatState(
                  onExplore: () => context.push('/home/search'),
                ),
              );
            }
            return ListView.separated(
                itemCount: state.items.length,
                shrinkWrap: true,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conv = state.items[index];
                  final title = conv.partnerName;
                  final subtitle = conv.lastMessageText ?? 'Tap to open chat';
                  return ListTile(
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
                        '/main/chat?conversationId=${Uri.encodeComponent(conv.id)}${'&toUserId=${Uri.encodeComponent(conv.partnerId)}'}',
                      ),
                    );
                },
              );
          },
        ),
      ),
    );
  }
}
