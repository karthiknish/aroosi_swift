import 'package:flutter/cupertino.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/theme/typography.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';

/// A comprehensive empty state widget that can be customized for different scenarios
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final Widget? icon;
  final Widget? action;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final bool showAction;
  final double? spacing;
  final EdgeInsetsGeometry? padding;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.icon,
    this.action,
    this.onActionPressed,
    this.actionLabel,
    this.showAction = false,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, SizedBox(height: spacing!)],
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: spacing! / 2),
            Text(
              subtitle!,
              style: AppTypography.body.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
          if (description != null) ...[
            SizedBox(height: spacing! / 2),
            Text(
              description!,
              style: AppTypography.caption.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
          if (showAction) ...[
            SizedBox(height: spacing! * 1.5),
            if (action != null)
              action!
            else if (onActionPressed != null && actionLabel != null)
              PrimaryButton(label: actionLabel!, onPressed: onActionPressed),
          ],
        ],
      ),
    );
  }
}

/// Pre-built empty state for when there's no data
class NoDataEmptyState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onRefresh;
  final String? refreshLabel;

  const NoDataEmptyState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onRefresh,
    this.refreshLabel,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'No data found',
      subtitle: subtitle ?? 'There are no items to display',
      description: description,
      icon: Icon(CupertinoIcons.tray, size: 64, color: AppColors.muted),
      showAction: onRefresh != null,
      onActionPressed: onRefresh,
      actionLabel: refreshLabel ?? 'Refresh',
    );
  }
}

/// Pre-built empty state for empty lists
class EmptyListState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyListState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'No items yet',
      subtitle: subtitle ?? 'Your list is empty',
      description: description ?? 'Add some items to get started',
      icon: Icon(CupertinoIcons.list_bullet, size: 64, color: AppColors.muted),
      showAction: onAction != null,
      onActionPressed: onAction,
      actionLabel: actionLabel ?? 'Add Item',
    );
  }
}

/// Pre-built empty state for empty search results
class EmptySearchState extends StatelessWidget {
  final String? searchQuery;
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onClearSearch;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptySearchState({
    super.key,
    this.searchQuery,
    this.title,
    this.subtitle,
    this.description,
    this.onClearSearch,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'No results found',
      subtitle: searchQuery != null
          ? 'No results for "$searchQuery"'
          : (subtitle ?? 'Try adjusting your search'),
      description:
          description ?? 'Try different keywords or check your spelling',
      icon: Icon(CupertinoIcons.clear, size: 64, color: AppColors.muted),
      showAction: onAction != null,
      onActionPressed: onAction,
      actionLabel: actionLabel ?? 'Clear Search',
    );
  }
}

/// Pre-built empty state for empty favorites
class EmptyFavoritesState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onExplore;

  const EmptyFavoritesState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'No favorites yet',
      subtitle: subtitle ?? 'Your favorites list is empty',
      description:
          description ?? 'Add some items to your favorites to see them here',
      icon: Icon(
        CupertinoIcons.heart,
        size: 64,
        color: AppColors.muted,
      ),
      showAction: onExplore != null,
      onActionPressed: onExplore,
      actionLabel: 'Explore',
    );
  }
}

/// Pre-built empty state for empty shortlists
class EmptyShortlistState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onExplore;

  const EmptyShortlistState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'No shortlisted items',
      subtitle: subtitle ?? 'Your shortlist is empty',
      description:
          description ?? 'Add items to your shortlist to see them here',
      icon: Icon(
        CupertinoIcons.bookmark,
        size: 64,
        color: AppColors.muted,
      ),
      showAction: onExplore != null,
      onActionPressed: onExplore,
      actionLabel: 'Browse Items',
    );
  }
}

/// Pre-built empty state for empty matches
class EmptyMatchesState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onExplore;
  final VoidCallback? onImproveProfile;

  const EmptyMatchesState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onExplore,
    this.onImproveProfile,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'Your Journey Begins',
      subtitle: subtitle ?? 'Find meaningful connections that honor your values',
      description:
          description ??
          'Complete your profile and start exploring. Every great relationship begins with a single conversation.',
      icon: Icon(
        CupertinoIcons.heart,
        size: 64,
        color: AppColors.primary.withAlpha(179),
      ),
      showAction: true,
      action: Column(
        children: [
          if (onExplore != null)
            PrimaryButton(
              label: 'Start Exploring',
              onPressed: onExplore,
            ),
          if (onImproveProfile != null) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: onImproveProfile,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.pencil, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Complete Profile',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pre-built empty state for empty chats/conversations
class EmptyChatState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onExplore;

  const EmptyChatState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'No conversations yet',
      subtitle: subtitle ?? 'Your messages will appear here',
      description: description ?? 'Start a conversation to see your chats',
      icon: Icon(
        CupertinoIcons.chat_bubble_text,
        size: 64,
        color: AppColors.muted,
      ),
      showAction: onExplore != null,
      onActionPressed: onExplore,
      actionLabel: 'Find Someone to Chat',
    );
  }
}

/// Pre-built empty state for empty notifications
class EmptyNotificationsState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;

  const EmptyNotificationsState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title ?? 'No notifications',
      subtitle: subtitle ?? 'You\'re all caught up',
      description: description ?? 'New notifications will appear here',
      icon: Icon(
        CupertinoIcons.bell,
        size: 64,
        color: AppColors.muted,
      ),
    );
  }
}
