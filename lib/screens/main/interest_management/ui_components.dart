import 'package:flutter/material.dart';

/// Avatar widget for displaying user profile images with fallback to initials
class InterestAvatar extends StatelessWidget {
  final String otherUserName;
  final String? imageUrl;
  final Color accent;

  const InterestAvatar({
    super.key,
    required this.otherUserName,
    required this.imageUrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
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
              ? Image.network(imageUrl!, fit: BoxFit.cover)
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
}

/// Trait pill widget for displaying user characteristics
class TraitPill extends StatelessWidget {
  final String trait;
  final Color accent;

  const TraitPill({super.key, required this.trait, required this.accent});

  @override
  Widget build(BuildContext context) {
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
}

/// Status chip widget for displaying interest status
class StatusChip extends StatelessWidget {
  final String label;
  final Color accent;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(46),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: accent),
          ),
        ],
      ),
    );
  }
}

/// Timeline chips widget for showing interaction timeline
class TimelineChips extends StatelessWidget {
  final Color accent;
  final List<Map<String, Object>> timelineItems;

  const TimelineChips({
    super.key,
    required this.accent,
    required this.timelineItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: timelineItems.map((item) {
        final icon = item['icon'] as IconData;
        final label = item['label'] as String;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withAlpha(38)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: accent.withAlpha(204),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
