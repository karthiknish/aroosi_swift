import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/features/subscription/subscription_models.dart';
import 'package:aroosi_flutter/platform/adaptive_feedback.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/shimmer.dart';
import 'package:aroosi_flutter/widgets/paged_list_footer.dart';
import 'package:aroosi_flutter/widgets/inline_upgrade_banner.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/widgets/animations/motion.dart';

class InterestsManagementScreen extends ConsumerStatefulWidget {
  const InterestsManagementScreen({super.key});

  @override
  ConsumerState<InterestsManagementScreen> createState() =>
      _InterestsManagementScreenState();
}

class _InterestsManagementScreenState
    extends ConsumerState<InterestsManagementScreen> {
  final _scrollController = ScrollController();
  String _currentMode = 'sent';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interestsControllerProvider.notifier).load(mode: _currentMode);
    });
    addLoadMoreListener(
      _scrollController,
      threshold: 200,
      canLoadMore: () {
        final s = ref.read(interestsControllerProvider);
        return s.hasMore && !s.loading;
      },
      onLoadMore: () =>
          ref.read(interestsControllerProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interestsControllerProvider);
    final access = ref.watch(featureAccessProvider);
    final isFreePlan = access.plan == SubscriptionPlan.free;

    if (!state.loading && state.error != null && state.items.isEmpty) {
      return AppScaffold(
        title: 'Interests',
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref
                    .read(interestsControllerProvider.notifier)
                    .load(mode: _currentMode),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final content = AdaptiveRefresh(
      onRefresh: () async {
        await ref
            .read(interestsControllerProvider.notifier)
            .load(mode: _currentMode);
        ToastService.instance.success('Refreshed');
      },
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'sent', label: Text('Sent')),
                ButtonSegment<String>(
                  value: 'received',
                  label: Text('Received'),
                ),
                ButtonSegment<String>(value: 'mutual', label: Text('Mutual')),
              ],
              selected: {_currentMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _currentMode = newSelection.first;
                });
                ref
                    .read(interestsControllerProvider.notifier)
                    .load(mode: _currentMode);
              },
            ),
          ),
        ),
        if (isFreePlan && _currentMode == 'sent')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InlineUpgradeBanner(
                message: 'Upgrade to Premium to send unlimited interests.',
                ctaLabel: 'Upgrade to Premium',
                onPressed: () => context.push('/main/subscription'),
              ),
            ),
          ),
        if (state.items.isEmpty && !state.loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No interests found')),
            ),
          )
        else
          _buildListSliver(state),
      ],
    );

    return AppScaffold(title: 'Interests', child: content);
  }

  Widget _buildListSliver(InterestsState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index >= state.items.length) {
          return PagedListFooter(
            hasMore: state.hasMore,
            isLoading: state.loading,
          );
        }
        final interest = state.items[index];
        return _InterestCard(interest: interest, mode: _currentMode);
      }, childCount: state.items.length + (state.hasMore ? 1 : 0)),
    );
  }
}

class _InterestCard extends ConsumerWidget {
  const _InterestCard({required this.interest, required this.mode});

  final InterestEntry interest;
  final String mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReceived = mode == 'received';
    final isMutual = mode == 'mutual';

    // Get user info from snapshots
    final otherUserSnapshot = isReceived
        ? interest.fromSnapshot
        : interest.toSnapshot;
    final otherUserName = otherUserSnapshot?['fullName']?.toString() ?? 'User';
    final otherUserImage = otherUserSnapshot?['profileImageUrls'] is List
        ? (otherUserSnapshot!['profileImageUrls'] as List).isNotEmpty
              ? otherUserSnapshot['profileImageUrls'][0]?.toString()
              : null
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: otherUserImage != null
              ? NetworkImage(otherUserImage)
              : null,
          child: otherUserImage == null
              ? Text(
                  otherUserName.isNotEmpty
                      ? otherUserName.characters.first
                      : '?',
                )
              : null,
        ),
        title: Text(otherUserName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${interest.status}',
              style: TextStyle(
                color: _getStatusColor(interest.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: isReceived && interest.status == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      final result = await ref
                          .read(interestsControllerProvider.notifier)
                          .respondToInterest(
                            interestId: interest.id,
                            status: 'rejected',
                          );

                      if (result['success'] == true) {
                        ToastService.instance.success('Interest rejected');
                      } else {
                        final error =
                            result['error'] as String? ??
                            'Failed to reject interest';
                        final isPlanLimit = result['isPlanLimit'] == true;
                        if (isPlanLimit) {
                          ToastService.instance.warning(
                            'Upgrade to respond to more interests',
                          );
                        } else {
                          ToastService.instance.error(error);
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      final result = await ref
                          .read(interestsControllerProvider.notifier)
                          .respondToInterest(
                            interestId: interest.id,
                            status: 'accepted',
                          );

                      if (result['success'] == true) {
                        ToastService.instance.success('Interest accepted!');
                      } else {
                        final error =
                            result['error'] as String? ??
                            'Failed to accept interest';
                        final isPlanLimit = result['isPlanLimit'] == true;
                        if (isPlanLimit) {
                          ToastService.instance.warning(
                            'Upgrade to respond to more interests',
                          );
                        } else {
                          ToastService.instance.error(error);
                        }
                      }
                    },
                  ),
                ],
              )
            : isMutual
            ? const Icon(Icons.favorite, color: Colors.pink)
            : Icon(
                _getStatusIcon(interest.status),
                color: _getStatusColor(interest.status),
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'reciprocated':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
      case 'reciprocated':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'withdrawn':
        return Icons.undo;
      default:
        return Icons.help_outline;
    }
  }
}
