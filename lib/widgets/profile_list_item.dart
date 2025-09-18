import 'package:flutter/material.dart';
import 'package:aroosi_flutter/widgets/shimmer.dart';

import 'package:aroosi_flutter/features/profiles/models.dart';

class ProfileListItem extends StatelessWidget {
  const ProfileListItem({
    super.key,
    required this.profile,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final ProfileSummary profile;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (profile.city != null && profile.city!.isNotEmpty) profile.city!,
      if (profile.age != null) '${profile.age}',
    ].join(' • ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
        child: profile.avatarUrl == null
            ? Text(profile.displayName.isNotEmpty ? profile.displayName.characters.first : '?')
            : null,
      ),
      title: Text(profile.displayName, style: theme.textTheme.bodyLarge),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class ProfileListSkeleton extends StatelessWidget {
  const ProfileListSkeleton({super.key});

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
