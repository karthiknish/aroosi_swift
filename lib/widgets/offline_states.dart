import 'package:flutter/material.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';
import 'package:aroosi_flutter/widgets/error_states.dart';

/// A comprehensive offline state widget for connectivity issues
class OfflineState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final Widget? icon;
  final VoidCallback? onRetry;
  final VoidCallback? onCheckConnection;
  final bool showRetry;
  final bool showCheckConnection;
  final EdgeInsetsGeometry? padding;

  const OfflineState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.icon,
    this.onRetry,
    this.onCheckConnection,
    this.showRetry = true,
    this.showCheckConnection = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title ?? 'You\'re Offline',
      subtitle: subtitle ?? 'No internet connection detected',
      description: description ?? 'Please check your connection and try again',
      icon:
          icon ??
          Icon(Icons.wifi_off_outlined, size: 64, color: AppColors.warning),
      onRetryPressed: showRetry ? onRetry : null,
      action: showCheckConnection && onCheckConnection != null
          ? PrimaryButton(
              label: 'Check Connection',
              onPressed: onCheckConnection,
            )
          : null,
      padding: padding,
    );
  }
}

/// Offline state for when user can't load content due to connectivity
class OfflineContentState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onRetry;
  final VoidCallback? onGoOffline;

  const OfflineContentState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onRetry,
    this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    return OfflineState(
      title: title ?? 'Content Unavailable',
      subtitle: subtitle ?? 'Unable to load content while offline',
      description:
          description ?? 'Connect to the internet to access this content',
      onRetry: onRetry,
      onCheckConnection: onGoOffline,
    );
  }
}

/// Offline state for when user tries to perform an action that requires internet
class OfflineActionState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? actionName;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const OfflineActionState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.actionName,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_outlined, size: 64, color: AppColors.warning),
          const SizedBox(height: 16),
          Text(
            title ?? 'Internet Required',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            actionName != null
                ? 'This action requires an internet connection'
                : (subtitle ?? 'An internet connection is required'),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.muted),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              if (onCancel != null && onRetry != null)
                const SizedBox(width: 12),
              if (onRetry != null)
                Expanded(
                  child: PrimaryButton(label: 'Try Again', onPressed: onRetry),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Offline state for when user is viewing cached content
class CachedContentState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onRefresh;
  final bool showRefreshButton;

  const CachedContentState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.onRefresh,
    this.showRefreshButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? 'Viewing Cached Content',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ??
                      'You\'re currently offline. Some content may be outdated.',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
                if (showRefreshButton && onRefresh != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRefresh,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Refresh',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline state banner that can be shown at the top of screens
class OfflineBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDismissButton;

  const OfflineBanner({
    super.key,
    this.message,
    this.onRetry,
    this.onDismiss,
    this.showDismissButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? 'No internet connection',
              style: textTheme.bodySmall?.copyWith(color: AppColors.text),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(60, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (showDismissButton && onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: AppColors.muted, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}

/// Offline state for when user tries to sync data
class OfflineSyncState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final int? pendingItemsCount;
  final VoidCallback? onRetry;
  final VoidCallback? onSyncLater;

  const OfflineSyncState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.pendingItemsCount,
    this.onRetry,
    this.onSyncLater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sync_disabled_outlined,
            size: 64,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          Text(
            title ?? 'Sync Unavailable',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            pendingItemsCount != null
                ? '$pendingItemsCount items waiting to sync'
                : (subtitle ?? 'Unable to sync while offline'),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          if (onRetry != null || onSyncLater != null) ...[
            Row(
              children: [
                if (onSyncLater != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSyncLater,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.muted),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sync Later',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
                if (onSyncLater != null && onRetry != null)
                  const SizedBox(width: 12),
                if (onRetry != null)
                  Expanded(
                    child: PrimaryButton(
                      label: 'Try Again',
                      onPressed: onRetry,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
