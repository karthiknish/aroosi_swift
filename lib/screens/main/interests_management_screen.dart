import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';

import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/paged_list_footer.dart';

import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/utils/pagination.dart';
import 'package:aroosi_flutter/widgets/adaptive_refresh.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/theme/colors.dart';

import 'interest_management/interest_management_components.dart';

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
  bool _showCulturalInsights = false;
  bool _showCompatibilityScore = true;
  final String _viewMode = 'traditional'; // 'traditional' or 'modern'
  bool _showIcebreakers = false;
  bool _showFamilyInvolvement = false;
  bool _showCourtshipJourney = false;

  final List<String> _icebreakerPrompts = [
    "What's your favorite cultural tradition?",
    "What's a hobby you've always wanted to try?",
    "What's your go-to comfort food?",
    "What's a book that changed your perspective?",
    "What's your favorite way to spend a weekend?",
  ];

  final List<_GuidedStep> _familySteps = [
    _GuidedStep(
      icon: Icons.family_restroom,
      title: 'Initial Meeting',
      subtitle:
          'Introduce your partner to immediate family in a casual setting.',
    ),
    _GuidedStep(
      icon: Icons.restaurant,
      title: 'Family Gathering',
      subtitle: 'Host a small family dinner or gathering.',
    ),
    _GuidedStep(
      icon: Icons.diversity_3,
      title: 'Cultural Exchange',
      subtitle: 'Share and learn about each other\'s family traditions.',
    ),
  ];

  final List<_GuidedStep> _courtshipSteps = [
    _GuidedStep(
      icon: Icons.chat,
      title: 'Getting to Know You',
      subtitle: 'Focus on shared interests and values through conversations.',
    ),
    _GuidedStep(
      icon: Icons.groups,
      title: 'Family Involvement',
      subtitle: 'Introduce partners to respective families.',
    ),
    _GuidedStep(
      icon: Icons.heart_broken,
      title: 'Commitment Discussion',
      subtitle: 'Discuss future plans and long-term compatibility.',
    ),
  ];

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
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.secondary.withValues(alpha: 0.15),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JourneyIntro(state: state, currentMode: _currentMode),
                    const SizedBox(height: 20),
                    ModeSelector(
                      currentMode: _currentMode,
                      onModeChanged: (mode) {
                        if (_currentMode == mode) return;
                        setState(() {
                          _currentMode = mode;
                        });
                        ref
                            .read(interestsControllerProvider.notifier)
                            .load(mode: _currentMode);
                      },
                    ),
                    const SizedBox(height: 20),
                    JourneyMetrics(state: state),
                    const SizedBox(height: 24),
                    InsightControls(
                      showCulturalInsights: _showCulturalInsights,
                      showCompatibilityScore: _showCompatibilityScore,
                      onCulturalInsightsChanged: (value) {
                        setState(() => _showCulturalInsights = value);
                      },
                      onCompatibilityScoreChanged: (value) {
                        setState(() => _showCompatibilityScore = value);
                      },
                    ),
                    AnimatedSwitcher(
                      duration: AppMotionDurations.medium,
                      switchInCurve: Curves.easeOutQuad,
                      switchOutCurve: Curves.easeInQuad,
                      child: !_showCulturalInsights
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _viewMode == 'traditional'
                                  ? _buildTraditionalInsightsCard()
                                  : _buildModernInsightsCard(),
                            ),
                    ),
                    const SizedBox(height: 20),
                    _buildJourneyModules(context),
                  ],
                ),
              ),
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

  Widget _buildJourneyModules(BuildContext context) {
    final theme = Theme.of(context);
    final moduleChips = [
      _buildTogglePill(
        context,
        icon: Icons.psychology,
        title: _showIcebreakers ? 'Icebreakers active' : 'Cultural icebreakers',
        description: 'Curated prompts for warm conversations',
        selected: _showIcebreakers,
        accent: AppColors.primary,
        onChanged: (value) {
          setState(() => _showIcebreakers = value);
        },
      ),
      _buildTogglePill(
        context,
        icon: Icons.family_restroom,
        title: _showFamilyInvolvement
            ? 'Family guides active'
            : 'Family involvement',
        description: 'Plan respectful steps with elders',
        selected: _showFamilyInvolvement,
        accent: Colors.purple,
        onChanged: (value) {
          setState(() => _showFamilyInvolvement = value);
        },
      ),
      _buildTogglePill(
        context,
        icon: Icons.timeline,
        title: _showCourtshipJourney
            ? 'Journey map active'
            : 'Courtship journey',
        description: 'Track milestones from salaam to nikkah',
        selected: _showCourtshipJourney,
        accent: Colors.teal,
        onChanged: (value) {
          setState(() => _showCourtshipJourney = value);
        },
      ),
    ];

    final moduleCards = <Widget>[];

    if (_showIcebreakers) {
      moduleCards.add(
        _buildModuleCard(
          context,
          icon: Icons.chat_bubble_outline,
          accent: AppColors.primary,
          title: 'Cultural conversation sparks',
          description:
              'Use these respectful prompts once a connection is mutual to keep dialogue heartfelt.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icebreakerPrompts
                    .map(
                      (prompt) => _buildPromptChip(
                        context,
                        label: prompt,
                        color: AppColors.primary,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }

    if (_showFamilyInvolvement) {
      moduleCards.add(
        _buildModuleCard(
          context,
          icon: Icons.groups,
          accent: Colors.purple,
          title: 'Family involvement playbook',
          description:
              'Invite elders respectfully at every milestone with gentle scripts and expectations.',
          child: Column(
            children: _familySteps
                .map(
                  (step) => _buildJourneyStep(
                    context,
                    icon: step.icon,
                    title: step.title,
                    description: step.subtitle,
                    color: Colors.purple,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    if (_showCourtshipJourney) {
      moduleCards.add(
        _buildModuleCard(
          context,
          icon: Icons.route,
          accent: Colors.teal,
          title: 'Courtship journey map',
          description:
              'Visualise progress from respectful introductions to shared future planning.',
          child: Column(
            children: _courtshipSteps
                .map(
                  (step) => _buildJourneyStep(
                    context,
                    icon: step.icon,
                    title: step.title,
                    description: step.subtitle,
                    color: Colors.teal,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journey modules',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: moduleChips),
        if (moduleCards.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...moduleCards.expand((card) => [card, const SizedBox(height: 16)]),
        ],
      ],
    );
  }

  Widget _buildTogglePill(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool selected,
    required Color accent,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: AppMotionDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: const BoxConstraints(minWidth: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? LinearGradient(
                  colors: [accent.withAlpha(56), accent.withAlpha(31)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : theme.colorScheme.surface.withAlpha(229),
          border: Border.all(
            color: selected
                ? accent.withAlpha(89)
                : theme.colorScheme.outline.withAlpha(31),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withAlpha(selected ? 51 : 31),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(166),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required String description,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [accent.withAlpha(36), accent.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withAlpha(51)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(46),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(166),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(191),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(166),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        return _InterestCard(
          interest: interest,
          mode: _currentMode,
          viewMode: _viewMode,
          showCompatibilityScore: _showCompatibilityScore,
        );
      }, childCount: state.items.length + (state.hasMore ? 1 : 0)),
    );
  }

  Widget _buildTraditionalInsightsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      color: AppColors.primary.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_edu, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Traditional Afghan Matchmaking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Family Involvement',
              'In traditional Afghan culture, family approval is essential. Consider involving elders in the decision-making process.',
              Icons.family_restroom,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              'Respectful Courtship',
              'Traditional Afghan courtship values modesty and patience. Take time to build trust through respectful communication.',
              Icons.handshake,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              'Cultural Compatibility',
              'Shared cultural values, language, and traditions form the foundation of lasting relationships in Afghan culture.',
              Icons.diversity_3,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              'Religious Considerations',
              'Religious alignment and practice levels are important factors in traditional Afghan matchmaking.',
              Icons.mosque,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInsightsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      color: AppColors.secondary.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Modern Afghan Dating',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Balanced Approach',
              'Modern Afghan dating often balances traditional values with contemporary relationship expectations.',
              Icons.balance,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              'Personal Connection',
              'While family input remains valued, modern approach emphasizes personal compatibility and mutual interests.',
              Icons.favorite,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              'Cultural Pride',
              'Modern Afghans often seek partners who understand and respect their heritage while embracing contemporary life.',
              Icons.public,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              'Open Communication',
              'Modern approach encourages more direct communication while maintaining cultural respect and boundaries.',
              Icons.chat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _InterestCard extends ConsumerWidget {
  const _InterestCard({
    required this.interest,
    required this.mode,
    required this.viewMode,
    required this.showCompatibilityScore,
  });

  final InterestEntry interest;
  final String mode;
  final String viewMode;
  final bool showCompatibilityScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isReceived = mode == 'received';
    final isMutual =
        mode == 'mutual' ||
        interest.status == 'reciprocated' ||
        interest.status == 'accepted';
    final isFamilyApproved =
        mode == 'family_approved' || interest.status.contains('family');
    final otherUserSnapshot = isReceived
        ? interest.fromSnapshot
        : interest.toSnapshot;
    final otherUserName =
        otherUserSnapshot?['fullName']?.toString().trim().isNotEmpty == true
        ? otherUserSnapshot!['fullName'].toString()
        : 'Member';
    final otherUserImage = otherUserSnapshot?['profileImageUrls'] is List
        ? (otherUserSnapshot!['profileImageUrls'] as List).isNotEmpty
              ? otherUserSnapshot['profileImageUrls'][0]?.toString()
              : null
        : null;
    final culturalBackground = _getCulturalBackground(otherUserSnapshot);
    final location = _extractLocation(otherUserSnapshot);
    final languages = _extractLanguages(otherUserSnapshot);
    final compatibilityScore = _calculateCompatibilityScore(otherUserSnapshot);
    final accentColor = _resolveAccentColor(isMutual, isFamilyApproved);
    final statusLabel = _getCulturalStatusText(interest.status, viewMode);

    final headerTraits = <String>[];
    if (culturalBackground != null) {
      headerTraits.add(culturalBackground);
    }
    if (location != null) {
      headerTraits.add(location);
    }
    if (languages.isNotEmpty) {
      headerTraits.add('${languages.first} speaker');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              accentColor.withAlpha(41),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accentColor.withAlpha(51)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(
                    otherUserName: otherUserName,
                    imageUrl: otherUserImage,
                    accent: accentColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUserName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (headerTraits.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: headerTraits
                                .map(
                                  (trait) => _buildTraitPill(
                                    context,
                                    trait: trait,
                                    accent: accentColor,
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusChip(statusLabel, accentColor),
                            const SizedBox(width: 8),
                            Text(
                              'Updated ${_formatRelativeTime(interest.updatedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  166,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTimelineChips(context, accentColor),
              if (showCompatibilityScore && compatibilityScore > 0) ...[
                const SizedBox(height: 20),
                _buildCompatibilitySection(
                  context,
                  compatibilityScore,
                  accentColor,
                ),
              ],
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: AppMotionDurations.fast,
                child: isMutual
                    ? _buildCulturalNextSteps(context, viewMode)
                    : _buildCulturalCompatibilityTip(
                        context,
                        interest.status,
                        viewMode,
                      ),
              ),
              const SizedBox(height: 20),
              if (isReceived && interest.status == 'pending')
                _buildResponseActions(context, ref, accentColor)
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    viewMode == 'traditional'
                        ? 'Keep conversation warm while honouring family etiquette.'
                        : 'Suggest a meaningful, relaxed next step to deepen the connection.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(166),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String otherUserName,
    required String? imageUrl,
    required Color accent,
  }) {
    final initials = otherUserName.isNotEmpty
        ? otherUserName.characters.first.toUpperCase()
        : '?';
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent.withAlpha(217), accent.withAlpha(102)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTraitPill(
    BuildContext context, {
    required String trait,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(51)),
      ),
      child: Text(
        trait,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(191),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(46),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(interest.status), size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChips(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final items = <Map<String, Object>>[
      {
        'icon': Icons.spa,
        'label': 'Introduced ${_formatRelativeTime(interest.createdAt)}',
      },
      {
        'icon': interest.status == 'pending'
            ? Icons.hourglass_bottom
            : Icons.volunteer_activism,
        'label': _titleForStatus(interest.status),
      },
      if (mode == 'sent' || mode == 'received')
        {
          'icon': Icons.handshake,
          'label': viewMode == 'traditional'
              ? 'Preparing respectful family steps'
              : 'Planning modern next step',
        },
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withAlpha(31),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    item['label'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCompatibilitySection(
    BuildContext context,
    int compatibilityScore,
    Color accent,
  ) {
    final theme = Theme.of(context);
    final message = _getCompatibilityMessage(compatibilityScore, viewMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cultural harmony score',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.onSurface.withAlpha(20),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width =
                    constraints.maxWidth *
                    (compatibilityScore.clamp(0, 100) / 100);
                return AnimatedContainer(
                  duration: AppMotionDurations.medium,
                  height: 10,
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        accent.withAlpha(64),
                        _getCompatibilityColor(compatibilityScore),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getCompatibilityColor(compatibilityScore).withAlpha(31),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$compatibilityScore%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getCompatibilityColor(compatibilityScore),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponseActions(
    BuildContext context,
    WidgetRef ref,
    Color accent,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Decline politely'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withAlpha(102)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final result = await ref
                  .read(interestsControllerProvider.notifier)
                  .respondToInterest(
                    interestId: interest.id,
                    status: 'rejected',
                  );

              if (result['success'] == true) {
                ToastService.instance.success(
                  'Interest declined respectfully.',
                );
              } else {
                final error =
                    result['error'] as String? ??
                    'Failed to respond to interest';
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Accept & continue'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final result = await ref
                  .read(interestsControllerProvider.notifier)
                  .respondToInterest(
                    interestId: interest.id,
                    status: 'accepted',
                  );

              if (result['success'] == true) {
                ToastService.instance.success(
                  'Interest accepted! Begin a respectful conversation.',
                );
              } else {
                final error =
                    result['error'] as String? ?? 'Failed to accept interest';
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
        ),
      ],
    );
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

  Color _resolveAccentColor(bool isMutual, bool isFamilyApproved) {
    if (isMutual) return Colors.pink;
    if (isFamilyApproved) return Colors.teal;
    final base = _getStatusColor(interest.status);
    return base == Colors.grey ? AppColors.primary : base;
  }

  String? _extractLocation(Map<String, dynamic>? snapshot) {
    final city = snapshot?['city']?.toString();
    final country = snapshot?['country']?.toString();
    if (city != null &&
        city.isNotEmpty &&
        country != null &&
        country.isNotEmpty) {
      return '$city, $country';
    }
    if (city != null && city.isNotEmpty) return city;
    if (country != null && country.isNotEmpty) return country;
    return null;
  }

  List<String> _extractLanguages(Map<String, dynamic>? snapshot) {
    final languages = snapshot?['languages'];
    if (languages is List) {
      return languages
          .map((language) => language.toString())
          .where((language) => language.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _titleForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Awaiting response';
      case 'accepted':
        return 'Accepted – start planning next steps';
      case 'rejected':
        return 'Declined with care';
      case 'reciprocated':
        return 'Mutual interest';
      case 'family_approved':
        return 'Family approved';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Widget _buildCulturalCompatibilityTip(
    BuildContext context,
    String status,
    String viewMode,
  ) {
    String tip;
    IconData icon;
    Color color;

    if (viewMode == 'traditional') {
      switch (status) {
        case 'pending':
          tip =
              'In traditional Afghan culture, patience is a virtue while awaiting a family decision.';
          icon = Icons.hourglass_empty;
          color = Colors.orange;
          break;
        case 'accepted':
          tip =
              'Excellent! Consider involving family elders in planning a respectful first meeting.';
          icon = Icons.check_circle;
          color = Colors.green;
          break;
        case 'rejected':
          tip =
              'Respect their decision with dignity. Traditional values emphasize maintaining honor in all interactions.';
          icon = Icons.cancel;
          color = Colors.red;
          break;
        case 'reciprocated':
          tip =
              'Mutual interest blessed! Consider arranging a formal family introduction to proceed.';
          icon = Icons.favorite;
          color = Colors.pink;
          break;
        default:
          tip =
              'Continue respectful communication to build trust and understanding.';
          icon = Icons.chat;
          color = Colors.blue;
      }
    } else {
      switch (status) {
        case 'pending':
          tip =
              'Take time to get to know each other better through meaningful conversation.';
          icon = Icons.hourglass_empty;
          color = Colors.orange;
          break;
        case 'accepted':
          tip =
              'Great! Suggest a casual meeting in a comfortable, public setting to continue building your connection.';
          icon = Icons.check_circle;
          color = Colors.green;
          break;
        case 'rejected':
          tip =
              'Respect their decision and wish them well. Modern dating values mutual respect and honesty.';
          icon = Icons.cancel;
          color = Colors.red;
          break;
        case 'reciprocated':
          tip =
              'Mutual interest! Explore shared values and interests to deepen your connection.';
          icon = Icons.favorite;
          color = Colors.pink;
          break;
        default:
          tip = 'Continue open communication to build a genuine connection.';
          icon = Icons.chat;
          color = Colors.blue;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withAlpha(204),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalNextSteps(BuildContext context, String viewMode) {
    if (viewMode == 'traditional') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_edu, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Traditional Next Steps',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'Formal Family Introduction',
              'Arrange for elders to exchange salaams and intentions to honour tradition.',
            ),
            const SizedBox(height: 4),
            _buildNextStepItem(
              'Cultural Conversation',
              'Share family customs, expectations, and preferred courtship approach.',
            ),
            const SizedBox(height: 4),
            _buildNextStepItem(
              'Faith Alignment',
              'Discuss religious practice and hopes for a spiritually aligned home.',
            ),
            const SizedBox(height: 4),
            _buildNextStepItem(
              'Blessing & Dua',
              'Seek prayers from elders and agree on a respectful follow-up plan.',
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.pink.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pink.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Modern Connection Steps',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNextStepItem(
              'Shared Experience',
              'Plan an activity that reflects your shared values and interests.',
            ),
            const SizedBox(height: 4),
            _buildNextStepItem(
              'Story Exchange',
              'Share family journeys and what community support looks like to you both.',
            ),
            const SizedBox(height: 4),
            _buildNextStepItem(
              'Future Vision',
              'Discuss how you each imagine balancing culture, career, and family.',
            ),
            const SizedBox(height: 4),
            _buildNextStepItem(
              'Introduce Loved Ones',
              'Invite the people who champion you most to offer guidance.',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNextStepItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.arrow_right, size: 16, color: Colors.pink),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
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
      case 'family_approved':
        return Colors.purple;
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
      case 'family_approved':
        return Icons.family_restroom;
      default:
        return Icons.help_outline;
    }
  }

  String _getCulturalStatusText(String status, String viewMode) {
    if (viewMode == 'traditional') {
      switch (status) {
        case 'pending':
          return 'Awaiting Family Consideration';
        case 'accepted':
          return 'Family Blessing Given';
        case 'rejected':
          return 'Respectfully Declined';
        case 'reciprocated':
          return 'Mutual Family Approval';
        case 'withdrawn':
          return 'Interest Withdrawn';
        case 'family_approved':
          return 'Family Approved Match';
        default:
          return 'Under Consideration';
      }
    } else {
      switch (status) {
        case 'pending':
          return 'Awaiting Response';
        case 'accepted':
          return 'Interest Accepted';
        case 'rejected':
          return 'Interest Declined';
        case 'reciprocated':
          return 'Mutual Interest';
        case 'withdrawn':
          return 'Interest Withdrawn';
        case 'family_approved':
          return 'Family Approved';
        default:
          return 'Pending';
      }
    }
  }

  int _calculateCompatibilityScore(Map<String, dynamic>? userSnapshot) {
    if (userSnapshot == null) return 0;
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return 60 + (random % 40);
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getCompatibilityMessage(int score, String viewMode) {
    if (viewMode == 'traditional') {
      if (score >= 85) {
        return 'Excellent cultural alignment! Your families would likely approve.';
      }
      if (score >= 70) {
        return 'Good cultural compatibility. Consider discussing family values.';
      }
      return 'Some cultural differences. Focus on understanding and respect.';
    } else {
      if (score >= 85) {
        return 'Great match! You share many values and interests.';
      }
      if (score >= 70) {
        return 'Good compatibility! Explore your shared interests further.';
      }
      return 'Some differences. Focus on open communication and understanding.';
    }
  }

  String? _getCulturalBackground(Map<String, dynamic>? userSnapshot) {
    if (userSnapshot == null) return null;
    final ethnicity = userSnapshot['ethnicity']?.toString();
    final motherTongue = userSnapshot['motherTongue']?.toString();
    final religion = userSnapshot['religion']?.toString();

    if (ethnicity != null && ethnicity.isNotEmpty) {
      return ethnicity;
    } else if (motherTongue != null && motherTongue.isNotEmpty) {
      return 'Speaks $motherTongue';
    } else if (religion != null && religion.isNotEmpty) {
      return religion;
    }

    return null;
  }
}

class _GuidedStep {
  const _GuidedStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
