// Example usage of the enhanced toast system
// This file demonstrates how to use the new toast functionality

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/core/toast_service.dart';
import 'package:aroosi_flutter/core/ui_toasts.dart';
import 'package:aroosi_flutter/core/toast_helpers.dart';

// Example 1: Using the basic toast methods
class ToastExample1 extends ConsumerWidget {
  const ToastExample1({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Toast Usage')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Show Error Toast'),
            onTap: () => showErrorToast('This is an error message'),
          ),
          ListTile(
            title: const Text('Show Success Toast'),
            onTap: () => showSuccessToast('Operation completed successfully!'),
          ),
          ListTile(
            title: const Text('Show Info Toast'),
            onTap: () => showInfoToast('This is an informational message'),
          ),
          ListTile(
            title: const Text('Show Warning Toast'),
            onTap: () => showWarningToast('This is a warning message'),
          ),
          ListTile(
            title: const Text('Show Primary Toast'),
            onTap: () => showPrimaryToast('This is a special announcement!'),
          ),
          ListTile(
            title: const Text('Show Undo Toast'),
            onTap: () => showUndoToast(
              'Item deleted',
              () => debugPrint('Undo action triggered'),
            ),
          ),
        ],
      ),
    );
  }
}

// Example 2: Using the WidgetRef extension
class ToastExample2 extends ConsumerWidget {
  const ToastExample2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('WidgetRef Toast Extension')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Show Success'),
            onTap: () => ref.showSuccess('Profile updated successfully!'),
          ),
          ListTile(
            title: const Text('Show Network Error'),
            onTap: () => ref.showNetworkError(
              operation: 'load profiles',
              onRetry: () => debugPrint('Retry loading profiles'),
            ),
          ),
          ListTile(
            title: const Text('Show Validation Error'),
            onTap: () => ref.showValidationError('Email address is required'),
          ),
          ListTile(
            title: const Text('Show Copied to Clipboard'),
            onTap: () => ref.showCopiedToClipboard(),
          ),
        ],
      ),
    );
  }
}

// Example 3: Simple notifier example (commented due to StateNotifier issues)
// class ExampleNotifier extends StateNotifier<String> {
//   ExampleNotifier() : super('');
//
//   Future<void> performOperation() async {
//     try {
//       // Simulate some operation
//       await Future.delayed(const Duration(seconds: 1));
//       state = 'Operation completed';
//       showSuccessToast('Operation completed successfully!');
//     } catch (e) {
//       showErrorToast('Failed to perform operation');
//     }
//   }
//
//   void deleteItem() {
//     showUndoToast(
//       'Item deleted',
//       () => debugPrint('Undo delete triggered'),
//       actionLabel: 'Restore',
//     );
//   }
// }

// Example 4: Using AppToastUtils for common patterns
class ToastExample4 extends ConsumerWidget {
  const ToastExample4({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('AppToastUtils Examples')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Profile Action Success'),
            onTap: () => AppToastUtils.showProfileAction('liked', 'John Doe'),
          ),
          ListTile(
            title: const Text('Interest Action Success'),
            onTap: () => AppToastUtils.showInterestAction('sent', 'Jane Smith'),
          ),
          ListTile(
            title: const Text('Feature Unavailable'),
            onTap: () =>
                AppToastUtils.showFeatureUnavailable('unlimited likes'),
          ),
          ListTile(
            title: const Text('Coming Soon'),
            onTap: () => AppToastUtils.showComingSoon('voice messages'),
          ),
          ListTile(
            title: const Text('Welcome Back'),
            onTap: () => AppToastUtils.showWelcomeBack(),
          ),
          ListTile(
            title: const Text('Session Expired'),
            onTap: () => AppToastUtils.showSessionExpired(),
          ),
        ],
      ),
    );
  }
}

// Example 5: Using ToastErrorHandler for async operations
class ToastExample5 extends ConsumerWidget {
  const ToastExample5({super.key});

  Future<void> _performAsyncOperation() async {
    await ToastErrorHandler.handleVoid(
      () async {
        // Simulate an API call that might fail
        await Future.delayed(const Duration(seconds: 2));
        if (DateTime.now().second % 2 == 0) {
          throw Exception('Random failure for demo');
        }
        debugPrint('Operation successful');
      },
      operationName: 'load user data',
      onRetry: _performAsyncOperation,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ToastErrorHandler Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: _performAsyncOperation,
          child: const Text('Try Async Operation'),
        ),
      ),
    );
  }
}

// Example 6: Error handling with different categories
class ToastExample6 extends ConsumerWidget {
  const ToastExample6({super.key});

  void _simulateNetworkError() {
    final toast = ToastService.instance;
    toast.networkError(
      operation: 'upload image',
      onRetry: () => debugPrint('Retry upload'),
    );
  }

  void _simulateAuthError() {
    final toast = ToastService.instance;
    toast.authError(
      operation: 'access premium features',
      onRetry: () => debugPrint('Retry auth'),
    );
  }

  void _simulatePermissionError() {
    final toast = ToastService.instance;
    toast.permissionError(
      operation: 'delete profile',
      onRetry: () => debugPrint('Retry permission check'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Categories Example')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Network Error'),
            onTap: _simulateNetworkError,
          ),
          ListTile(title: const Text('Auth Error'), onTap: _simulateAuthError),
          ListTile(
            title: const Text('Permission Error'),
            onTap: _simulatePermissionError,
          ),
        ],
      ),
    );
  }
}

// Example 7: Common toast patterns from the React app
class ToastExample7 extends ConsumerWidget {
  const ToastExample7({super.key});

  void _showReactAppPatterns() {
    // Push notification patterns
    showNotificationSentToast(false);
    showNotificationPreviewToast();
    showTemplateSavedToast();

    // Email patterns
    showEmailSentToast(false);
    showEmailPreviewToast();
    showCampaignStartedToast();

    // Profile patterns
    showProfileDeletedToast();
    showInterestSentToast();

    // File operations
    showCopiedToClipboardToast();
    showFileExportedToast('CSV');

    // Validation errors
    showRequiredFieldToast('Email');
    showInvalidEmailToast();
    showEmailExistsToast();
    showSessionExpiredToast();
    showTooManyAttemptsToast();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('React App Patterns')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showReactAppPatterns,
          child: const Text('Show All Patterns'),
        ),
      ),
    );
  }
}
