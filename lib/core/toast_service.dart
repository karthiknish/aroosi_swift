import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/theme/theme.dart';

// Provider for toast service messenger key
final toastMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

enum ToastType { info, success, warning, error }

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
      throw StateError('ToastService not initialized. Call initialize() first.');
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

  // Simple in-memory dedupe within a short window to avoid toast spam
  String? _lastKey;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const _dedupeWindow = Duration(milliseconds: 1500);

  bool _shouldSuppress(String key) {
    final now = DateTime.now();
    if (_lastKey == key && now.difference(_lastAt) < _dedupeWindow) {
      return true;
    }
    _lastKey = key;
    _lastAt = now;
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
      if (candidate.isNotEmpty && candidate.length < 200)
        return _capitalizeFirst(candidate);
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
    }
  }

  Duration _defaultDuration(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Duration(milliseconds: 2600);
      case ToastType.info:
        return const Duration(milliseconds: 2800);
      case ToastType.warning:
        return const Duration(milliseconds: 3400);
      case ToastType.error:
        return const Duration(milliseconds: 3600);
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
