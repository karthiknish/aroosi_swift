import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/core/responsive.dart';
import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/platform/adaptive_feedback.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/paged_list_footer.dart';

import 'package:aroosi_flutter/widgets/empty_states.dart';
import 'package:aroosi_flutter/widgets/retryable_network_image.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';
import 'package:aroosi_flutter/widgets/offline_states.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/features/profiles/selection.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  final _scrollController = ScrollController();
  String? _currentSort;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchesControllerProvider.notifier).refresh();
    });
    addLoadMoreListener(
      _scrollController,
      threshold: 200,
      canLoadMore: () {
        final s = ref.read(matchesControllerProvider);
        return s.hasMore && !s.loading;
      },
      onLoadMore: () => ref.read(matchesControllerProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchesControllerProvider);

    // Handle matches controller errors
    ref.listen(matchesControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        final error = next.error.toString();
        final isOfflineError =
            error.toLowerCase().contains('network') ||
            error.toLowerCase().contains('connection') ||
            error.toLowerCase().contains('timeout');

        if (isOfflineError) {
          ToastService.instance.error('Connection error while loading matches');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error while loading matches'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () =>
                    ref.read(matchesControllerProvider.notifier).refresh(),
              ),
            ),
          );
        } else {
          ToastService.instance.error('Failed to load matches: $error');
        }
      }
    });

    if (!state.loading && state.error != null && state.items.isEmpty) {
      final error = state.error.toString();
      final isOfflineError =
          error.toLowerCase().contains('network') ||
          error.toLowerCase().contains('connection') ||
          error.toLowerCase().contains('timeout');

      return AppScaffold(
        title: 'Matches',
        child: isOfflineError
            ? OfflineState(
                title: 'No Connection',
                subtitle: 'Unable to load matches',
                description:
                    'Please check your internet connection and try again',
                onRetry: () =>
                    ref.read(matchesControllerProvider.notifier).refresh(),
              )
            : ErrorState(
                title: 'Failed to Load Matches',
                subtitle: 'Something went wrong',
                errorMessage: error,
                onRetryPressed: () =>
                    ref.read(matchesControllerProvider.notifier).refresh(),
              ),
      );
    }

    Widget buildGridSliver() {
      return Builder(
        builder: (context) {
          final columns = Responsive.gridColumns(context);
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: Responsive.isTablet(context) ? 3.2 / 4 : 3 / 4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (state.items.isEmpty && state.loading) {
                  return _MatchSkeleton();
                }
                if (index >= state.items.length) {
                  return PagedListFooter(
                    hasMore: state.hasMore,
                    isLoading: state.loading,
                  );
                }
                final match = state.items[index];
                final itemDelay = Duration(
                  milliseconds:
                      (AppMotionDurations.fast.inMilliseconds ~/ 2) *
                      (index % 6),
                );
                return FadeSlideIn(
                  duration: AppMotionDurations.short,
                  delay: itemDelay,
                  beginOffset: const Offset(0, 0.08),
                  child: MotionPressable(
                    onPressed: () {
                      if (!_canViewProfile()) return;
                      // All features are now free - no usage tracking needed

                      // For mutual matches, navigate to conversation
                      if (match.isMutual && match.conversationId.isNotEmpty) {
                        // Mark conversation as read when opening
                        ref
                            .read(matchesControllerProvider.notifier)
                            .markConversationAsRead(match.conversationId);
                        context.push('/chat/${match.conversationId}');
                      } else {
                        // For non-mutual matches, navigate to profile
                        final targetUserId =
                            match.otherUserId ??
                            (match.user1Id == match.user2Id
                                ? match.user1Id
                                : (match.user1Id.isNotEmpty
                                      ? match.user1Id
                                      : match.user2Id));
                        ref
                            .read(lastSelectedProfileIdProvider.notifier)
                            .set(targetUserId);
                        context.push('/details/$targetUserId');
                      }
                    },
                    onLongPress: () async {
                      final ctx = context;
                      final targetUserId =
                          match.otherUserId ??
                          (match.user1Id == match.user2Id
                              ? match.user1Id
                              : (match.user1Id.isNotEmpty
                                    ? match.user1Id
                                    : match.user2Id));

                      final action = await showAdaptiveActionSheet(
                        ctx,
                        title: match.otherUserName ?? 'Match',
                        actions: [
                          if (!match.isMutual) 'Send Interest',
                          'View Profile',
                          if (match.isMutual && match.conversationId.isNotEmpty)
                            'Open Chat',
                        ],
                      );

                      if (action == null) return;

                      if (action == 0 && !match.isMutual) {
                        // Send interest
                        final result = await ref
                            .read(matchesControllerProvider.notifier)
                            .sendInterest(targetUserId);
                        if (result['success'] == true) {
                          ToastService.instance.success(
                            'Interest sent to ${match.otherUserName ?? 'match'}',
                          );
                        } else {
                          final error =
                              result['error'] as String? ??
                              'Failed to send interest';
                          ToastService.instance.error(error);
                        }
                      } else if ((action == 0 && match.isMutual) ||
                          (action == 1 && !match.isMutual)) {
                        // View profile
                        ref
                            .read(lastSelectedProfileIdProvider.notifier)
                            .set(targetUserId);
                        context.push('/details/$targetUserId');
                      } else if ((action == 1 && match.isMutual) ||
                          (action == 2)) {
                        // Open chat
                        if (match.conversationId.isNotEmpty) {
                          ref
                              .read(matchesControllerProvider.notifier)
                              .markConversationAsRead(match.conversationId);
                          context.push('/chat/${match.conversationId}');
                        }
                      }
                    },
                    child: _MatchCard(match: match),
                  ),
                );
              },
              childCount: state.items.isEmpty && state.loading
                  ? 6
                  : state.items.length + (state.hasMore ? 1 : 0),
            ),
          );
        },
      );
    }

    final content = AdaptiveRefresh(
      onRefresh: () async {
        await ref.read(matchesControllerProvider.notifier).refresh();
        ToastService.instance.success('Matches refreshed');
      },
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildMatchesHero(context, state),
          ),
        ),
        if (state.items.isEmpty && !state.loading)
          SliverToBoxAdapter(
            child: EmptyMatchesState(
              onExplore: () => context.push('/home/search'),
              onImproveProfile: () => context.push('/main/edit-profile'),
            ),
          )
        else
          buildGridSliver(),
      ],
    );

    return AppScaffold(title: 'Matches', child: content);
  }

  Widget _buildMatchesHero(BuildContext context, MatchesState state) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(56),
            AppColors.secondary.withAlpha(46),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(36),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Matches',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover meaningful connections and build lasting relationships with people who share your values.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(184),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortDropdown(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown(ThemeData theme) {
    final options = <Map<String, Object?>>[
      {'value': null, 'label': 'Default Order'},
      {'value': 'recent', 'label': 'Recently Active'},
      {'value': 'newest', 'label': 'Newest First'},
      {'value': 'distance', 'label': 'Nearest First'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(229),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(31)),
      ),
      child: DropdownButton<String?>(
        value: _currentSort,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.sort, color: AppColors.primary),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        dropdownColor: theme.colorScheme.surface,
        items: options.map((option) {
          return DropdownMenuItem<String?>(
            value: option['value'] as String?,
            child: Text(option['label'] as String),
          );
        }).toList(),
        onChanged: (value) {
          _onSortSelected(value);
        },
      ),
    );
  }

  void _onSortSelected(String? value) {
    if (_currentSort == value) return;
    setState(() {
      _currentSort = value;
    });
    ref.read(matchesControllerProvider.notifier).refresh();
  }

  bool _canViewProfile() {
    // All features are now free - no usage tracking needed
    return true;
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchEntry match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = (match.otherUserName ?? 'Match').trim();
    final name = displayName.isEmpty ? 'Match' : displayName;
    final accent = _accentColor;
    final backgroundUrl = match.otherUserImage;
    final lastInteraction = match.lastMessageAt ?? match.createdAt;
    final statusLabel = _statusLabel();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: backgroundUrl != null
                ? RetryableNetworkImage(
                    url: backgroundUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(color: accent.withAlpha(20)),
                    errorWidget: Container(
                      color: accent.withAlpha(31),
                      child: Center(
                        child: Icon(
                          Icons.favorite_outline,
                          color: accent.withAlpha(153),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent.withAlpha(46), accent.withAlpha(13)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(166),
                    Colors.black.withAlpha(26),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          if (!match.isBlocked) ...[
            Positioned(
              top: 16,
              left: 16,
              child: _buildStatusChip(statusLabel, accent),
            ),
          ],
          if (match.isBlocked)
            Positioned(
              top: 16,
              left: 16,
              child: _buildBadge('Blocked', Colors.grey.shade600),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(179),
                    Colors.black.withAlpha(51),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (match.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            match.unreadCount > 99
                                ? '99+'
                                : '${match.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        match.isMutual ? Icons.favorite : Icons.person,
                        size: 14,
                        color: match.isMutual
                            ? Colors.pinkAccent
                            : Colors.white.withAlpha(191),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          match.isMutual ? 'Mutual Match' : 'Potential Match',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha(191),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.white.withAlpha(153),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRelativeTime(lastInteraction),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(153),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if ((match.lastMessageText ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${match.lastMessageText!.trim()}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(224),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(115),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(31)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            match.isMutual ? Icons.favorite : Icons.auto_awesome,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(46),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    if (match.isMutual) return 'Mutual match';
    switch (match.status) {
      case 'pending':
        return 'Awaiting response';
      case 'accepted':
        return 'Accepted match';
      case 'blocked':
        return 'Blocked';
      default:
        return match.status.replaceAll('_', ' ');
    }
  }

  String _formatRelativeTime(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Color get _accentColor {
    if (match.isMutual) return Colors.pinkAccent;
    if (match.status == 'pending') return Colors.teal;
    if (match.isBlocked) return Colors.grey;
    return AppColors.primary;
  }
}

class _MatchSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final hilite = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Background image placeholder
          Positioned.fill(child: Container(color: base.withAlpha(102))),
          // Status chip placeholder
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: hilite.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Bottom content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(179),
                    Colors.black.withAlpha(51),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name placeholder
                  Container(
                    width: 120,
                    height: 20,
                    color: hilite.withAlpha(128),
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  // Status and time row
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: hilite.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 80,
                        height: 12,
                        color: hilite.withAlpha(128),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: hilite.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 40,
                        height: 12,
                        color: hilite.withAlpha(128),
                      ),
                    ],
                  ),
                  // Message preview placeholder (sometimes shown)
                  if (DateTime.now().millisecond % 3 == 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 14,
                      color: hilite.withAlpha(102),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
