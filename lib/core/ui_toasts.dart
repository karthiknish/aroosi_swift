import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:aroosi_flutter/core/toast_service.dart';

/// Toast helper functions that match the React app patterns
/// These provide easy-to-use methods for common toast scenarios

/// Error toast with fallback message (matches React app showErrorToast)
void showErrorToast(dynamic error, [String fallback = "Something went wrong. Please try again."]) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.errorToast(error, fallback: fallback);
}

/// Success toast (matches React app showSuccessToast)
void showSuccessToast(String message) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.success(message);
}

/// Success toast with undo functionality (matches React app showUndoToast)
void showUndoToast(String message, VoidCallback onUndo, {String actionLabel = "Undo", Duration duration = const Duration(milliseconds: 6000)}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.successWithUndo(message, onUndo, actionLabel: actionLabel, duration: duration);
}

/// Info toast (matches React app showInfoToast)
void showInfoToast(String message) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.info(message);
}

/// Warning toast (matches React app showWarningToast)
void showWarningToast(String message) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.warning(message);
}

/// Primary branded toast for special announcements (matches React app showPrimaryToast)
void showPrimaryToast(String message) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.primary(message);
}

/// Common toast patterns from React app

/// Push notification related toasts
void showNotificationSentToast(bool isTest) {
  showSuccessToast(isTest ? "Test notification sent successfully" : "Push notification sent successfully");
}

void showNotificationPreviewToast() {
  showSuccessToast("Preview generated successfully");
}

void showTemplateSavedToast() {
  showSuccessToast("Template saved");
}

void showTemplateAppliedToast() {
  showSuccessToast("Template applied");
}

void showTemplateDeletedToast() {
  showSuccessToast("Template deleted successfully");
}

/// Email/marketing related toasts
void showEmailSentToast(bool isTest) {
  showSuccessToast(isTest ? "Test email sent successfully" : "Email queued for delivery");
}

void showEmailPreviewToast() {
  showSuccessToast("Email preview generated");
}

void showCampaignStartedToast() {
  showSuccessToast("Campaign started. Emails are being sent.");
}

/// Profile related toasts
void showProfileDeletedToast() {
  showSuccessToast("Profile deleted");
}

void showInterestSentToast() {
  showSuccessToast("Interest sent successfully!");
}

void showInterestWithdrawnToast() {
  showSuccessToast("Interest withdrawn successfully!");
}

/// File operations toasts
void showCopiedToClipboardToast() {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.copiedToClipboard();
}

void showFileExportedToast(String fileType) {
  showSuccessToast("$fileType exported successfully");
}

/// Generic operation toasts
void showSavedToast(String operation) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.operationSuccess("Saved $operation");
}

void showUpdatedToast(String operation) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.operationSuccess("Updated $operation");
}

void showCreatedToast(String operation) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.operationSuccess("Created $operation");
}

void showDeletedToast(String operation) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.operationSuccess("Deleted $operation");
}

/// Error toasts for common operations
void showLoadFailedToast(String operation, {VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.serverError(
    operation: "load $operation",
    onRetry: onRetry,
  );
}

void showSaveFailedToast(String operation, {VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.serverError(
    operation: "save $operation",
    onRetry: onRetry,
  );
}

void showDeleteFailedToast(String operation, {VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.serverError(
    operation: "delete $operation",
    onRetry: onRetry,
  );
}

void showNetworkErrorToast({String? operation, VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.networkError(
    operation: operation,
    onRetry: onRetry,
  );
}

void showAuthErrorToast({String? operation, VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.authError(
    operation: operation,
    onRetry: onRetry,
  );
}

void showPermissionErrorToast({String? operation, VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.permissionError(
    operation: operation,
    onRetry: onRetry,
  );
}

/// Validation error toasts
void showValidationErrorToast(String message, {VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.validationError(message, onRetry: onRetry);
}

/// Retryable error toasts
void showRetryableErrorToast(String message, VoidCallback onRetry) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.retryableError(message, onRetry: onRetry);
}

/// Common validation error messages
void showRequiredFieldToast(String fieldName) {
  showValidationErrorToast("$fieldName is required");
}

void showInvalidEmailToast() {
  showValidationErrorToast("Invalid email address");
}

void showInvalidPasswordToast() {
  showValidationErrorToast("Password is too weak");
}

void showInvalidInputToast() {
  showValidationErrorToast("Invalid input format");
}

void showEmailExistsToast() {
  showErrorToast("An account with this email already exists");
}

void showAccountNotFoundToast() {
  showErrorToast("Account not found");
}

void showWrongPasswordToast() {
  showErrorToast("Incorrect email or password");
}

void showSessionExpiredToast() {
  showAuthErrorToast(operation: "access this feature");
}

void showTooManyAttemptsToast() {
  showWarningToast("Too many attempts. Please try again later");
}

void showPermissionDeniedToast(String operation) {
  showPermissionErrorToast(operation: operation);
}

void showNetworkTimeoutToast(String operation) {
  showNetworkErrorToast(operation: operation);
}

/// Admin-specific toasts
void showAdminOperationSuccess(String operation) {
  showPrimaryToast("Admin: $operation completed");
}

void showAdminOperationError(String operation, {VoidCallback? onRetry}) {
  final container = ProviderContainer();
  final toastService = container.read(toastServiceProvider);
  toastService.serverError(
    operation: "admin $operation",
    onRetry: onRetry,
  );
}

/// Special toast patterns
void showUpgradeRequiredToast(String feature) {
  showWarningToast("Upgrade to Premium to use $feature");
}

void showFeatureComingSoonToast(String feature) {
  showInfoToast("$feature coming soon");
}

void showMaintenanceToast() {
  showWarningToast("System is under maintenance. Please try again later");
}

void showWelcomeBackToast() {
  showPrimaryToast("Welcome back! 🎉");
}

void showOnboardingIncompleteToast() {
  showWarningToast("Please finish onboarding to continue");
}
