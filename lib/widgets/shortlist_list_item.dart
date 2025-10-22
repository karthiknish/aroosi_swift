import 'package:flutter/material.dart';
import 'package:aroosi_flutter/widgets/shimmer.dart';

import 'package:aroosi_flutter/features/profiles/models.dart';

class ShortlistListItem extends StatelessWidget {
  const ShortlistListItem({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final ShortlistEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  static const _placeholderAsset = 'assets/images/placeholder.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get the first image URL from the list, or null if empty
    final imageUrl = entry.profileImageUrls?.isNotEmpty == true
        ? entry.profileImageUrls!.first
        : null;

    // Extract age from fullName if possible (format: "Name, Age")
    String? age;
    String displayName = entry.fullName ?? 'Unknown';
    final commaIndex = entry.fullName?.lastIndexOf(',');
    if (commaIndex != null && commaIndex > 0) {
      final agePart = entry.fullName!.substring(commaIndex + 1).trim();
      if (agePart.isNotEmpty && int.tryParse(agePart) != null) {
        age = agePart;
        displayName = entry.fullName!.substring(0, commaIndex).trim();
      }
    }

    final subtitle = age != null ? 'Age $age' : '';

    final hasAvatar = imageUrl != null && imageUrl.trim().isNotEmpty;
    final avatar = hasAvatar
        ? FadeInImage.assetNetwork(
            placeholder: _placeholderAsset,
            image: imageUrl,
            fit: BoxFit.cover,
            imageErrorBuilder: (_, __, ___) =>
                Image.asset(_placeholderAsset, fit: BoxFit.cover),
          )
        : Image.asset(_placeholderAsset, fit: BoxFit.cover);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipOval(child: avatar),
          ),
          title: Text(displayName, style: theme.textTheme.bodyLarge),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          trailing: trailing,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
        if (entry.note != null && entry.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${entry.note}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ShortlistListSkeleton extends StatelessWidget {
  const ShortlistListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade300;
    final hilite = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade200;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Shimmer(
        baseColor: base,
        highlightColor: hilite,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: base, shape: BoxShape.circle),
          ),
          title: Container(height: 14, width: 180, color: base),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(height: 12, width: 140, color: hilite),
          ),
        ),
      ),
    );
  }
}
