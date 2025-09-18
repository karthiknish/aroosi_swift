import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/platform/adaptive_pickers.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/widgets/profile_list_item.dart';
import 'package:aroosi_flutter/widgets/paged_list_footer.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/features/profiles/selection.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/widgets/swipe_deck.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  SearchFilters? _currentFilters;
  Timer? _debounce;
  bool _cardsView = false;

  Future<void> _refresh() async {
    if (_currentFilters == null) return;
    if (!_requestUsage(UsageMetric.searchPerformed)) return;
    await ref.read(searchControllerProvider.notifier).search(_currentFilters!);
    if (!mounted) return;
    ToastService.instance.info('Search refreshed');
  }

  @override
  void initState() {
    super.initState();
    addLoadMoreListener(
      _scrollController,
      threshold: 200,
      canLoadMore: () {
        final s = ref.read(searchControllerProvider);
        return s.hasMore && !s.loading && s.filters != null;
      },
      onLoadMore: () => ref.read(searchControllerProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    // Build results list sliver
    SliverList buildResultsSliver() {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (state.items.isEmpty && state.loading) {
              return const ProfileListSkeleton();
            }
            if (index >= state.items.length) {
              return PagedListFooter(
                hasMore: state.hasMore,
                isLoading: state.loading,
              );
            }
            final p = state.items[index];
            return ProfileListItem(
              profile: p,
              onTap: () {
                ref.read(lastSelectedProfileIdProvider.notifier).set(p.id);
                context.push('/details/${p.id}');
              },
            );
          },
          childCount: state.items.isEmpty && state.loading
              ? 6
              : state.items.length + (state.hasMore ? 1 : 0),
        ),
      );
    }

    final results = AdaptiveRefresh(
      onRefresh: _refresh,
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSearchField(context),
          ),
        ),
        if (!_cardsView) ...[
          if (state.items.isEmpty && !state.loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No results')),
              ),
            )
          else
            buildResultsSliver(),
        ] else ...[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildCardDeck(context, state.items),
            ),
          ),
        ],
      ],
    );

    return AppScaffold(
      title: 'Search',
      actions: [
        IconButton(
          tooltip: _cardsView ? 'List view' : 'Card view',
          onPressed: () => setState(() => _cardsView = !_cardsView),
          icon: Icon(_cardsView ? Icons.view_list : Icons.style),
        ),
        IconButton(
          onPressed: () async {
            final access = ref.read(featureAccessProvider);
            if (!access.can(SubscriptionFeatureFlag.canUseAdvancedFilters)) {
              _showUpgradeToast(SubscriptionFeatureFlag.canUseAdvancedFilters);
              return;
            }
            final ctx = context;
            final date = await showAdaptiveDatePicker(ctx);
            if (date != null) {
              ToastService.instance.success(
                'Filter date: ${date.toLocal().toString().split(' ').first}',
              );
            }
          },
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
      child: results,
    );
  }

  Widget _buildCardDeck(BuildContext context, List<ProfileSummary> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('No results', style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    final deckItems = List<ProfileSummary>.from(items);
    return Column(
      children: [
        Expanded(
          child: SwipeDeck<ProfileSummary>(
            items: deckItems,
            overlayBuilder: (_, __, ___) => const DefaultSwipeOverlay(),
            itemBuilder: (ctx, profile) => _ProfileCard(profile: profile),
            onSwipe: (profile, dir) async {
              if (dir == SwipeDirection.right) {
                if (!_requestUsage(UsageMetric.interestSent)) return;
                final ok = await ref
                    .read(matchesControllerProvider.notifier)
                    .sendInterest(profile.id);
                if (ok) {
                  ToastService.instance.success('Liked ${profile.displayName}');
                } else {
                  ToastService.instance.error('Failed to like');
                }
              }
            },
            onEnd: () {
              ToastService.instance.info('That’s all for now');
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: () => ToastService.instance.info('Swipe left to pass'),
              child: const Icon(Icons.close),
            ),
            const SizedBox(width: 24),
            FilledButton(
              onPressed: () =>
                  ToastService.instance.info('Swipe right to like'),
              child: const Icon(Icons.favorite),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search...',
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _debounce?.cancel();
                  ref.read(searchControllerProvider.notifier).clear();
                  _currentFilters = null;
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () async {
          final query = value.trim();
          _currentFilters = SearchFilters(query: query.isEmpty ? null : query);
          if (_currentFilters?.query != null) {
            await _executeSearch(_currentFilters!);
          } else {
            ref.read(searchControllerProvider.notifier).clear();
          }
          if (!mounted) return;
          setState(() {});
        });
      },
      onSubmitted: (value) async {
        _currentFilters = SearchFilters(
          query: value.trim().isEmpty ? null : value.trim(),
        );
        if (_currentFilters?.query != null) {
          await ref
              .read(searchControllerProvider.notifier)
              .search(_currentFilters!);
        } else {
          ref.read(searchControllerProvider.notifier).clear();
        }
        if (!mounted) return;
        ToastService.instance.info('Searching "$value"');
      },
    );
  }

  Future<void> _executeSearch(SearchFilters filters) async {
    if (!_requestUsage(UsageMetric.searchPerformed)) return;
    await ref.read(searchControllerProvider.notifier).search(filters);
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
    final remaining = limit > 0 ? (limit - used).clamp(0, limit) : null;

    final featureMapping = {
      UsageMetric.searchPerformed:
          SubscriptionFeatureFlag.canUseAdvancedFilters,
      UsageMetric.interestSent: SubscriptionFeatureFlag.canSendUnlimitedLikes,
      UsageMetric.profileView: SubscriptionFeatureFlag.canViewFullProfiles,
      UsageMetric.profileBoostUsed: SubscriptionFeatureFlag.canBoostProfile,
      UsageMetric.messageSent: SubscriptionFeatureFlag.canInitiateChat,
      UsageMetric.voiceMessageSent: SubscriptionFeatureFlag.canChatWithMatches,
    };

    final feature = featureMapping[metric];
    final planLabel = feature != null
        ? access.requiredPlanLabel(feature)
        : 'Premium';

    final baseMessage = remaining == 0 && limit > 0
        ? 'You\'ve reached your ${limit == 1 ? 'limit' : 'monthly limit'} for this action.'
        : 'Upgrade to $planLabel to unlock more access.';

    ToastService.instance.warning(
      limit > 0 && remaining == 0
          ? '$baseMessage Upgrade to $planLabel for unlimited access.'
          : 'Upgrade to $planLabel to unlock more access.',
    );
  }

  void _showUpgradeToast(SubscriptionFeatureFlag feature) {
    final access = ref.read(featureAccessProvider);
    final planLabel = access.requiredPlanLabel(feature);
    ToastService.instance.warning('Upgrade to $planLabel to use this feature.');
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final ProfileSummary profile;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: profile.avatarUrl != null
                ? Ink.image(
                    image: NetworkImage(profile.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName.characters.first
                            : '?',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
          ListTile(
            title: Text(profile.displayName, overflow: TextOverflow.ellipsis),
            subtitle: Text(profile.city ?? ''),
            trailing: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
