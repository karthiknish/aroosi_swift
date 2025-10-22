import 'package:flutter/material.dart';
import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/widgets/primary_button.dart';

/// A comprehensive error state widget that can be customized for different error scenarios
class ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final String? errorMessage;
  final Widget? icon;
  final Widget? action;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final VoidCallback? onRetryPressed;
  final String? retryLabel;
  final bool showRetry;
  final bool showErrorDetails;
  final EdgeInsetsGeometry? padding;
  final double? spacing;

  const ErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.errorMessage,
    this.icon,
    this.action,
    this.onActionPressed,
    this.actionLabel,
    this.onRetryPressed,
    this.retryLabel,
    this.showRetry = true,
    this.showErrorDetails = false,
    this.padding,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: spacing! / 2),
            Text(
              subtitle!,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.text),
              textAlign: TextAlign.center,
            ),
          ],
          if (description != null) ...[
            SizedBox(height: spacing! / 2),
            Text(
              description!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
          if (errorMessage != null && showErrorDetails) ...[
            SizedBox(height: spacing! / 2),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                errorMessage!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          SizedBox(height: spacing! * 1.5),
          if (action != null)
            action!
          else ...[
            if (showRetry && onRetryPressed != null)
              PrimaryButton(
                label: retryLabel ?? 'Try Again',
                onPressed: onRetryPressed,
              ),
            if (onActionPressed != null && actionLabel != null) ...[
              if (showRetry && onRetryPressed != null)
                const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onActionPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Pre-built error state for network/connection errors
class NetworkErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showErrorDetails;

  const NetworkErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.errorMessage,
    this.onRetry,
    this.showErrorDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title ?? 'Connection Error',
      subtitle: subtitle ?? 'Unable to connect to the internet',
      description:
          description ?? 'Please check your internet connection and try again',
      errorMessage: errorMessage,
      icon: Icon(Icons.wifi_off_outlined, size: 64, color: AppColors.error),
      onRetryPressed: onRetry,
      showErrorDetails: showErrorDetails,
    );
  }
}

/// Pre-built error state for server errors
class ServerErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showErrorDetails;

  const ServerErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.errorMessage,
    this.onRetry,
    this.showErrorDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title ?? 'Server Error',
      subtitle: subtitle ?? 'Something went wrong on our end',
      description:
          description ?? 'Our team has been notified. Please try again later',
      errorMessage: errorMessage,
      icon: Icon(Icons.cloud_off_outlined, size: 64, color: AppColors.error),
      onRetryPressed: onRetry,
      showErrorDetails: showErrorDetails,
    );
  }
}

/// Pre-built error state for authentication errors
class AuthErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onLogin;
  final bool showErrorDetails;

  const AuthErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.errorMessage,
    this.onRetry,
    this.onLogin,
    this.showErrorDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title ?? 'Authentication Error',
      subtitle: subtitle ?? 'Your session has expired',
      description: description ?? 'Please log in again to continue',
      errorMessage: errorMessage,
      icon: Icon(Icons.lock_outline, size: 64, color: AppColors.error),
      showRetry: onRetry != null,
      onRetryPressed: onRetry,
      action: onLogin != null
          ? PrimaryButton(label: 'Log In', onPressed: onLogin)
          : null,
      showErrorDetails: showErrorDetails,
    );
  }
}

/// Pre-built error state for permission errors
class PermissionErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onGrantPermission;
  final bool showErrorDetails;

  const PermissionErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.errorMessage,
    this.onRetry,
    this.onGrantPermission,
    this.showErrorDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title ?? 'Permission Required',
      subtitle: subtitle ?? 'Access denied',
      description:
          description ?? 'Please grant the required permissions to continue',
      errorMessage: errorMessage,
      icon: Icon(Icons.security_outlined, size: 64, color: AppColors.error),
      onRetryPressed: onRetry,
      action: onGrantPermission != null
          ? PrimaryButton(
              label: 'Grant Permission',
              onPressed: onGrantPermission,
            )
          : null,
      showErrorDetails: showErrorDetails,
    );
  }
}

/// Pre-built error state for data loading errors
class DataLoadErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;
  final bool showErrorDetails;

  const DataLoadErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.errorMessage,
    this.onRetry,
    this.onRefresh,
    this.showErrorDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title ?? 'Failed to Load Data',
      subtitle: subtitle ?? 'Unable to load your content',
      description: description ?? 'Please try again to refresh your data',
      errorMessage: errorMessage,
      icon: Icon(Icons.refresh_outlined, size: 64, color: AppColors.error),
      onRetryPressed: onRetry ?? onRefresh,
      retryLabel: 'Refresh',
      showErrorDetails: showErrorDetails,
    );
  }
}

/// Pre-built error state for generic errors with customizable content
class GenericErrorState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? description;
  final String? errorMessage;
  final Widget? icon;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showErrorDetails;

  const GenericErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.description,
    this.errorMessage,
    this.icon,
    this.onRetry,
    this.onAction,
    this.actionLabel,
    this.showErrorDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title ?? 'Something went wrong',
      subtitle: subtitle ?? 'An unexpected error occurred',
      description:
          description ??
          'Please try again or contact support if the problem persists',
      errorMessage: errorMessage,
      icon: icon ?? Icon(Icons.error_outline, size: 64, color: AppColors.error),
      onRetryPressed: onRetry,
      onActionPressed: onAction,
      actionLabel: actionLabel,
      showErrorDetails: showErrorDetails,
    );
  }
}

/// A compact error widget for inline error display
class InlineError extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final bool showIcon;

  const InlineError({
    super.key,
    required this.error,
    this.onRetry,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (showIcon)
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
          if (showIcon) const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced error state with retry options and better styling
class ErrorStateWithRetry extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? retryLabel;
  final String? actionLabel;
  final Widget? icon;
  final bool showRetry;
  final bool showAction;

  const ErrorStateWithRetry({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.onRetry,
    this.onAction,
    this.retryLabel,
    this.actionLabel,
    this.icon,
    this.showRetry = true,
    this.showAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: 16),
          ] else ...[
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          if (showRetry && onRetry != null) ...[
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel ?? 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (showAction && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.outline),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel ?? 'Go Back',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
