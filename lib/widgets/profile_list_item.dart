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

  static const _placeholderAsset = 'assets/images/placeholder.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (profile.city != null && profile.city!.isNotEmpty) profile.city!,
      if (profile.age != null) '${profile.age}',
    ].join(' • ');

    final hasAvatar =
        profile.avatarUrl != null && profile.avatarUrl!.trim().isNotEmpty;
    final avatar = hasAvatar
        ? FadeInImage.assetNetwork(
            placeholder: _placeholderAsset,
            image: profile.avatarUrl!,
            fit: BoxFit.cover,
            imageErrorBuilder: (_, __, ___) =>
                Image.asset(_placeholderAsset, fit: BoxFit.cover),
          )
        : Image.asset(_placeholderAsset, fit: BoxFit.cover);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(width: 48, height: 48, child: ClipOval(child: avatar)),
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
