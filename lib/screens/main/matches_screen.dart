import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/features/subscription/subscription_models.dart';
import 'package:aroosi_flutter/platform/adaptive_feedback.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/shimmer.dart';
import 'package:aroosi_flutter/widgets/paged_list_footer.dart';
import 'package:aroosi_flutter/widgets/inline_upgrade_banner.dart';
import 'package:aroosi_flutter/widgets/empty_states.dart';
import 'package:aroosi_flutter/widgets/retryable_network_image.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';
import 'package:aroosi_flutter/widgets/offline_states.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/core/toast_helpers.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/features/profiles/selection.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
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
      onLoadMore: () => ref
          .read(matchesControllerProvider.notifier)
          .loadMore(),
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
    final access = ref.watch(featureAccessProvider);
    final isFreePlan = access.plan == SubscriptionPlan.free;

    // Handle matches controller errors
    ref.listen(matchesControllerProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        final error = next.error.toString();
        final isOfflineError = error.toLowerCase().contains('network') ||
                              error.toLowerCase().contains('connection') ||
                              error.toLowerCase().contains('timeout');

        if (isOfflineError) {
          ref.showNetworkError(
            operation: 'load matches',
            onRetry: () => ref.read(matchesControllerProvider.notifier).refresh(),
          );
        } else {
          ref.showError(error, 'Failed to load matches');
        }
      }
    });

    if (!state.loading && state.error != null && state.items.isEmpty) {
      final error = state.error.toString();
      final isOfflineError = error.toLowerCase().contains('network') ||
                            error.toLowerCase().contains('connection') ||
                            error.toLowerCase().contains('timeout');

      return AppScaffold(
        title: 'Matches',
        child: isOfflineError
            ? OfflineState(
                title: 'No Connection',
                subtitle: 'Unable to load matches',
                description: 'Please check your internet connection and try again',
                onRetry: () => ref
                    .read(matchesControllerProvider.notifier)
                    .refresh(),
              )
            : ErrorState(
                title: 'Failed to Load Matches',
                subtitle: 'Something went wrong',
                errorMessage: error,
                onRetryPressed: () => ref
                    .read(matchesControllerProvider.notifier)
                    .refresh(),
              ),
      );
    }

    SliverGrid buildGridSliver() {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3 / 4,
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
                  (AppMotionDurations.fast.inMilliseconds ~/ 2) * (index % 6),
            );
            return FadeSlideIn(
              duration: AppMotionDurations.short,
              delay: itemDelay,
              beginOffset: const Offset(0, 0.08),
              child: MotionPressable(
                onPressed: () {
                  if (!_canViewProfile()) return;
                  if (!_requestUsage(UsageMetric.profileView)) return;
                  
                  // For mutual matches, navigate to conversation
                  if (match.isMutual && match.conversationId.isNotEmpty) {
                    // Mark conversation as read when opening
                    ref.read(matchesControllerProvider.notifier)
                        .markConversationAsRead(match.conversationId);
                    context.push('/chat/${match.conversationId}');
                  } else {
                    // For non-mutual matches, navigate to profile
                    final targetUserId = match.otherUserId ?? 
                        (match.user1Id == match.user2Id ? match.user1Id : 
                         (match.user1Id.isNotEmpty ? match.user1Id : match.user2Id));
                    ref
                        .read(lastSelectedProfileIdProvider.notifier)
                        .set(targetUserId);
                    context.push('/details/$targetUserId');
                  }
                },
                onLongPress: () async {
                  if (!_requestUsage(UsageMetric.interestSent)) return;
                  final ctx = context;
                  final action = await showAdaptiveActionSheet(
                    ctx,
                    title: match.otherUserName ?? 'Match',
                    actions: const [
                      'Send interest',
                      'Favorite / Unfavorite',
                      'Shortlist / Unshortlist',
                    ],
                  );
                  if (action == null) return;
                  final targetUserId = match.otherUserId ?? 
                      (match.user1Id == match.user2Id ? match.user1Id : 
                       (match.user1Id.isNotEmpty ? match.user1Id : match.user2Id));
                  if (action == 0) {
                    if (!_requestUsage(UsageMetric.interestSent)) return;
                    final result = await ref
                        .read(matchesControllerProvider.notifier)
                        .sendInterest(targetUserId);
                    if (result['success'] == true) {
                      ref.showSuccess('Interest sent to ${match.otherUserName ?? 'match'}');
                    } else {
                      final error = result['error'] as String? ?? 'Failed to send interest';
                      final isPlanLimit = result['isPlanLimit'] == true;
                      if (isPlanLimit) {
                        ref.showWarning('Upgrade to send more interests');
                      } else {
                        ref.showError(error, 'Failed to send interest');
                      }
                    }
                  } else if (action == 1) {
                    // Favorite functionality would need to be added to MatchesController
                    ref.showInfo('Favorite feature coming soon');
                  } else if (action == 2) {
                    // Shortlist functionality would need to be added to MatchesController
                    ref.showInfo('Shortlist feature coming soon');
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
    }

    final content = AdaptiveRefresh(
      onRefresh: () async {
        await ref
            .read(matchesControllerProvider.notifier)
            .refresh();
        ref.showSuccess('Matches refreshed');
      },
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (isFreePlan)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InlineUpgradeBanner(
                message:
                    'Upgrade to Premium to unlock unlimited likes and view full profiles.',
                ctaLabel: 'Upgrade to Premium',
                onPressed: () => context.push('/main/subscription'),
              ),
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

    return AppScaffold(
      title: 'Matches',
      actions: [
        IconButton(
          onPressed: () async {
            final access = ref.read(featureAccessProvider);
            if (!access.can(SubscriptionFeatureFlag.canUseAdvancedFilters)) {
              _showUpgradeToast(SubscriptionFeatureFlag.canUseAdvancedFilters);
              return;
            }
            final ctx = context;
            final selection = await showAdaptiveActionSheet(
              ctx,
              title: 'Sort by',
              actions: const ['Recently active', 'Newest', 'Distance'],
            );
            setState(() {
              switch (selection) {
                case 0:
                  _currentSort = 'recent';
                  break;
                case 1:
                  _currentSort = 'newest';
                  break;
                case 2:
                  _currentSort = 'distance';
                  break;
                default:
                  break;
              }
            });
            if (selection != null) {
              await ref
                  .read(matchesControllerProvider.notifier)
                  .refresh();
              ref.showSuccess('Sort applied');
            }
          },
          icon: const Icon(Icons.sort),
        ),
      ],
      child: content,
    );
  }

  bool _canViewProfile() {
    final access = ref.read(featureAccessProvider);
    if (access.can(SubscriptionFeatureFlag.canViewFullProfiles)) {
      return true;
    }
    _showUpgradeToast(SubscriptionFeatureFlag.canViewFullProfiles);
    return false;
  }

  bool _requestUsage(UsageMetric metric) {
    final controller = ref.read(featureUsageControllerProvider.notifier);
    final allowed = controller.requestUsage(metric);
    if (!allowed) {
      _showUsageLimitMessage(metric);
    }
    return allowed;
  }

  void _showUsageLimitMessage(UsageMetric metric) {
    final usageState = ref.read(featureUsageControllerProvider);
    final access = ref.read(featureAccessProvider);
    final limit = access.usageLimit(metric);
    final used = usageState.count(metric);

    final featureMapping = {
      UsageMetric.profileView: SubscriptionFeatureFlag.canViewFullProfiles,
      UsageMetric.interestSent: SubscriptionFeatureFlag.canSendUnlimitedLikes,
      UsageMetric.profileBoostUsed: SubscriptionFeatureFlag.canBoostProfile,
      UsageMetric.searchPerformed:
          SubscriptionFeatureFlag.canUseAdvancedFilters,
      UsageMetric.messageSent: SubscriptionFeatureFlag.canInitiateChat,
      UsageMetric.voiceMessageSent: SubscriptionFeatureFlag.canChatWithMatches,
    };

    final feature = featureMapping[metric];
    final planLabel = feature != null
        ? access.requiredPlanLabel(feature)
        : 'Premium';
    final limitDescription = limit > 0
        ? '$used / $limit used'
        : 'limit reached';

    ref.showWarning(
      'You\'ve reached your $limitDescription. Upgrade to $planLabel to keep going.',
    );
  }

  void _showUpgradeToast(SubscriptionFeatureFlag feature) {
    final access = ref.read(featureAccessProvider);
    final planLabel = access.requiredPlanLabel(feature);
    ref.showWarning('Upgrade to $planLabel to use this feature.');
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchEntry match;

  @override
  Widget build(BuildContext context) {
    final displayName = match.otherUserName ?? 'Match';
    final avatarUrl = match.otherUserImage;
    
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                child: avatarUrl != null
                    ? ClipOval(
                        child: RetryableNetworkImage(
                          url: avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: Colors.grey[200],
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName.characters.first
                                  : '?',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName.characters.first
                              : '?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(displayName, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              if (match.lastMessageText != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    match.lastMessageText!,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (match.status != 'matched')
                Text(
                  match.status,
                  style: TextStyle(
                    fontSize: 10,
                    color: match.status == 'pending' ? Colors.orange : Colors.green,
                  ),
                ),
              if (match.isMutual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Mutual Match',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          // Unread message indicator
          if (match.unreadCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  match.unreadCount > 99 ? '99+' : match.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Blocked indicator
          if (match.isBlocked)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Blocked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final hilite = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _GridSkeleton(base: base, hilite: hilite),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({required this.base, required this.hilite});
  final Color base;
  final Color hilite;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final dx = rect.width * value;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, hilite, base],
              stops: const [0.2, 0.5, 0.8],
              transform: GradientTranslation(dx, 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: base, shape: BoxShape.circle),
              ),
              const SizedBox(height: 12),
              Container(height: 14, width: 96, color: base),
              const SizedBox(height: 6),
              Container(height: 12, width: 72, color: hilite),
            ],
          ),
        );
      },
    );
  }
}
