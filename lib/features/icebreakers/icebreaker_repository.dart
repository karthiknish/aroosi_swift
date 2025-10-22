import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/core/firebase_service.dart';
import 'package:aroosi_flutter/utils/debug_logger.dart';

import 'icebreaker_models.dart';

final icebreakerRepositoryProvider = Provider<IcebreakerRepository>(
  (ref) => IcebreakerRepository(),
);

class IcebreakerRepository {
  IcebreakerRepository({Dio? dio, FirebaseFirestore? firestore})
    : _dio = dio ?? ApiClient.dio,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final Dio _dio;
  final FirebaseFirestore _firestore;

  /// Fetch today's icebreaker questions
  /// Returns a list of icebreaker questions with answered status
  Future<List<Icebreaker>> fetchDailyIcebreakers() async {
    try {
      // Get current user ID
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Fetch all active icebreaker questions from Firestore
      final questionsSnapshot = await _firestore
          .collection('icebreaker_questions')
          .where('active', isEqualTo: true)
          .get();

      // Fetch user's existing answers
      final answersSnapshot = await _firestore
          .collection('icebreaker_answers')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Create a map of questionId -> answer for quick lookup
      final userAnswers = <String, IcebreakerAnswer>{};
      for (final doc in answersSnapshot.docs) {
        final answer = IcebreakerAnswer.fromJson(doc.data());
        userAnswers[answer.questionId] = answer;
      }

      // Convert questions to Icebreaker objects with answered status
      final icebreakers = <Icebreaker>[];
      for (final doc in questionsSnapshot.docs) {
        final questionData = doc.data();
        final question = IcebreakerQuestion.fromJson(questionData);
        final existingAnswer = userAnswers[question.id];

        icebreakers.add(
          Icebreaker(
            id: question.id,
            text: question.text,
            answered: existingAnswer != null,
            answer: existingAnswer?.answer,
          ),
        );
      }

      logDebug(
        'Fetched icebreakers from Firebase',
        data: {
          'questionCount': icebreakers.length,
          'answeredCount': icebreakers.where((i) => i.answered).length,
        },
      );

      return icebreakers;
    } catch (e) {
      logDebug('Failed to fetch icebreakers from Firebase', error: e);
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
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) {
        return IcebreakerSubmissionResult(
          success: false,
          error: 'User not authenticated',
        );
      }

      // Check if user already answered this question
      final existingAnswerQuery = await _firestore
          .collection('icebreaker_answers')
          .where('userId', isEqualTo: currentUser.uid)
          .where('questionId', isEqualTo: questionId)
          .get();

      if (existingAnswerQuery.docs.isNotEmpty) {
        // Update existing answer
        final docId = existingAnswerQuery.docs.first.id;
        await _firestore.collection('icebreaker_answers').doc(docId).update({
          'answer': answer.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new answer
        await _firestore.collection('icebreaker_answers').add({
          'userId': currentUser.uid,
          'questionId': questionId,
          'answer': answer.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      logDebug(
        'Icebreaker answer submitted to Firebase',
        data: {
          'questionId': questionId,
          'answerLength': answer.length,
          'userId': currentUser.uid,
        },
      );

      return IcebreakerSubmissionResult(success: true);
    } catch (e) {
      logDebug('Failed to submit icebreaker answer to Firebase', error: e);

      return IcebreakerSubmissionResult(success: false, error: e.toString());
    }
  }

  /// Get user's icebreaker answers (for profile display)
  Future<List<IcebreakerAnswer>> getUserAnswers({String? userId}) async {
    try {
      final targetUserId = userId ?? FirebaseService().currentUser?.uid;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      final answersSnapshot = await _firestore
          .collection('icebreaker_answers')
          .where('userId', isEqualTo: targetUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final answers = answersSnapshot.docs
          .map(
            (doc) => IcebreakerAnswer.fromJson({...doc.data(), 'id': doc.id}),
          )
          .where((a) => a.id.isNotEmpty)
          .toList();

      logDebug(
        'Fetched user icebreaker answers from Firebase',
        data: {'userId': targetUserId, 'answerCount': answers.length},
      );

      return answers;
    } catch (e) {
      logDebug(
        'Failed to fetch user icebreaker answers from Firebase',
        error: e,
      );
      rethrow;
    }
  }

  /// Get all available icebreaker questions (for admin)
  Future<List<IcebreakerQuestion>> getAllQuestions() async {
    try {
      final questionsSnapshot = await _firestore
          .collection('icebreaker_questions')
          .orderBy('createdAt', descending: true)
          .get();

      final questions = questionsSnapshot.docs
          .map(
            (doc) => IcebreakerQuestion.fromJson({...doc.data(), 'id': doc.id}),
          )
          .where((q) => q.id.isNotEmpty)
          .toList();

      logDebug(
        'Fetched all icebreaker questions from Firebase',
        data: {'questionCount': questions.length},
      );

      return questions;
    } catch (e) {
      logDebug(
        'Failed to fetch all icebreaker questions from Firebase',
        error: e,
      );
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
      await _firestore.collection('icebreaker_questions').add({
        'text': text.trim(),
        'category': category,
        'weight': weight,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logDebug('Created icebreaker question in Firebase', data: {'text': text});
      return true;
    } catch (e) {
      logDebug('Failed to create icebreaker question in Firebase', error: e);
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
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('icebreaker_questions')
          .doc(questionId)
          .update(data);

      logDebug(
        'Updated icebreaker question in Firebase',
        data: {'questionId': questionId},
      );
      return true;
    } catch (e) {
      logDebug('Failed to update icebreaker question in Firebase', error: e);
      return false;
    }
  }

  /// Delete an icebreaker question (admin)
  Future<bool> deleteQuestion(String questionId) async {
    try {
      await _firestore
          .collection('icebreaker_questions')
          .doc(questionId)
          .delete();

      logDebug(
        'Deleted icebreaker question from Firebase',
        data: {'questionId': questionId},
      );
      return true;
    } catch (e) {
      logDebug('Failed to delete icebreaker question from Firebase', error: e);
      return false;
    }
  }

  /// Get icebreaker statistics for a user
  Future<Map<String, dynamic>> getUserStats({String? userId}) async {
    try {
      final targetUserId = userId ?? FirebaseService().currentUser?.uid;
      if (targetUserId == null) {
        return {'error': 'User not authenticated'};
      }

      final answersSnapshot = await _firestore
          .collection('icebreaker_answers')
          .where('userId', isEqualTo: targetUserId)
          .get();

      final stats = {
        'totalAnswers': answersSnapshot.docs.length,
        'userId': targetUserId,
      };

      logDebug('Fetched icebreaker stats from Firebase', data: stats);
      return stats;
    } catch (e) {
      logDebug('Failed to fetch icebreaker stats from Firebase', error: e);
      return {'error': e.toString()};
    }
  }
}
