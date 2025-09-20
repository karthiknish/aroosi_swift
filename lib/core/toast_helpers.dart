import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/core/toast_service.dart';

/// Toast helper extensions for easy access in widgets
extension ToastHelper on WidgetRef {
  ToastService get toast => read(toastServiceProvider);

  /// Quick access to common toast methods
  void showError(dynamic error, [String fallback = "Something went wrong. Please try again."]) {
    toast.errorToast(error, fallback: fallback);
  }

  void showSuccess(String message) {
    toast.success(message);
  }

  void showInfo(String message) {
    toast.info(message);
  }

  void showWarning(String message) {
    toast.warning(message);
  }

  void showPrimary(String message) {
    toast.primary(message);
  }

  void showUndo(String message, VoidCallback onUndo, {String actionLabel = "Undo"}) {
    toast.successWithUndo(message, onUndo, actionLabel: actionLabel);
  }

  void showCopiedToClipboard() {
    toast.copiedToClipboard();
  }

  void showOperationSuccess(String operation) {
    toast.operationSuccess(operation);
  }

  void showOperationFailed(String operation, {String? details, VoidCallback? onRetry}) {
    toast.serverError(operation: operation, onRetry: onRetry);
  }

  void showNetworkError({String? operation, VoidCallback? onRetry}) {
    toast.networkError(operation: operation, onRetry: onRetry);
  }

  void showAuthError({String? operation, VoidCallback? onRetry}) {
    toast.authError(operation: operation, onRetry: onRetry);
  }

  void showPermissionError({String? operation, VoidCallback? onRetry}) {
    toast.permissionError(operation: operation, onRetry: onRetry);
  }

  void showValidationError(String message, {VoidCallback? onRetry}) {
    toast.validationError(message, onRetry: onRetry);
  }

  void showRetryableError(String message, VoidCallback onRetry) {
    toast.retryableError(message, onRetry: onRetry);
  }
}

/// Toast helper mixin for state notifiers
mixin ToastMixin {
  ToastService get toast => ToastService.instance;

  void showErrorToast(dynamic error, [String fallback = "Something went wrong. Please try again."]) {
    toast.errorToast(error, fallback: fallback);
  }

  void showSuccessToast(String message) {
    toast.success(message);
  }

  void showInfoToast(String message) {
    toast.info(message);
  }

  void showWarningToast(String message) {
    toast.warning(message);
  }

  void showPrimaryToast(String message) {
    toast.primary(message);
  }

  void showUndoToast(String message, VoidCallback onUndo, {String actionLabel = "Undo"}) {
    toast.successWithUndo(message, onUndo, actionLabel: actionLabel);
  }

  void showCopiedToClipboardToast() {
    toast.copiedToClipboard();
  }

  void showOperationSuccessToast(String operation) {
    toast.operationSuccess(operation);
  }

  void showOperationFailedToast(String operation, {String? details, VoidCallback? onRetry}) {
    toast.serverError(operation: operation, onRetry: onRetry);
  }

  void showNetworkErrorToast({String? operation, VoidCallback? onRetry}) {
    toast.networkError(operation: operation, onRetry: onRetry);
  }

  void showAuthErrorToast({String? operation, VoidCallback? onRetry}) {
    toast.authError(operation: operation, onRetry: onRetry);
  }

  void showPermissionErrorToast({String? operation, VoidCallback? onRetry}) {
    toast.permissionError(operation: operation, onRetry: onRetry);
  }

  void showValidationErrorToast(String message, {VoidCallback? onRetry}) {
    toast.validationError(message, onRetry: onRetry);
  }

  void showRetryableErrorToast(String message, VoidCallback onRetry) {
    toast.retryableError(message, onRetry: onRetry);
  }
}

/// Error handling wrapper for async operations with toast notifications
class ToastErrorHandler {
  static Future<T> handle<T>(
    Future<T> Function() operation, {
    String? operationName,
    VoidCallback? onRetry,
    bool showRetry = true,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final toast = ToastService.instance;

      if (showRetry && onRetry != null) {
        toast.retryableError(
          operationName != null ? 'Failed to $operationName' : 'Operation failed',
          onRetry: onRetry,
        );
      } else {
        toast.errorToast(
          e,
          fallback: operationName != null
              ? 'Failed to $operationName. Please try again.'
              : 'Something went wrong. Please try again.',
        );
      }
      rethrow;
    }
  }

  static Future<void> handleVoid(
    Future<void> Function() operation, {
    String? operationName,
    VoidCallback? onRetry,
    bool showRetry = true,
  }) async {
    try {
      await operation();
    } catch (e) {
      final toast = ToastService.instance;

      if (showRetry && onRetry != null) {
        toast.retryableError(
          operationName != null ? 'Failed to $operationName' : 'Operation failed',
          onRetry: onRetry,
        );
      } else {
        toast.errorToast(
          e,
          fallback: operationName != null
              ? 'Failed to $operationName. Please try again.'
              : 'Something went wrong. Please try again.',
        );
      }
      rethrow;
    }
  }
}

/// Toast utility for common app operations
class AppToastUtils {
  static void showProfileAction(String action, String profileName) {
    final toast = ToastService.instance;
    toast.success('$action for $profileName');
  }

  static void showInterestAction(String action, String userName) {
    final toast = ToastService.instance;
    toast.success('Interest $action for $userName');
  }

  static void showMessageAction(String action, String userName) {
    final toast = ToastService.instance;
    toast.success('Message $action to $userName');
  }

  static void showFeatureUnavailable(String feature) {
    final toast = ToastService.instance;
    toast.warning('Upgrade to Premium to use $feature');
  }

  static void showComingSoon(String feature) {
    final toast = ToastService.instance;
    toast.info('$feature coming soon');
  }

  static void showMaintenanceMode() {
    final toast = ToastService.instance;
    toast.warning('System is under maintenance. Please try again later');
  }

  static void showWelcomeBack() {
    final toast = ToastService.instance;
    toast.primary('Welcome back! 🎉');
  }

  static void showOnboardingRequired() {
    final toast = ToastService.instance;
    toast.warning('Please finish onboarding to continue');
  }

  static void showSessionExpired() {
    final toast = ToastService.instance;
    toast.authError(operation: 'access this feature');
  }
}
