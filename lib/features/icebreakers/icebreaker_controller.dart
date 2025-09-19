import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'icebreaker_models.dart';
import 'icebreaker_repository.dart';

// State class for icebreaker functionality
class IcebreakerState {
  const IcebreakerState({
    this.questions = const [],
    this.isLoading = false,
    this.error,
    this.answers = const {},
    this.submittedAnswers = const {},
    this.editingAnswers = const {},
    this.hiddenQuestions = const {},
    this.currentIndex = 0,
    this.isSubmitting = false,
    this.autoSaveTimers = const {},
  });

  final List<Icebreaker> questions;
  final bool isLoading;
  final String? error;
  final Map<String, String> answers; // questionId -> answer text
  final Map<String, bool> submittedAnswers; // questionId -> is submitted
  final Map<String, bool> editingAnswers; // questionId -> is editing
  final Map<String, bool> hiddenQuestions; // questionId -> is hidden
  final int currentIndex;
  final bool isSubmitting;
  final Map<String, int> autoSaveTimers; // questionId -> timer id

  IcebreakerState copyWith({
    List<Icebreaker>? questions,
    bool? isLoading,
    String? error,
    Map<String, String>? answers,
    Map<String, bool>? submittedAnswers,
    Map<String, bool>? editingAnswers,
    Map<String, bool>? hiddenQuestions,
    int? currentIndex,
    bool? isSubmitting,
    Map<String, int>? autoSaveTimers,
  }) {
    return IcebreakerState(
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      answers: answers ?? this.answers,
      submittedAnswers: submittedAnswers ?? this.submittedAnswers,
      editingAnswers: editingAnswers ?? this.editingAnswers,
      hiddenQuestions: hiddenQuestions ?? this.hiddenQuestions,
      currentIndex: currentIndex ?? this.currentIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      autoSaveTimers: autoSaveTimers ?? this.autoSaveTimers,
    );
  }

  // Getters for computed properties
  List<Icebreaker> get visibleQuestions => 
      questions.where((q) => !hiddenQuestions[q.id]!).toList();
  
  Icebreaker? get currentQuestion => 
      visibleQuestions.isNotEmpty && currentIndex < visibleQuestions.length
          ? visibleQuestions[currentIndex]
          : null;
  
  int get answeredCount => visibleQuestions
      .where((q) => submittedAnswers[q.id]! || q.answered)
      .length;
  
  int get totalQuestions => visibleQuestions.length;
  
  double get progressPercentage => totalQuestions > 0 
      ? answeredCount / totalQuestions 
      : 0.0;
  
  bool get isCompleted => answeredCount == totalQuestions && totalQuestions > 0;
}

// State notifier
class IcebreakerController extends StateNotifier<IcebreakerState> {
  IcebreakerController(this.ref) : super(const IcebreakerState()) {
    _repository = ref.read(icebreakerRepositoryProvider);
  }

  final Ref ref;
  late final IcebreakerRepository _repository;

  // Fetch daily icebreakers
  Future<void> fetchDailyIcebreakers() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final questions = await _repository.fetchDailyIcebreakers();
      
      // Pre-fill answers with any server-provided saved answers
      final answers = <String, String>{};
      final submittedAnswers = <String, bool>{};
      
      for (final question in questions) {
        if (question.answer != null && question.answer!.isNotEmpty) {
          answers[question.id] = question.answer!;
        }
        if (question.answered) {
          submittedAnswers[question.id] = true;
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        questions: questions,
        answers: answers,
        submittedAnswers: submittedAnswers,
        currentIndex: 0,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load icebreakers',
      );
    }
  }

  // Submit an answer
  Future<bool> submitAnswer(String questionId, String answer) async {
    final trimmedAnswer = answer.trim();
    
    if (trimmedAnswer.isEmpty) {
      state = state.copyWith(error: 'Please enter an answer');
      return false;
    }
    
    if (trimmedAnswer.length > 500) {
      state = state.copyWith(error: 'Answer is too long (max 500 characters)');
      return false;
    }
    
    state = state.copyWith(isSubmitting: true, error: null);
    
    try {
      final result = await _repository.submitAnswer(
        questionId: questionId,
        answer: trimmedAnswer,
      );
      
      if (result.success) {
        // Update local state
        final newAnswers = Map<String, String>.from(state.answers);
        newAnswers[questionId] = trimmedAnswer;
        
        final newSubmitted = Map<String, bool>.from(state.submittedAnswers);
        newSubmitted[questionId] = true;
        
        final newEditing = Map<String, bool>.from(state.editingAnswers);
        newEditing[questionId] = false;
        
        // Clear any auto-save timer for this question
        final newTimers = Map<String, int>.from(state.autoSaveTimers);
        newTimers.remove(questionId);
        
        state = state.copyWith(
          isSubmitting: false,
          answers: newAnswers,
          submittedAnswers: newSubmitted,
          editingAnswers: newEditing,
          autoSaveTimers: newTimers,
        );
        
        // Auto-advance to next question
        _advanceToNextQuestion();
        
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: result.error ?? 'Failed to save answer',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _extractErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to submit answer',
      );
      return false;
    }
  }

  // Schedule auto-save for an answer
  void scheduleAutoSave(String questionId, String answer) {
    final trimmedAnswer = answer.trim();
    
    // Don't auto-save if answer is too short or already submitted
    if (trimmedAnswer.length < 3 || state.submittedAnswers[questionId] == true) {
      return;
    }
    
    // Clear existing timer
    _clearAutoSaveTimer(questionId);
    
    // Schedule new timer
    final timerId = DateTime.now().millisecondsSinceEpoch;
    final newTimers = Map<String, int>.from(state.autoSaveTimers);
    newTimers[questionId] = timerId;
    state = state.copyWith(autoSaveTimers: newTimers);
    
    // Execute auto-save after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (state.autoSaveTimers[questionId] == timerId) {
        submitAnswer(questionId, answer);
      }
    });
  }

  // Clear auto-save timer for a question
  void _clearAutoSaveTimer(String questionId) {
    final timerId = state.autoSaveTimers[questionId];
    if (timerId != null) {
      final newTimers = Map<String, int>.from(state.autoSaveTimers);
      newTimers.remove(questionId);
      state = state.copyWith(autoSaveTimers: newTimers);
    }
  }

  // Update answer text
  void updateAnswer(String questionId, String answer) {
    final newAnswers = Map<String, String>.from(state.answers);
    newAnswers[questionId] = answer;
    
    // If this answer was previously submitted, mark it as editing
    final newEditing = Map<String, bool>.from(state.editingAnswers);
    if (state.submittedAnswers[questionId] == true) {
      newEditing[questionId] = true;
    }
    
    state = state.copyWith(
      answers: newAnswers,
      editingAnswers: newEditing,
    );
  }

  // Skip a question
  void skipQuestion(String questionId) {
    final newHidden = Map<String, bool>.from(state.hiddenQuestions);
    newHidden[questionId] = true;
    
    state = state.copyWith(hiddenQuestions: newHidden);
    
    // Auto-advance to next question
    _advanceToNextQuestion();
  }

  // Toggle edit mode for a question
  void toggleEditMode(String questionId) {
    final newEditing = Map<String, bool>.from(state.editingAnswers);
    newEditing[questionId] = !(newEditing[questionId] ?? false);
    
    state = state.copyWith(editingAnswers: newEditing);
  }

  // Navigate to previous question
  void goToPreviousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  // Navigate to next question
  void goToNextQuestion() {
    if (state.currentIndex < state.visibleQuestions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  // Navigate to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < state.visibleQuestions.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  // Reset state
  void reset() {
    state = const IcebreakerState();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Private helper methods
  void _advanceToNextQuestion() {
    if (state.currentIndex < state.visibleQuestions.length - 1) {
      goToNextQuestion();
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
final icebreakerControllerProvider = StateNotifierProvider.autoDispose
  .family<IcebreakerController, IcebreakerState, String>(
    (ref, sessionId) {
      return IcebreakerController(ref);
    },
  );

// Provider for daily icebreakers (simplified access)
final dailyIcebreakersProvider = FutureProvider.autoDispose<List<Icebreaker>>(
  (ref) async {
    final repository = ref.read(icebreakerRepositoryProvider);
    return repository.fetchDailyIcebreakers();
  },
);