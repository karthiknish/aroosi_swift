import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

import 'icebreaker_models.dart';

final icebreakerRepositoryProvider = Provider<IcebreakerRepository>(
  (ref) => IcebreakerRepository(),
);

class IcebreakerRepository {
  IcebreakerRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// Fetch today's icebreaker questions
  /// Returns a list of icebreaker questions with answered status
  Future<List<Icebreaker>> fetchDailyIcebreakers() async {
    try {
      final res = await _dio.get('/api/icebreakers');
      
      logDebug('Icebreaker API response', data: {
        'status': res.statusCode,
        'data': res.data,
      });

      final data = res.data;
      List<dynamic> items;
      
      if (data is Map<String, dynamic>) {
        // Handle wrapped response: { data: [...] }
        if (data['data'] is List) {
          items = data['data'] as List;
        } else if (data['success'] == true && data['icebreakers'] is List) {
          items = data['icebreakers'] as List;
        } else {
          items = [];
        }
      } else if (data is List) {
        // Handle direct array response
        items = data;
      } else {
        items = [];
      }

      return items
          .whereType<Map>()
          .map((e) => Icebreaker.fromJson(e.cast<String, dynamic>()))
          .where((q) => q.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      logDebug('Failed to fetch icebreakers', error: e);
      rethrow;
    }
  }

  /// Submit an answer to an icebreaker question
  /// Returns the submission result
  Future<IcebreakerSubmissionResult> submitAnswer({
    required String questionId,
    required String answer,
  }) async {
    try {
      final res = await _dio.post(
        '/api/icebreakers/answer',
        data: {
          'questionId': questionId,
          'answer': answer.trim(),
        },
      );

      logDebug('Icebreaker answer submission', data: {
        'questionId': questionId,
        'answerLength': answer.length,
        'status': res.statusCode,
        'response': res.data,
      });

      final data = res.data;
      Map<String, dynamic> resultData;
      
      if (data is Map<String, dynamic>) {
        resultData = data;
      } else {
        resultData = {'success': false};
      }

      return IcebreakerSubmissionResult.fromJson(resultData);
    } on DioException catch (e) {
      logDebug('Failed to submit icebreaker answer', error: e);
      
      // Extract error message from response if available
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response?.data as Map<String, dynamic>;
        errorMessage = errorData['error']?.toString() ?? 
                       errorData['message']?.toString();
      }
      
      return IcebreakerSubmissionResult(
        success: false,
        error: errorMessage ?? e.message ?? 'Failed to submit answer',
      );
    }
  }

  /// Get user's icebreaker answers (for profile display)
  Future<List<IcebreakerAnswer>> getUserAnswers({String? userId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }

      final res = await _dio.get(
        '/api/icebreakers/answers',
        queryParameters: queryParams,
      );

      final data = res.data;
      List<dynamic> items;
      
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          items = data['data'] as List;
        } else if (data['answers'] is List) {
          items = data['answers'] as List;
        } else {
          items = [];
        }
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }

      return items
          .whereType<Map>()
          .map((e) => IcebreakerAnswer.fromJson(e.cast<String, dynamic>()))
          .where((a) => a.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      logDebug('Failed to fetch user icebreaker answers', error: e);
      rethrow;
    }
  }

  /// Get all available icebreaker questions (for admin)
  Future<List<IcebreakerQuestion>> getAllQuestions() async {
    try {
      final res = await _dio.get('/api/icebreakers/questions');

      final data = res.data;
      List<dynamic> items;
      
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          items = data['data'] as List;
        } else if (data['questions'] is List) {
          items = data['questions'] as List;
        } else {
          items = [];
        }
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }

      return items
          .whereType<Map>()
          .map((e) => IcebreakerQuestion.fromJson(e.cast<String, dynamic>()))
          .where((q) => q.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      logDebug('Failed to fetch all icebreaker questions', error: e);
      rethrow;
    }
  }

  /// Create a new icebreaker question (admin)
  Future<bool> createQuestion({
    required String text,
    String? category,
    int weight = 1,
  }) async {
    try {
      final res = await _dio.post(
        '/api/icebreakers/questions',
        data: {
          'text': text.trim(),
          'category': category,
          'weight': weight,
          'active': true,
        },
      );

      final status = res.statusCode ?? 200;
      return status >= 200 && status < 300;
    } on DioException catch (e) {
      logDebug('Failed to create icebreaker question', error: e);
      return false;
    }
  }

  /// Update an icebreaker question (admin)
  Future<bool> updateQuestion({
    required String questionId,
    String? text,
    String? category,
    int? weight,
    bool? active,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (text != null) data['text'] = text.trim();
      if (category != null) data['category'] = category;
      if (weight != null) data['weight'] = weight;
      if (active != null) data['active'] = active;

      final res = await _dio.put(
        '/api/icebreakers/questions/$questionId',
        data: data,
      );

      final status = res.statusCode ?? 200;
      return status >= 200 && status < 300;
    } on DioException catch (e) {
      logDebug('Failed to update icebreaker question', error: e);
      return false;
    }
  }

  /// Delete an icebreaker question (admin)
  Future<bool> deleteQuestion(String questionId) async {
    try {
      final res = await _dio.delete('/api/icebreakers/questions/$questionId');
      
      final status = res.statusCode ?? 200;
      return status >= 200 && status < 300;
    } on DioException catch (e) {
      logDebug('Failed to delete icebreaker question', error: e);
      return false;
    }
  }

  /// Get icebreaker statistics for a user
  Future<Map<String, dynamic>> getUserStats({String? userId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }

      final res = await _dio.get(
        '/api/icebreakers/stats',
        queryParameters: queryParams,
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    } on DioException catch (e) {
      logDebug('Failed to fetch icebreaker stats', error: e);
      return {};
    }
  }
}