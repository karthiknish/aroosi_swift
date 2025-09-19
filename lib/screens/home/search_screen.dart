import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/features/subscription/feature_access_provider.dart';
import 'package:aroosi_flutter/features/subscription/feature_usage_controller.dart';
import 'package:aroosi_flutter/features/subscription/subscription_features.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/widgets/profile_list_item.dart';
import 'package:aroosi_flutter/widgets/paged_list_footer.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/features/profiles/selection.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/widgets/swipe_deck.dart';
import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';
import 'package:aroosi_flutter/utils/globalkey_error_handler.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const int _defaultPageSize = 12;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  SearchFilters _filters = const SearchFilters(pageSize: _defaultPageSize);
  Timer? _debounce;
  bool _cardsView = true;
  int _currentCardIndex = 0;

  // Get toast service from provider
  ToastService get _toast => ref.read(toastServiceProvider);

  bool get _hasSearchCriteria => _filters.hasCriteria;
  bool get _hasActiveFilters => _filters.hasFieldFilters;

  @override
  void initState() {
    super.initState();
    // Load all profiles on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllProfiles();
    });
    addLoadMoreListener(
      _scrollController,
      threshold: 200,
      canLoadMore: () {
        final state = ref.read(searchControllerProvider);
        return state.hasMore && !state.loading && state.filters != null;
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
    final auth = ref.watch(authControllerProvider);
    // Redirect to welcome if not authenticated
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentLoc = GoRouterState.of(context).uri.toString();
        if (currentLoc != '/startup') {
          context.go('/startup');
        }
      });
      return const SizedBox.shrink();
    }
    // Show loader if auth is loading or profile is missing
    if (auth.loading || auth.profile == null) {
      return const AppScaffold(
        title: 'Search',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSearchControls(context),
        ),
      ),
      if (state.error != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildErrorBanner(context, state.error!),
          ),
        ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200, // Approximate height for card view
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildCardDeck(context, state),
          ),
        ),
      ),
    ];

    return AppScaffold(
      title: 'Search',
      actions: [
        IconButton(
          tooltip: 'Filters',
          onPressed: _onFiltersPressed,
          icon: Icon(
            Icons.filter_alt_outlined,
            color: _hasActiveFilters
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
      ],
      child: AdaptiveRefresh(
        onRefresh: _refresh,
        controller: _scrollController,
        slivers: slivers,
      ),
    );
  }

  Widget _buildSearchControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterButtons(context),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 12),
          _buildActiveFiltersChips(context),
        ],
      ],
    );
  }

  Widget _buildFilterButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: OutlinedButton.icon(
              onPressed: _onFiltersPressed,
              icon: const Icon(Icons.tune),
              label: const Text('Filters'),
            ),
          ),
          const SizedBox(width: 12),
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearNonQueryFilters,
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context) {
    final chips = <Widget>[];

    if (_filters.city != null && _filters.city!.trim().isNotEmpty) {
      chips.add(
        InputChip(
          label: Text('City: ${_filters.city}'),
          onDeleted: () =>
              _handleFilterRemoval((current) => current.copyWith(city: null)),
        ),
      );
    }

    if (_filters.minAge != null || _filters.maxAge != null) {
      final min = _filters.minAge?.toString() ?? 'Any';
      final max = _filters.maxAge?.toString() ?? 'Any';
      chips.add(
        InputChip(
          label: Text('Age $min - $max'),
          onDeleted: () => _handleFilterRemoval(
            (current) => current.copyWith(minAge: null, maxAge: null),
          ),
        ),
      );
    }

    if (_filters.sort != null && _filters.sort!.trim().isNotEmpty) {
      chips.add(
        InputChip(
          label: Text(_sortLabelForValue(_filters.sort!)),
          onDeleted: () =>
              _handleFilterRemoval((current) => current.copyWith(sort: null)),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  String _sortLabelForValue(String value) {
    switch (value) {
      case 'newest':
        return 'Newest profiles';
      case 'distance':
        return 'Closest to you';
      case 'recent':
      default:
        return 'Recently active';
    }
  }

  SliverList _buildResultsSliver(ProfilesListState state) {
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
          final profile = state.items[index];
          return ProfileListItem(
            key: ValueKey('profile_list_${profile.id}'),
            profile: profile,
            onTap: () {
              ref.read(lastSelectedProfileIdProvider.notifier).set(profile.id);
              context.push('/details/${profile.id}');
            },
          );
        },
        childCount: state.items.isEmpty && state.loading
            ? 6
            : state.items.length + (state.hasMore ? 1 : 0),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = scheme.errorContainer;
    final foreground = scheme.onErrorContainer;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
          if (_hasSearchCriteria)
            TextButton(
              onPressed: () => _scheduleSearch(immediate: true),
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool forCards}) {
    final theme = Theme.of(context);
    final message = 'No profiles found';
    final subtext = 'Try adjusting your filters or check back later.';
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          subtext,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _onFiltersPressed,
          icon: const Icon(Icons.tune),
          label: const Text('Open filters'),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: forCards ? 24 : 32,
      ),
      child: Center(child: content),
    );
  }

  Widget _buildCardDeck(BuildContext context, ProfilesListState state) {
    final items = state.items;
    if (items.isEmpty) {
      return _buildEmptyState(context, forCards: true);
    }

    final deckItems = List<ProfileSummary>.from(items);
    int remaining = deckItems.length;
    
    // Log for debugging GlobalKey issues
    logDebug('Building card deck', data: {
      'itemCount': deckItems.length,
      'widgetType': 'SwipeDeck',
      'timestamp': DateTime.now().toIso8601String(),
    });
    return Column(
      children: [
        // Card deck with flexible height
        Expanded(
          child: SwipeDeck<ProfileSummary>(
            items: deckItems,
            overlayBuilder: (_, __, ___) => const DefaultSwipeOverlay(),
            itemBuilder: (ctx, profile) => _ProfileCard(
              key: ValueKey('profile_card_${profile.id}'),
              profile: profile,
            ),
            onSwipe: (profile, direction) async {
              if (direction == SwipeDirection.right) {
                if (!_requestUsage(UsageMetric.interestSent)) return;
                final ok = await ref
                    .read(matchesControllerProvider.notifier)
                    .sendInterest(profile.id);
                if (ok) {
                  _toast.success(
                    'Liked ${profile.displayName}',
                  );
                } else {
                  _toast.error('Failed to like');
                }
              }
              // Update current index after swipe
              setState(() {
                _currentCardIndex++;
              });
            },
            onEnd: () {
              _toast.info("That's all for now");
            },
          ),
        ),
        const SizedBox(height: 12),
        // Bottom action bar
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: FilledButton.tonal(
                  onPressed: () {
                    // Swipe left (pass) - show toast since we can't directly control the deck
                    _toast.info('Swipe left on the card to pass');
                  },
                  child: const Icon(Icons.close),
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: FilledButton.tonal(
                  onPressed: () {
                    // Show more info - get current profile and navigate to details
                    final state = ref.read(searchControllerProvider);
                    if (state.items.isNotEmpty && _currentCardIndex < state.items.length) {
                      final profile = state.items[_currentCardIndex];
                      ref.read(lastSelectedProfileIdProvider.notifier).set(profile.id);
                      context.push('/details/${profile.id}');
                    }
                  },
                  child: const Icon(Icons.info_outline),
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: FilledButton(
                  onPressed: () {
                    // Swipe right (like) - show toast since we can't directly control the deck
                    _toast.info('Swipe right on the card to like');
                  },
                  child: const Icon(Icons.favorite),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Remaining counter
        Text(
          '$remaining left',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search by name or keyword',
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: _clearQuery,
              )
            : null,
      ),
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        final trimmed = value.trim();
        setState(() {
          _filters = _filters.copyWith(
            query: trimmed.isEmpty ? null : trimmed,
            pageSize: _filters.pageSize ?? _defaultPageSize,
          );
        });
        _scheduleSearch();
      },
      onSubmitted: (value) async {
        final trimmed = value.trim();
        setState(() {
          _filters = _filters.copyWith(
            query: trimmed.isEmpty ? null : trimmed,
            pageSize: _filters.pageSize ?? _defaultPageSize,
          );
        });
        await _performSearch(announce: true);
      },
    );
  }

  void _clearQuery() {
    if (_controller.text.isEmpty) return;
    
    logDebug('SearchScreen: Clearing search query', data: {
      'previousQuery': _controller.text,
      'remainingFilters': _filters.toQuery(),
    });
    
    _debounce?.cancel();
    setState(() {
      _controller.clear();
      _filters = _filters.copyWith(
        query: null,
        pageSize: _filters.pageSize ?? _defaultPageSize,
      );
    });
    
    if (_filters.hasCriteria) {
      logDebug('SearchScreen: Still has criteria, performing search');
      unawaited(_performSearch());
    } else {
      logDebug('SearchScreen: No criteria remaining, clearing results');
      ref.read(searchControllerProvider.notifier).clear();
    }
  }

  void _handleFilterRemoval(
    SearchFilters Function(SearchFilters current) transform,
  ) {
    final next = transform(_filters);
    unawaited(_setFiltersAndSearch(next));
  }

  void _clearNonQueryFilters() {
    final cleared = _filters.copyWith(
      city: null,
      minAge: null,
      maxAge: null,
      sort: null,
      cursor: null,
    );
    unawaited(_setFiltersAndSearch(cleared));
  }

  Future<void> _refresh() async {
    if (!_hasSearchCriteria) {
      logDebug('SearchScreen: Refresh skipped - no search criteria');
      return;
    }
    
    if (!_requestUsage(UsageMetric.searchPerformed)) {
      logDebug('SearchScreen: Refresh skipped - usage limit reached');
      return;
    }
    
    logDebug('SearchScreen: Refreshing search', data: {
      'filters': _effectiveFilters.toQuery(),
    });
    
    await ref.read(searchControllerProvider.notifier).search(_effectiveFilters);
    if (!mounted) return;
    _toast.info('Search refreshed');
  }

  SearchFilters get _effectiveFilters => _filters.copyWith(
    pageSize: _filters.pageSize ?? _defaultPageSize,
    cursor: null,
  );

  void _scheduleSearch({bool immediate = false}) {
    _debounce?.cancel();
    if (!_hasSearchCriteria) {
      logDebug('SearchScreen: No search criteria, clearing results');
      ref.read(searchControllerProvider.notifier).clear();
      return;
    }
    
    logDebug('SearchScreen: Scheduling search', data: {
      'immediate': immediate,
      'filters': _filters.toQuery(),
      'hasCriteria': _hasSearchCriteria,
    });
    
    if (immediate) {
      unawaited(_performSearch());
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), () {
        unawaited(_performSearch());
      });
    }
  }

  Future<void> _performSearch({bool announce = false}) async {
    if (!_hasSearchCriteria) {
      logDebug('SearchScreen: No search criteria, clearing results');
      ref.read(searchControllerProvider.notifier).clear();
      return;
    }
    
    if (!_requestUsage(UsageMetric.searchPerformed)) {
      logDebug('SearchScreen: Usage limit reached for search');
      return;
    }

    final filters = _effectiveFilters;
    logDebug('SearchScreen: Performing search', data: {
      'filters': filters.toQuery(),
      'announce': announce,
      'hasQuery': filters.hasQuery,
      'query': filters.query,
    });
    
    await ref.read(searchControllerProvider.notifier).search(filters);
    if (!mounted) return;

    if (announce && filters.hasQuery) {
      _toast.info('Searching "${filters.query}"');
    }
  }

  Future<void> _setFiltersAndSearch(
    SearchFilters update, {
    bool announce = false,
  }) async {
    _debounce?.cancel();
    final normalized = update.copyWith(
      cursor: null,
      pageSize: update.pageSize ?? _defaultPageSize,
    );
    
    logDebug('SearchScreen: Setting filters and searching', data: {
      'previousFilters': _filters.toQuery(),
      'newFilters': normalized.toQuery(),
      'announce': announce,
      'hasCriteria': normalized.hasCriteria,
    });
    
    setState(() {
      _filters = normalized;
    });
    
    if (_filters.hasCriteria) {
      await _performSearch(announce: announce);
    } else {
      logDebug('SearchScreen: No criteria after filter update, clearing results');
      ref.read(searchControllerProvider.notifier).clear();
    }
  }

  Future<void> _onFiltersPressed() async {
    final access = ref.read(featureAccessProvider);
    if (!access.can(SubscriptionFeatureFlag.canUseAdvancedFilters)) {
      _showUpgradeToast(SubscriptionFeatureFlag.canUseAdvancedFilters);
      return;
    }

    final selection = await showModalBottomSheet<_FilterSelection>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => _SearchFiltersSheet(initial: _filters),
    );

    if (!mounted || selection == null) return;

    final updated = _filters.copyWith(
      city: selection.city,
      minAge: selection.minAge,
      maxAge: selection.maxAge,
      sort: selection.sort,
    );

    await _setFiltersAndSearch(updated);
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
        ? "You've reached your ${limit == 1 ? 'limit' : 'monthly limit'} for this action."
        : 'Upgrade to $planLabel to unlock more access.';

    _toast.warning(
      limit > 0 && remaining == 0
          ? '$baseMessage Upgrade to $planLabel for unlimited access.'
          : 'Upgrade to $planLabel to unlock more access.',
    );
  }

  void _showUpgradeToast(SubscriptionFeatureFlag feature) {
    final access = ref.read(featureAccessProvider);
    final planLabel = access.requiredPlanLabel(feature);
    _toast.warning('Upgrade to $planLabel to use this feature.');
  }

  Future<void> _loadAllProfiles() async {
    if (!_requestUsage(UsageMetric.searchPerformed)) {
      logDebug('SearchScreen: Usage limit reached for loading profiles');
      return;
    }
    
    logDebug('SearchScreen: Loading all profiles');
    
    // Create empty filters to get all profiles
    final emptyFilters = SearchFilters(
      pageSize: _defaultPageSize,
      query: null,
      city: null,
      minAge: null,
      maxAge: null,
      sort: null,
      cursor: null,
    );
    
    await ref.read(searchControllerProvider.notifier).search(emptyFilters);
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({super.key, required this.profile});

  final ProfileSummary profile;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  static const String _placeholderAsset = 'assets/images/placeholder.png';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.profile;
    final ageCity = <String>[];
    if (p.age != null) ageCity.add(p.age!.toString());
    if (p.city?.trim().isNotEmpty == true) {
      ageCity.add(p.city!.trim());
    }
    final subtitle = ageCity.join(' • ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: p.avatarUrl != null && p.avatarUrl!.trim().isNotEmpty
                  ? Image.network(
                      p.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Image.asset(_placeholderAsset, fit: BoxFit.cover),
                    )
                  : Image.asset(_placeholderAsset, fit: BoxFit.cover),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitle, style: theme.textTheme.bodyMedium),
                    ),
                  if (p.isFavorite || p.isShortlisted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          if (p.isFavorite)
                            Icon(
                              Icons.favorite,
                              color: theme.colorScheme.error,
                              size: 18,
                            ),
                          if (p.isShortlisted)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.bookmark,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // ...existing code...
  }

  // (removed unused _badge and _activePill)
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.borderRadius});
  final double borderRadius;
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ShimmerPainter(progress: _controller.value),
          child: Container(),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Colors.grey.shade800;
    final highlight = Colors.grey.shade600;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + progress * 2, -1),
        end: Alignment(1 + progress * 2, 1),
        colors: [
          base.withOpacity(0.35),
          highlight.withOpacity(0.55),
          base.withOpacity(0.35),
        ],
        stops: const [0.15, 0.5, 0.85],
      ).createShader(Offset.zero & size);
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(20));
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FilterSelection {
  const _FilterSelection({this.city, this.minAge, this.maxAge, this.sort});

  final String? city;
  final int? minAge;
  final int? maxAge;
  final String? sort;
}

class _FilterOption {
  const _FilterOption(this.value, this.label);
  final String value;
  final String label;
}

const List<_FilterOption> _sortOptions = [
  _FilterOption('', 'Recommended'),
  _FilterOption('recent', 'Recently active'),
  _FilterOption('newest', 'Newest profiles'),
  _FilterOption('distance', 'Closest to you'),
];

class _SearchFiltersSheet extends StatefulWidget {
  const _SearchFiltersSheet({required this.initial});

  final SearchFilters initial;

  @override
  State<_SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<_SearchFiltersSheet> {
  late final TextEditingController _cityController;
  late bool _useAgeFilter;
  late RangeValues _ageRange;
  late String _sort;

  static const double _minAge = 18;
  static const double _maxAge = 80;
  static const double _defaultMinAge = 24;
  static const double _defaultMaxAge = 36;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initial.city ?? '');
    _useAgeFilter =
        widget.initial.minAge != null || widget.initial.maxAge != null;
    final minAge = (widget.initial.minAge ?? _defaultMinAge).toDouble();
    final maxAge = (widget.initial.maxAge ?? _defaultMaxAge).toDouble();
    _ageRange = RangeValues(
      minAge.clamp(_minAge, _maxAge),
      maxAge.clamp(_minAge, _maxAge),
    );
    _sort = widget.initial.sort ?? '';
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Refine search', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter city',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _useAgeFilter,
                onChanged: (value) => setState(() => _useAgeFilter = value),
                title: const Text('Filter by age range'),
                subtitle: Text(
                  '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                ),
              ),
              IgnorePointer(
                ignoring: !_useAgeFilter,
                child: Opacity(
                  opacity: _useAgeFilter ? 1 : 0.4,
                  child: RangeSlider(
                    values: _ageRange,
                    min: _minAge,
                    max: _maxAge,
                    divisions: (_maxAge - _minAge).round(),
                    labels: RangeLabels(
                      '${_ageRange.start.round()}',
                      '${_ageRange.end.round()}',
                    ),
                    onChanged: (value) => setState(() => _ageRange = value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sort,
                decoration: const InputDecoration(
                  labelText: 'Sort by',
                  prefixIcon: Icon(Icons.sort),
                ),
                items: _sortOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _sort = value ?? ''),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                  const Spacer(),
                  FilledButton(
                    onPressed: _apply,
                    child: const Text('Apply filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _cityController.clear();
      _useAgeFilter = false;
      _ageRange = const RangeValues(_defaultMinAge, _defaultMaxAge);
      _sort = '';
    });
  }

  void _apply() {
    final trimmedCity = _cityController.text.trim();
    Navigator.of(context).pop(
      _FilterSelection(
        city: trimmedCity.isEmpty ? null : trimmedCity,
        minAge: _useAgeFilter ? _ageRange.start.round() : null,
        maxAge: _useAgeFilter ? _ageRange.end.round() : null,
        sort: _sort.isEmpty ? null : _sort,
      ),
    );
  }
}
