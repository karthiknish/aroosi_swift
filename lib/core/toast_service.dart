import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/theme/theme.dart';

final GlobalKey<ScaffoldMessengerState> toastMessengerKey = GlobalKey<ScaffoldMessengerState>();

enum ToastType { info, success, warning, error }

class ToastService {
  ToastService._(this._messengerKey);

  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  static final ToastService _instance = ToastService._(toastMessengerKey);

  static ToastService get instance => _instance;

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
    if (message.trim().isEmpty) return;

    // Dedupe based on type + message and action label
    final key = '${type.name}:${message.trim()}:${actionLabel ?? ''}';
    if (_shouldSuppress(key)) return;

    scaffoldMessenger.hideCurrentSnackBar();

    final palette = _resolvePalette(type, Theme.of(context).colorScheme);
    final theme = Theme.of(context);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration ?? _defaultDuration(type),
      backgroundColor: palette.background,
      content: Text(
        message,
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

  void info(String message, {Duration duration = const Duration(milliseconds: 2800)}) {
    show(message, type: ToastType.info, duration: duration);
  }

  void success(String message, {Duration duration = const Duration(milliseconds: 2800)}) {
    show(message, type: ToastType.success, duration: duration);
  }

  void warning(String message, {Duration duration = const Duration(milliseconds: 3200)}) {
    show(message, type: ToastType.warning, duration: duration);
  }

  void error(String message, {Duration duration = const Duration(milliseconds: 3200)}) {
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

final toastServiceProvider = Provider<ToastService>((ref) => ToastService.instance);
