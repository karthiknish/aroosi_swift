import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'icebreaker_models.dart';
import 'icebreaker_repository.dart';

// Simple state for icebreakers
class IcebreakerState {
  const IcebreakerState({
    this.icebreakers = const [],
    this.isLoading = false,
    this.error,
    this.savingIds = const {},
  });

  final List<Icebreaker> icebreakers;
  final bool isLoading;
  final String? error;
  final Set<String> savingIds; // question IDs currently being saved

  IcebreakerState copyWith({
    List<Icebreaker>? icebreakers,
    bool? isLoading,
    String? error,
    Set<String>? savingIds,
  }) {
    return IcebreakerState(
      icebreakers: icebreakers ?? this.icebreakers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      savingIds: savingIds ?? this.savingIds,
    );
  }
}

// Simple controller for icebreakers
class IcebreakerController extends Notifier<IcebreakerState> {

  late final IcebreakerRepository _repository;

  @override
  IcebreakerState build() {
    _repository = ref.read(icebreakerRepositoryProvider);
    // Don't auto-fetch here to avoid putting provider in error state during initialization
    return const IcebreakerState();
  }

  // Fetch daily icebreakers
  Future<void> fetchDailyIcebreakers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final icebreakers = await _repository.fetchDailyIcebreakers();
      state = state.copyWith(isLoading: false, icebreakers: icebreakers);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load icebreakers',
      );
    }
  }

  // Refresh icebreakers
  Future<void> refreshIcebreakers() async {
    await fetchDailyIcebreakers();
  }

  // Submit an answer
  Future<bool> submitAnswer(String questionId, String answer) async {
    final trimmedAnswer = answer.trim();

    if (trimmedAnswer.isEmpty) {
      return false;
    }

    if (trimmedAnswer.length < 10) {
      return false;
    }

    // Set saving state
    state = state.copyWith(savingIds: {...state.savingIds, questionId});

    try {
      final result = await _repository.submitAnswer(
        questionId: questionId,
        answer: trimmedAnswer,
      );

      if (result.success) {
        // Refresh icebreakers to get updated state
        await fetchDailyIcebreakers();
        return true;
      } else {
        return false;
      }
    } on DioException {
      return false;
    } catch (e) {
      return false;
    } finally {
      // Clear saving state
      state = state.copyWith(
        savingIds: state.savingIds.where((id) => id != questionId).toSet(),
      );
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final errorData = e.response?.data as Map<String, dynamic>;
      return errorData['error']?.toString() ??
          errorData['message']?.toString() ??
          'Network error';
    }
    return e.message ?? 'Network error';
  }
}

// Provider for the controller
final icebreakerControllerProvider =
    NotifierProvider<IcebreakerController, IcebreakerState>(
      IcebreakerController.new,
    );
