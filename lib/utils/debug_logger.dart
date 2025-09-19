import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Global verbose logging toggle.
/// Can be overridden at build time using:
///   flutter run --dart-define=AROOSI_VERBOSE_LOGS=true
///   flutter build apk --dart-define=AROOSI_VERBOSE_LOGS=false
const bool kVerboseLogs = bool.fromEnvironment(
  'AROOSI_VERBOSE_LOGS',
  defaultValue:
      true, // Enable by default so new instrumentation is visible immediately.
);

void _baseLog(String domain, String message) {
  if (!kVerboseLogs) return;
  final ts = DateTime.now().toIso8601String();
  debugPrint('[AROOSI][$ts][$domain] $message');
}

void logAuth(String message) => _baseLog('AUTH', message);
void logRouter(String message) => _baseLog('ROUTER', message);
void logNav(String message) => _baseLog('NAV', message);
void logState(String message) => _baseLog('STATE', message);
void logApi(String message) => _baseLog('API', message);

/// File-based logging for GlobalKey errors
Future<void> logGlobalKeyError(String errorType, String message, {
  Object? error,
  StackTrace? stackTrace,
  String? widgetType,
  String? keyHash,
}) async {
  if (!kVerboseLogs) return;
  
  final timestamp = DateTime.now().toIso8601String();
  var fullMessage = '[$timestamp] GlobalKey Error: $errorType\n';
  fullMessage += 'Message: $message\n';
  
  if (widgetType != null) {
    fullMessage += 'Widget Type: $widgetType\n';
  }
  if (keyHash != null) {
    fullMessage += 'Key Hash: $keyHash\n';
  }
  if (error != null) {
    fullMessage += 'Error: $error\n';
  }
  if (stackTrace != null) {
    fullMessage += 'Stack Trace:\n$stackTrace\n';
  }
  fullMessage += '=' * 80 + '\n';
  
  // Log to console as well
  _baseLog('GLOBALKEY', fullMessage);
  
  // Write to file
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logFile = File(path.join(directory.path, 'aroosi_globalkey_errors.log'));
    await logFile.writeAsString(fullMessage, mode: FileMode.append);
  } catch (e) {
    // If file logging fails, at least we have console logs
    debugPrint('[AROOSI][GLOBALKEY] Failed to write to log file: $e');
  }
}

/// Generic debug logging function
void logDebug(String message, {Object? data, Object? error, StackTrace? stackTrace}) {
  if (!kVerboseLogs) return;
  
  var fullMessage = message;
  if (data != null) {
    fullMessage += ' | Data: $data';
  }
  if (error != null) {
    fullMessage += ' | Error: $error';
  }
  if (stackTrace != null) {
    fullMessage += ' | Stack: $stackTrace';
  }
  
  _baseLog('DEBUG', fullMessage);
}
