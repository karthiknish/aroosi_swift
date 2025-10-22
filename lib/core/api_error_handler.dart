import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Enhanced API error handler for better debugging and user feedback
class ApiErrorHandler {
  static String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';

      case DioExceptionType.unknown:
        return 'An unexpected error occurred. Please try again.';

      default:
        return 'Request failed. Please try again.';
    }
  }

  static String _handleBadResponse(DioException error) {
    final response = error.response;
    if (response == null) return 'Server error occurred.';

    switch (response.statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Our team has been notified.';
      case 502:
        return 'Server is temporarily unavailable. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'HTTP ${response.statusCode}: Request failed.';
    }
  }

  static void logError(DioException error, String operation) {
    if (kDebugMode) {
      debugPrint('=== API Error ===');
      debugPrint('Operation: $operation');
      debugPrint('Type: ${error.type}');
      debugPrint('Message: ${error.message}');

      if (error.response != null) {
        debugPrint('Status Code: ${error.response!.statusCode}');
        debugPrint('Status Message: ${error.response!.statusMessage}');
        debugPrint('Headers: ${error.response!.headers}');

        try {
          debugPrint('Response Data: ${error.response!.data}');
        } catch (e) {
          debugPrint('Failed to parse response data: $e');
        }
      }

      debugPrint('Request: ${error.requestOptions}');
      debugPrint('==================');
    }
  }
}