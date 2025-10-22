import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/empty_states.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/features/profiles/selection.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/widgets/retryable_network_image.dart';

import 'package:aroosi_flutter/features/auth/auth_controller.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';
import 'package:aroosi_flutter/theme/colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const int _defaultPageSize = 12;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // Get toast service from provider
  ToastService get _toast => ref.read(toastServiceProvider);

  @override
  void initState() {
    super.initState();
    // Load all profiles on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllProfiles();
      _loadInterests();
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

    // Show loading state when performing search or initial load
    if (state.loading && state.items.isEmpty) {
      return AppScaffold(
        title: 'Search',
        child: AdaptiveRefresh(
          onRefresh: _refresh,
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSearchControls(context),
              ),
            ),
            SliverFillRemaining(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading profiles...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final slivers = <Widget>[
      if (state.error != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildErrorBanner(context, state.error!),
          ),
        ),
      SliverFillRemaining(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildCardDeck(context, state),
        ),
      ),
    ];

    return AppScaffold(
      title: 'Search',
      child: AdaptiveRefresh(
        onRefresh: _refresh,
        controller: _scrollController,
        slivers: slivers,
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return InlineError(
      error: message,
      onRetry: _hasSearchCriteria
          ? () => _scheduleSearch(immediate: true)
          : null,
      showIcon: true,
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool forCards}) {
    final state = ref.watch(searchControllerProvider);
    final isLoading = state.loading;

    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: forCards ? 24 : 32,
        ),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading profiles...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: forCards ? 24 : 32,
      ),
      child: EmptySearchState(
        searchQuery: _controller.text.isNotEmpty ? _controller.text : null,
        onClearSearch: _controller.text.isNotEmpty
            ? () {
                _controller.clear();
                _loadAllProfiles();
              }
            : null,
      ),
    );
  }

  Widget _buildSearchControls(BuildContext context) {
    return Column(
      children: [
        // Search Text Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search by name, city, or interests...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _loadAllProfiles();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                _scheduleSearch();
              });
            },
          ),
        ),
        // Filter Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showFiltersSheet(context),
              icon: const Icon(Icons.filter_list),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDeck(BuildContext context, ProfilesListState state) {
    final items = state.items;
    if (items.isEmpty && !state.loading) {
      return _buildEmptyState(context, forCards: true);
    }

    // Filter out profiles that already have interest sent
    final filteredItems = items.where((profile) {
      final interestStatus = ref.read(interestsControllerProvider);
      final hasSentInterest = interestStatus.items.any(
        (interest) =>
            interest.toUserId == profile.id &&
            (interest.status == 'pending' || interest.status == 'accepted'),
      );
      return !hasSentInterest;
    }).toList();

    logDebug(
      'Building profile list',
      data: {
        'itemCount': filteredItems.length,
        'widgetType': 'ListView',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final profile = filteredItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _ProfileListItem(
                  profile: profile,
                  onLike: () async {
                    final ok = await ref
                        .read(matchesControllerProvider.notifier)
                        .sendInterest(profile.id);
                    if (ok['success'] == true) {
                      _toast.success('Liked ${profile.displayName}');
                    } else {
                      _toast.error('Failed to like');
                    }
                  },
                  onViewProfile: () {
                    ref
                        .read(lastSelectedProfileIdProvider.notifier)
                        .set(profile.id);
                    context.push('/details/${profile.id}');
                  },
                ),
              );
            },
          ),
        ),
        if (state.hasMore && !state.loading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(searchControllerProvider.notifier).loadMore(),
                child: const Text('Load More'),
              ),
            ),
          ),
        if (state.loading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _loadAllProfiles() async {
    logDebug('SearchScreen: Loading all profiles');

    // Get current user's profile to access preferred gender
    final auth = ref.read(authControllerProvider);
    final userProfile = auth.profile;

    // Create filters with preferred gender if available
    final filters = SearchFilters(
      pageSize: _defaultPageSize,
      query: null,
      city: null,
      minAge: null,
      maxAge: null,
      sort: null,
      cursor: null,
      preferredGender: userProfile?.preferredGender?.isNotEmpty == true
          ? userProfile!.preferredGender
          : null,
    );

    await ref.read(searchControllerProvider.notifier).search(filters);
  }

  Future<void> _loadInterests() async {
    logDebug('SearchScreen: Loading interests data');
    try {
      await ref.read(interestsControllerProvider.notifier).load(mode: 'sent');
    } catch (e) {
      logDebug('SearchScreen: Failed to load interests', error: e);
    }
  }

  Future<void> _refresh() async {
    final state = ref.read(searchControllerProvider);
    if (state.filters != null) {
      // Re-run the current search
      await ref.read(searchControllerProvider.notifier).search(state.filters!);
    } else {
      // Load all profiles if no filters
      await _loadAllProfiles();
    }
    if (mounted) {
      _toast.success('Search refreshed');
    }
  }

  Future<void> _scheduleSearch({bool immediate = false}) async {
    final query = _controller.text.trim();
    final state = ref.read(searchControllerProvider);

    // Get current user's profile for preferred gender
    final auth = ref.read(authControllerProvider);
    final userProfile = auth.profile;

    // Create filters with current query and existing filters
    final filters = SearchFilters(
      pageSize: _defaultPageSize,
      query: query.isNotEmpty ? query : null,
      city: state.filters?.city,
      minAge: state.filters?.minAge,
      maxAge: state.filters?.maxAge,
      sort: state.filters?.sort,
      cursor: null,
      preferredGender:
          state.filters?.preferredGender ??
          (userProfile?.preferredGender?.isNotEmpty == true
              ? userProfile!.preferredGender
              : null),
    );

    await ref.read(searchControllerProvider.notifier).search(filters);
  }

  bool get _hasSearchCriteria {
    final query = _controller.text.trim();
    final state = ref.read(searchControllerProvider);
    final filters = state.filters;

    return query.isNotEmpty ||
        (filters != null &&
            (filters.city != null ||
                filters.minAge != null ||
                filters.maxAge != null ||
                filters.sort != null ||
                filters.preferredGender != null));
  }

  Future<void> _showFiltersSheet(BuildContext context) async {
    final state = ref.read(searchControllerProvider);
    final initialFilters =
        state.filters ?? SearchFilters(pageSize: _defaultPageSize);

    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SearchFiltersSheet(initial: initialFilters),
    );

    if (result != null) {
      // Apply the selected filters
      final auth = ref.read(authControllerProvider);
      final userProfile = auth.profile;

      final filters = SearchFilters(
        pageSize: _defaultPageSize,
        query: _controller.text.trim().isNotEmpty
            ? _controller.text.trim()
            : null,
        city: result.city,
        minAge: result.minAge,
        maxAge: result.maxAge,
        sort: result.sort,
        cursor: null,
        preferredGender:
            result.preferredGender ??
            (userProfile?.preferredGender?.isNotEmpty == true
                ? userProfile!.preferredGender
                : null),
      );

      await ref.read(searchControllerProvider.notifier).search(filters);
    }
  }
}

class _ProfileListItem extends StatelessWidget {
  const _ProfileListItem({
    required this.profile,
    required this.onLike,
    required this.onViewProfile,
  });

  final ProfileSummary profile;
  final VoidCallback onLike;
  final VoidCallback onViewProfile;

  static const String _placeholderAsset = 'assets/images/placeholder.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = profile;

    final ageCity = <String>[];
    if (p.age != null) ageCity.add(p.age!.toString());
    if (p.city?.trim().isNotEmpty == true) {
      ageCity.add(p.city!.trim());
    }
    final subtitle = ageCity.join(' • ');

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Profile Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: p.avatarUrl != null && p.avatarUrl!.trim().isNotEmpty
                      ? RetryableNetworkImage(
                          url: p.avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: Image.asset(
                            _placeholderAsset,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(_placeholderAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Compatibility Score (mock data for now)
                    if (true) ...[
                      // This would be based on actual compatibility data
                      const SizedBox(height: 8),
                      _CompatibilityScoreIndicator(score: 0.75), // Mock score
                    ],

                    if (p.isFavorite || p.isShortlisted) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (p.isFavorite)
                            Icon(
                              Icons.favorite,
                              color: theme.colorScheme.error,
                              size: 16,
                            ),
                          if (p.isShortlisted)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.bookmark,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Action Buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    onPressed: onViewProfile,
                    icon: const Icon(Icons.person_outline),
                    tooltip: 'View Profile',
                  ),
                  const SizedBox(height: 8),
                  IconButton.filled(
                    onPressed: onLike,
                    icon: const Icon(Icons.favorite),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.pink.withValues(alpha: 0.1),
                      foregroundColor: Colors.pink,
                    ),
                    tooltip: 'Like',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompatibilityScoreIndicator extends StatelessWidget {
  final double score; // 0.0 to 1.0

  const _CompatibilityScoreIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = _getScoreColor(score);

    return Row(
      children: [
        Icon(Icons.favorite_border, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$percentage% Match',
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class _FilterSelection {
  const _FilterSelection({
    this.city,
    this.minAge,
    this.maxAge,
    this.sort,
    this.preferredGender,
  });

  final String? city;
  final int? minAge;
  final int? maxAge;
  final String? sort;
  final String? preferredGender;
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

const List<_FilterOption> _genderOptions = [
  _FilterOption('', 'Any gender'),
  _FilterOption('male', 'Male'),
  _FilterOption('female', 'Female'),
  _FilterOption('non-binary', 'Non-binary'),
];

BoxDecoration cupertinoDecoration(BuildContext context) {
  return BoxDecoration(
    border: Border.all(color: AppColors.primary, width: 1.5),
    borderRadius: BorderRadius.circular(8),
  );
}

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
  late String? _gender;

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
    _gender = widget.initial.preferredGender;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _showSortPicker() {
    final initialIndex = _sortOptions.indexWhere(
      (option) => option.value == _sort,
    );
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: initialIndex >= 0 ? initialIndex : 0,
            ),
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                _sort = _sortOptions[selectedItem].value;
              });
            },
            children: _sortOptions
                .map((option) => Center(child: Text(option.label)))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showGenderPicker() {
    final initialIndex = _genderOptions.indexWhere(
      (option) => option.value == (_gender ?? ''),
    );
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: initialIndex >= 0 ? initialIndex : 0,
            ),
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                final value = _genderOptions[selectedItem].value;
                _gender = value.isEmpty ? null : value;
              });
            },
            children: _genderOptions
                .map((option) => Center(child: Text(option.label)))
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
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
                        color: theme.dividerColor.withValues(alpha: 0.4),
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
                  AnimatedOpacity(
                    opacity: _useAgeFilter ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_useAgeFilter,
                      child: RangeSlider(
                        values: _ageRange,
                        min: _minAge,
                        max: _maxAge,
                        divisions: (_maxAge - _minAge).round(),
                        labels: RangeLabels(
                          '${_ageRange.start.round()}',
                          '${_ageRange.end.round()}',
                        ),
                        onChanged: _useAgeFilter
                            ? (value) => setState(() => _ageRange = value)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Sort by',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      Container(
                        decoration: cupertinoDecoration(context),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          onPressed: _showSortPicker,
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.sort_down, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _sortOptions
                                      .firstWhere(
                                        (option) => option.value == _sort,
                                        orElse: () => _sortOptions[0],
                                      )
                                      .label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: CupertinoColors.label,
                                  ),
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      Container(
                        decoration: cupertinoDecoration(context),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          onPressed: _showGenderPicker,
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.person, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _genderOptions
                                      .firstWhere(
                                        (option) =>
                                            option.value == (_gender ?? ''),
                                        orElse: () => _genderOptions[0],
                                      )
                                      .label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: CupertinoColors.label,
                                  ),
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _reset,
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _apply,
                          child: const Text('Apply filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      _gender = null;
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
        preferredGender: _gender?.isEmpty == true ? null : _gender,
      ),
    );
  }
}
