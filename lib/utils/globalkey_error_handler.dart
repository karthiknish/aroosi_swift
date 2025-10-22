import 'package:flutter/foundation.dart';
import 'debug_logger.dart';

/// Global error handler specifically for GlobalKey conflicts
class GlobalKeyErrorHandler {
  static final GlobalKeyErrorHandler _instance =
      GlobalKeyErrorHandler._internal();

  factory GlobalKeyErrorHandler() {
    return _instance;
  }

  GlobalKeyErrorHandler._internal();

  /// Initialize the error handler to catch Flutter errors
  void init() {
    // Override Flutter's error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if this is a GlobalKey error
      if (details.exception.toString().contains(
            'Multiple widgets used the same GlobalKey',
          ) ||
          details.exception.toString().contains('GlobalKey') ||
          details.exception.toString().contains('used the same GlobalKey')) {
        // Extract widget information from the stack trace
        String? widgetType;
        String? keyHash;

        if (details.stack != null) {
          final stackString = details.stack.toString();

          // Try to extract widget type from stack trace
          final widgetMatch = RegExp(r'(\w+)\.build').firstMatch(stackString);
          if (widgetMatch != null && widgetMatch.groupCount >= 1) {
            widgetType = widgetMatch.group(1);
          }

          // Try to extract key hash information
          final keyMatch = RegExp(
            r'GlobalKey<([#\w]+)>',
          ).firstMatch(stackString);
          if (keyMatch != null && keyMatch.groupCount >= 1) {
            keyHash = keyMatch.group(1);
          }
        }

        // Log the error to file
        logGlobalKeyError(
          'GlobalKey Conflict',
          details.exception.toString(),
          error: details.exception,
          stackTrace: details.stack,
          widgetType: widgetType,
          keyHash: keyHash,
        );
      }

      // Also log to console with the default handler
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Handle Dart errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (error.toString().contains('GlobalKey') ||
          error.toString().contains(
            'Multiple widgets used the same GlobalKey',
          )) {
        logGlobalKeyError(
          'Dart GlobalKey Error',
          error.toString(),
          error: error,
          stackTrace: stack,
        );
      }
      return true; // Prevent default error handling
    };
  }

  /// Manually log a GlobalKey error (for direct usage)
  static void logError(
    String errorType,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? widgetType,
    String? keyHash,
  }) async {
    await logGlobalKeyError(
      errorType,
      message,
      error: error,
      stackTrace: stackTrace,
      widgetType: widgetType,
      keyHash: keyHash,
    );
  }
}
