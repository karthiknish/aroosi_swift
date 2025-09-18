import 'package:dio/dio.dart';

import 'package:aroosi_flutter/core/api_client.dart';

/// Repository to submit support/contact requests.
/// Tolerant to multiple backend endpoint paths and payload shapes
/// to mirror aroosi-mobile behavior.
class SupportRepository {
  SupportRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  /// Submit a contact/support request.
  /// Returns true if the server accepted the request (2xx).
  Future<bool> submitContact({
    required String message,
    String? email,
    String? subject,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    // Build multiple payload variants to maximize compatibility across backends.
    final payloads = <Map<String, dynamic>>[
      {
        if (email != null && email.isNotEmpty) 'email': email,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (category != null && category.isNotEmpty) 'category': category,
        'message': message,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      },
      {
        if (email != null && email.isNotEmpty) 'from': email,
        if (subject != null && subject.isNotEmpty) 'title': subject,
        if (category != null && category.isNotEmpty) 'type': category,
        'body': message,
        if (metadata != null && metadata.isNotEmpty) 'meta': metadata,
      },
      {
        if (email != null && email.isNotEmpty) 'userEmail': email,
        if (subject != null && subject.isNotEmpty) 'topic': subject,
        if (category != null && category.isNotEmpty) 'topicCategory': category,
        'description': message,
        if (metadata != null && metadata.isNotEmpty) 'extra': metadata,
      },
    ];

    final endpoints = <String>[
      '/support/contact',
      '/support',
      '/help/contact',
      '/contact',
    ];

    for (final data in payloads) {
      for (final path in endpoints) {
        try {
          final res = await _dio.post(path, data: data);
          final code = res.statusCode ?? 200;
          if (code >= 200 && code < 300) {
            return true;
          }
        } on DioException catch (_) {
          // Try next
        } catch (_) {
          // Try next
        }
      }
    }
    return false;
  }
}
