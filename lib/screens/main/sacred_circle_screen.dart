import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/widgets/app_scaffold.dart';
import 'package:aroosi_flutter/widgets/retryable_network_image.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';
import 'package:aroosi_flutter/theme/motion.dart';
import 'package:aroosi_flutter/l10n/app_localizations.dart';

class SacredCircleScreen extends ConsumerStatefulWidget {
  const SacredCircleScreen({super.key});

  @override
  ConsumerState<SacredCircleScreen> createState() => _SacredCircleScreenState();
}

class _SacredCircleScreenState extends ConsumerState<SacredCircleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  int _selectedProfileIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchesControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesState = ref.watch(matchesControllerProvider);

    return AppScaffold(
      title: 'Sacred Circle',
      child: SafeArea(
        child: matchesState.loading
            ? const _SacredCircleLoading()
            : matchesState.error != null
                ? ErrorStateWithRetry(
                    title: 'Connection Error',
                    subtitle: matchesState.error!,
                    onRetry: () => ref.read(matchesControllerProvider.notifier).refresh(),
                  )
                : _SacredCircleContent(
                    profiles: matchesState.items.map((match) => ProfileSummary(
                      id: match.otherUserId ?? '',
                      displayName: match.otherUserName ?? 'Unknown',
                      age: 25, // Default age since not available in MatchEntry
                      city: null, // Not available in MatchEntry
                      avatarUrl: match.otherUserImage,
                    )).toList(),
                    rotationAnimation: _rotationAnimation,
                    selectedIndex: _selectedProfileIndex,
                    onProfileSelected: (index) => setState(() => _selectedProfileIndex = index),
                    onProfileTap: (profile) => _showProfileDetails(context, profile),
                  ),
      ),
    );
  }

  void _showProfileDetails(BuildContext context, ProfileSummary profile) {
    // Navigate to profile details or compatibility screen
    context.push('/profile/${profile.id}');
  }
}

class _SacredCircleLoading extends StatelessWidget {
  const _SacredCircleLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(),
          ),
          SizedBox(height: 16),
          Text('Preparing your Sacred Circle...'),
        ],
      ),
    );
  }
}

class _SacredCircleContent extends StatefulWidget {
  const _SacredCircleContent({
    required this.profiles,
    required this.rotationAnimation,
    required this.selectedIndex,
    required this.onProfileSelected,
    required this.onProfileTap,
  });

  final List<ProfileSummary> profiles;
  final Animation<double> rotationAnimation;
  final int selectedIndex;
  final ValueChanged<int> onProfileSelected;
  final ValueChanged<ProfileSummary> onProfileTap;

  @override
  State<_SacredCircleContent> createState() => _SacredCircleContentState();
}

class _SacredCircleContentState extends State<_SacredCircleContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sacred Circle Header
        _buildHeader(context),

        // Sacred Circle Visualization
        Expanded(
          child: _buildSacredCircle(context),
        ),

        // Profile Details Card
        _buildProfileCard(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Family-Centric Title
          Text(
            l10n?.sacredCircleTitle ?? 'Family Sacred Circle',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Cultural Description
          Text(
            l10n?.sacredCircleSubtitle ?? 'Connect families through traditional values and cultural harmony',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Family Connection Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.family_restroom_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.profiles.length} ${l10n?.sacredCircleFamiliesConnected ?? 'Families Connected'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSacredCircle(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.profiles.isEmpty) {
      return _buildEmptyCircle(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing for different screen sizes
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // For iPad and larger screens, use a more generous size
            final maxCircleSize = math.min(screenWidth * 0.8, screenHeight * 0.6);
            final size = math.min(maxCircleSize, 400.0); // Cap at reasonable size

            return SizedBox(
              width: size,
              height: size,
              child: Stack(
              children: [
                // Rotating Outer Ring (Cultural Symbols)
                AnimatedBuilder(
                  animation: widget.rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: widget.rotationAnimation.value,
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: _CulturalRingPainter(),
                      ),
                    );
                  },
                ),

                // Profile Circles
                ...List.generate(widget.profiles.length, (index) {
                  final angle = (2 * math.pi * index) / widget.profiles.length;
                  final radius = size * 0.35;
                  final x = size / 2 + radius * math.cos(angle);
                  final y = size / 2 + radius * math.sin(angle);

                  return Positioned(
                    left: x - (MediaQuery.of(context).size.width > 600 ? 40 : 35),
                    top: y - (MediaQuery.of(context).size.width > 600 ? 40 : 35),
                    child: _ProfileCircle(
                      profile: widget.profiles[index],
                      isSelected: index == widget.selectedIndex,
                      onTap: () {
                        widget.onProfileSelected(index);
                        widget.onProfileTap(widget.profiles[index]);
                      },
                    ),
                  );
                }),

                // Center Family Unity Circle
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.family_restroom_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 28,
                        ),
                        const SizedBox(height: 2),
          Text(
            l10n?.sacredCircleFamilyUnity ?? 'Unity',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCircle(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Family Circle Awaits',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your family profile to connect\nwith families sharing your values and traditions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(Icons.family_restroom_rounded),
            label: Text(l10n?.profileCreateProfile ?? 'Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.profiles.isEmpty || widget.selectedIndex >= widget.profiles.length) {
      return const SizedBox.shrink();
    }

    final profile = widget.profiles[widget.selectedIndex];
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxWidth: 600, // Limit max width on large screens
        minWidth: 300, // Ensure minimum usable width
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Row(
            children: [
              // Profile Image - Responsive sizing
              Container(
                width: MediaQuery.of(context).size.width > 600 ? 80 : 60,
                height: MediaQuery.of(context).size.width > 600 ? 80 : 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: profile.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profile.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: profile.avatarUrl == null
                      ? theme.colorScheme.surfaceContainerHighest
                      : null,
                ),
                child: profile.avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // Family Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.displayName}\'s Family',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${profile.city ?? 'Location not specified'} • ${l10n?.sacredCircleCulturalHarmony ?? 'Cultural Harmony'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Cultural Harmony Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Cultural Harmony',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Family Values Compatibility
          Row(
            children: [
              Icon(
                Icons.diversity_3_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.sacredCircleCulturalHarmony ?? 'Cultural Harmony',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Strong Cultural Match',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Family-Focused Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/cultural/family-approval'),
                  icon: const Icon(Icons.family_restroom_rounded),
                  label: Text(l10n?.sacredCircleRequestFamilyIntroduction ?? 'Request Family Introduction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/cultural/supervised-conversation/initiate'),
                  icon: const Icon(Icons.chat_rounded),
                  label: Text(l10n?.sacredCircleBeginSupervisedCourtship ?? 'Begin Supervised Courtship'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: theme.colorScheme.primary),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

class _ProfileCircle extends StatelessWidget {
  const _ProfileCircle({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  final ProfileSummary profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotionDurations.medium,
        width: isSelected
            ? (MediaQuery.of(context).size.width > 600 ? 80 : 70)
            : (MediaQuery.of(context).size.width > 600 ? 70 : 60),
        height: isSelected
            ? (MediaQuery.of(context).size.width > 600 ? 80 : 70)
            : (MediaQuery.of(context).size.width > 600 ? 70 : 60),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: profile.avatarUrl != null
              ? RetryableNetworkImage(
                  url: profile.avatarUrl!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CulturalRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw traditional cultural symbols around the circle
    final symbols = ['🕌', '🌙', '🙏', '💒', '🌺', '⭐', '🕊️', '🌿'];
    for (int i = 0; i < symbols.length; i++) {
      final angle = (2 * math.pi * i) / symbols.length;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: symbols[i],
          style: const TextStyle(fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x - textPainter.width / 2, y - textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Draw subtle ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
