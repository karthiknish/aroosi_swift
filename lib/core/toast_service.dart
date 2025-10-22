import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/theme/theme.dart';

// Provider for toast service messenger key
final toastMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

enum ToastType { info, success, warning, error, primary }

// Enhanced error categorization for better error handling
enum ErrorCategory { network, server, auth, validation, permission, generic }

// Keep track of recent toast messages to prevent duplicates
final _recentToasts = <String, DateTime>{};

class ToastService {
  ToastService._(this._messengerKey);

  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  // Static fields for singleton pattern
  static ToastService? _instance;
  static GlobalKey<ScaffoldMessengerState>? _testMessengerKey;

  // Factory constructor for provider pattern
  factory ToastService(GlobalKey<ScaffoldMessengerState> messengerKey) {
    return ToastService._(messengerKey);
  }

  // Singleton instance getter
  static ToastService get instance {
    if (_instance == null) {
      if (_testMessengerKey != null) {
        _instance = ToastService._(_testMessengerKey!);
      } else {
        throw StateError(
          'ToastService not initialized. Call initialize() first.',
        );
      }
    }
    return _instance!;
  }

  // Initialize the singleton instance
  static void initialize(GlobalKey<ScaffoldMessengerState> messengerKey) {
    _instance = ToastService._(messengerKey);
  }

  // For testing: allows setting a custom key
  static void setTestMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _testMessengerKey = key;
    _instance = null; // Reset instance to use new key
  }

  // For testing: reset to default behavior
  static void resetTestMessengerKey() {
    _testMessengerKey = null;
    _instance = null;
  }

  // Enhanced duplicate prevention with better categorization
  bool _shouldSuppress(String key) {
    final now = DateTime.now();
    final lastTime = _recentToasts[key];

    if (lastTime != null &&
        now.difference(lastTime) < const Duration(seconds: 3)) {
      return true;
    }

    _recentToasts[key] = now;

    // Clean up old entries (older than 10 seconds) to prevent memory leaks
    _recentToasts.removeWhere(
      (_, time) => now.difference(time) > const Duration(seconds: 10),
    );

    return false;
  }

  void show(
    String message, {
    ToastType type = ToastType.info,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final scaffoldMessenger = _messengerKey.currentState;
    final context = _messengerKey.currentContext;
    if (scaffoldMessenger == null || context == null) return;

    // Sanitize the incoming message so users see friendly text, not
    // raw error codes or developer stack traces.
    final userMessage = _sanitizeMessage(message);
    if (userMessage.trim().isEmpty) return;

    // Dedupe based on type + user-friendly message and action label
    final key = '${type.name}:${userMessage.trim()}:${actionLabel ?? ''}';
    if (_shouldSuppress(key)) return;

    scaffoldMessenger.hideCurrentSnackBar();

    final palette = _resolvePalette(type, Theme.of(context).colorScheme);
    final theme = Theme.of(context);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration ?? _defaultDuration(type),
      backgroundColor: palette.background,
      content: Text(
        userMessage,
        style: theme.textTheme.bodyMedium?.copyWith(color: palette.foreground),
      ),
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: palette.foreground,
            )
          : null,
    );

    scaffoldMessenger.showSnackBar(snackBar);
  }

  // Enhanced error toast with fallback message and error categorization
  void errorToast(
    dynamic error, {
    String? fallback,
    bool showRetry = false,
    VoidCallback? onRetry,
    ErrorCategory category = ErrorCategory.generic,
  }) {
    final message = _humanizeError(
      error,
      fallback ?? 'Something went wrong. Please try again.',
    );
    final userMessage = _sanitizeMessage(message);

    if (userMessage.trim().isEmpty) return;

    // Dedupe based on error category + user-friendly message
    final key = '${ErrorCategory.generic.name}:$userMessage';
    if (_shouldSuppress(key)) return;

    _messengerKey.currentState?.hideCurrentSnackBar();

    final context = _messengerKey.currentContext;
    if (context == null) return;

    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    SnackBar snackBar;

    if (showRetry && onRetry != null) {
      snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 5000),
        backgroundColor: errorColor,
        content: Text(
          userMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onError,
          ),
        ),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: onRetry,
          textColor: theme.colorScheme.onError,
        ),
      );
    } else {
      snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 4000),
        backgroundColor: errorColor,
        content: Text(
          userMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onError,
          ),
        ),
      );
    }

    _messengerKey.currentState?.showSnackBar(snackBar);

    // Always log the raw error for diagnostics
    if (error != null) {
      debugPrint('[ToastError] $error');
    }
  }

  // Humanize error messages similar to React app patterns
  String _humanizeError(dynamic error, String fallback) {
    // Handle different error types
    String message;
    if (error is String && error.trim().isNotEmpty) {
      message = error.trim();
    } else if (error is Exception || error is Error) {
      message = error.toString();
    } else if (error != null && error is Map && error['error'] is String) {
      message = error['error'].toString();
    } else if (error != null && error is Map && error['message'] is String) {
      message = error['message'].toString();
    } else {
      message = fallback;
    }

    // Apply humanization patterns
    return _humanizeErrorMessage(message, fallback);
  }

  String _humanizeErrorMessage(String message, String fallback) {
    // Handle JSON error structures
    if (message.startsWith('{') && message.endsWith('}')) {
      try {
        final decoded = jsonDecode(message);
        if (decoded is Map && decoded['code'] == 'ONBOARDING_INCOMPLETE') {
          return 'Please finish onboarding to continue.';
        }
        if (decoded['message'] is String) return decoded['message'];
        if (decoded['error'] is String) return decoded['error'];
      } catch (_) {
        // Ignore JSON parse errors
      }
    }

    // Handle common error patterns
    final errorMappings = <RegExp, String>{
      // Network errors
      RegExp(
        r'network|connection|timeout|offline|no internet',
        caseSensitive: false,
      ): 'Network error. Check your connection.',
      RegExp(r'failed to fetch|http error|server error', caseSensitive: false):
          'Server error. Please try again.',

      // Auth errors
      RegExp(r'email.*already.*exists|account.*exists', caseSensitive: false):
          'An account with this email already exists.',
      RegExp(r'invalid.*email', caseSensitive: false): 'Invalid email address.',
      RegExp(r'password.*weak|invalid.*password', caseSensitive: false):
          'Password is too weak.',
      RegExp(r'wrong.*password|incorrect.*credentials', caseSensitive: false):
          'Incorrect email or password.',
      RegExp(r'user.*not.*found|account.*not.*found', caseSensitive: false):
          'Account not found.',
      RegExp(r'too.*many.*requests', caseSensitive: false):
          'Too many attempts. Please try again later.',
      RegExp(r'session.*expired|token.*expired', caseSensitive: false):
          'Session expired. Please sign in again.',
      RegExp(r'invalid.*credential', caseSensitive: false):
          'Invalid email or password.',

      // Permission errors
      RegExp(
        r'permission.*denied|insufficient.*permissions|forbidden',
        caseSensitive: false,
      ): 'You don\'t have permission to do that.',
      RegExp(r'unauthorized|access.*denied', caseSensitive: false):
          'Access denied.',

      // Validation errors
      RegExp(r'required|field.*required', caseSensitive: false):
          'Required field is missing.',
      RegExp(r'invalid.*format|invalid.*input', caseSensitive: false):
          'Invalid input format.',

      // Generic errors
      RegExp(r'internal.*error|unexpected.*error', caseSensitive: false):
          'Unexpected error. Please try again.',
      RegExp(r'something.*went.*wrong', caseSensitive: false):
          'Something went wrong. Please try again.',
    };

    for (final mapping in errorMappings.entries) {
      if (mapping.key.hasMatch(message)) {
        return mapping.value;
      }
    }

    // If message looks technical, use fallback
    if (message.contains('Exception') ||
        message.contains('StackTrace') ||
        message.contains('at ') ||
        message.length > 200) {
      return fallback;
    }

    return message;
  }

  // Attempt to convert developer-oriented or raw error text into a
  // concise, user-facing message. Heuristics include JSON parsing for
  // common API responses, trimming stack traces, and mapping common
  // error-code patterns to friendly phrases.
  String _sanitizeMessage(String message) {
    var m = message.trim();
    if (m.isEmpty) return m;

    // If this looks like JSON, try to extract a reasonable field.
    if (m.startsWith('{') || m.startsWith('[')) {
      try {
        final decoded = jsonDecode(m);
        if (decoded is Map) {
          if (decoded['message'] != null) return decoded['message'].toString();
          if (decoded['error'] != null) return decoded['error'].toString();
          if (decoded['detail'] != null) return decoded['detail'].toString();
        }
      } catch (_) {
        // fall through to other heuristics
      }
    }

    // Remove common stacktrace markers and long internal details
    if (m.contains('\n') ||
        m.contains('#0      ') ||
        m.contains('StackTrace')) {
      // If there's a short human-looking line at the start, keep that.
      final firstLine = m.split('\n').first;
      if (firstLine.length < 180 && !_looksLikeCode(firstLine)) {
        return _capitalizeFirst(firstLine);
      }
      return 'Something went wrong. Please try again.';
    }

    // Extract after typical prefixes like "Exception:", "Error:", etc.
    final exceptionMatch = RegExp(
      r'(?:exception|error|failed)[:\-\s]+(.+)',
      caseSensitive: false,
    ).firstMatch(m);
    if (exceptionMatch != null && exceptionMatch.groupCount >= 1) {
      final candidate = exceptionMatch.group(1)!.trim();
      if (candidate.isNotEmpty && candidate.length < 200) {
        return _capitalizeFirst(candidate);
      }
    }

    // Strip bracketed error codes like [ERR_SOMETHING] and common "code:" patterns
    m = m.replaceAll(RegExp(r'\[?ERR[_-]?[A-Z0-9]+\]?'), '');
    m = m.replaceAll(RegExp(r'code[:=]\s*[A-Za-z0-9_-]+'), '');
    m = m.replaceAll(RegExp(r'\s+\(.*\)\$'), '');

    // If message is still developersy or very long, fallback to generic text
    if (m.length > 180 ||
        m.contains(
          RegExp(r'\b(stacktrace|traceback|at\s)\b', caseSensitive: false),
        )) {
      return 'Something went wrong. Please try again.';
    }

    return _capitalizeFirst(m.trim());
  }

  bool _looksLikeCode(String s) {
    return RegExp(r'[{}<>;=/*]|\bException\b|\bStackTrace\b').hasMatch(s);
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void info(
    String message, {
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(message, type: ToastType.info, duration: duration);
  }

  void success(
    String message, {
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    show(message, type: ToastType.success, duration: duration);
  }

  void warning(
    String message, {
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(message, type: ToastType.warning, duration: duration);
  }

  void error(
    String message, {
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    show(message, type: ToastType.error, duration: duration);
  }

  void undo(
    String message,
    VoidCallback onUndo, {
    String actionLabel = 'Undo',
    Duration duration = const Duration(milliseconds: 6000),
  }) {
    show(
      message,
      type: ToastType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onUndo,
    );
  }

  // Primary branded toast for special announcements (matches React app)
  void primary(
    String message, {
    Duration duration = const Duration(milliseconds: 6000),
  }) {
    show(message, type: ToastType.primary, duration: duration);
  }

  // Success toast with undo functionality (matches React app showUndoToast)
  void successWithUndo(
    String message,
    VoidCallback onUndo, {
    String actionLabel = 'Undo',
    Duration duration = const Duration(milliseconds: 6000),
  }) {
    show(
      message,
      type: ToastType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onUndo,
    );
  }

  // Copy success message (matches React app pattern)
  void copiedToClipboard() {
    success('Copied to clipboard');
  }

  // Generic success message with common patterns
  void operationSuccess(String operation) {
    success('$operation successful');
  }

  // Generic error message with common patterns
  void operationFailed(String operation, {String? details}) {
    final message = details != null
        ? 'Failed to $operation: $details'
        : 'Failed to $operation';
    error(message);
  }

  // Network error handling
  void networkError({String? operation, VoidCallback? onRetry}) {
    final message = operation != null
        ? 'Failed to $operation - check your connection'
        : 'Network error - check your connection';
    errorToast(
      message,
      fallback: 'Network error. Check your connection.',
      showRetry: onRetry != null,
      onRetry: onRetry,
      category: ErrorCategory.network,
    );
  }

  // Server error handling
  void serverError({String? operation, VoidCallback? onRetry}) {
    final message = operation != null
        ? 'Server error during $operation'
        : 'Server error occurred';
    errorToast(
      message,
      fallback: 'Server error. Please try again.',
      showRetry: onRetry != null,
      onRetry: onRetry,
      category: ErrorCategory.server,
    );
  }

  // Authentication error handling
  void authError({String? operation, VoidCallback? onRetry}) {
    final message = operation != null
        ? 'Authentication failed for $operation'
        : 'Authentication failed';
    errorToast(
      message,
      fallback: 'Please sign in again.',
      showRetry: onRetry != null,
      onRetry: onRetry,
      category: ErrorCategory.auth,
    );
  }

  // Permission error handling
  void permissionError({String? operation, VoidCallback? onRetry}) {
    final message = operation != null
        ? 'Permission denied for $operation'
        : 'Permission denied';
    errorToast(
      message,
      fallback: 'You don\'t have permission to do that.',
      showRetry: onRetry != null,
      onRetry: onRetry,
      category: ErrorCategory.permission,
    );
  }

  // Validation error handling
  void validationError(String message, {VoidCallback? onRetry}) {
    errorToast(
      message,
      fallback: 'Please check your input and try again.',
      showRetry: onRetry != null,
      onRetry: onRetry,
      category: ErrorCategory.validation,
    );
  }

  // Generic error with retry
  void retryableError(
    String message, {
    required VoidCallback onRetry,
    String? retryLabel,
  }) {
    errorToast(
      message,
      showRetry: true,
      onRetry: onRetry,
      category: ErrorCategory.generic,
    );
  }

  void hide() {
    _messengerKey.currentState?.hideCurrentSnackBar();
  }

  _ToastPalette _resolvePalette(ToastType type, ColorScheme scheme) {
    switch (type) {
      case ToastType.success:
        return const _ToastPalette(AppColors.success, AppColors.onDark);
      case ToastType.warning:
        return const _ToastPalette(AppColors.warning, AppColors.onDark);
      case ToastType.error:
        return _ToastPalette(scheme.error, scheme.onError);
      case ToastType.info:
        return const _ToastPalette(AppColors.info, AppColors.onDark);
      case ToastType.primary:
        return const _ToastPalette(AppColors.primary, AppColors.onPrimary);
    }
  }

  Duration _defaultDuration(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Duration(milliseconds: 4000); // Match React app
      case ToastType.info:
        return const Duration(milliseconds: 4000); // Match React app
      case ToastType.warning:
        return const Duration(milliseconds: 5000); // Match React app
      case ToastType.error:
        return const Duration(milliseconds: 5000); // Match React app
      case ToastType.primary:
        return const Duration(milliseconds: 6000); // Match React app
    }
  }
}

class _ToastPalette {
  const _ToastPalette(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

// Provider for toast service that uses the messenger key provider
final toastServiceProvider = Provider<ToastService>(
  (ref) => ToastService(ref.read(toastMessengerKeyProvider)),
);
