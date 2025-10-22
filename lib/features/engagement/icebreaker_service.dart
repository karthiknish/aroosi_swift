import 'package:flutter/foundation.dart';
import 'package:aroosi_flutter/core/api_client.dart';

class IcebreakerQuestion {
  final String id;
  final String text;
  final bool answered;
  final String? answer;

  const IcebreakerQuestion({
    required this.id,
    required this.text,
    this.answered = false,
    this.answer,
  });

  factory IcebreakerQuestion.fromJson(Map<String, dynamic> json) {
    return IcebreakerQuestion(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      answered: json['answered'] == true,
      answer: json['answer']?.toString(),
    );
  }
}

class IcebreakerService {
  Future<List<IcebreakerQuestion>> getDailyIcebreakers() async {
    try {
      final response = await ApiClient.dio.get('/icebreakers');

      if (response.statusCode == 200) {
        final data = response.data;
        // NextJS returns { success: true, data: [...] } or just the array
        List<dynamic> questions;
        if (data['success'] == true && data['data'] != null) {
          questions = data['data'] as List<dynamic>;
        } else if (data is List) {
          questions = data;
        } else {
          return [];
        }
        
        return questions.map((q) {
          final id = q['id']?.toString() ?? q['questionId']?.toString() ?? '';
          final text = q['text']?.toString() ?? q['question']?.toString() ?? '';
          final answered = q['answered'] == true;
          final answer = q['answer']?.toString();
          
          return IcebreakerQuestion(
            id: id,
            text: text,
            answered: answered,
            answer: answer,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      // Error handling - log to debug in production
      debugPrint('Error fetching icebreakers: $e');
      return [];
    }
  }

  Future<bool> answerIcebreaker(String questionId, String answer) async {
    try {
      final response = await ApiClient.dio.post(
        '/icebreakers/answer',
        data: {
          'questionId': questionId,
          'answer': answer,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // Error handling
      return false;
    }
  }
}
