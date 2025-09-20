import 'package:equatable/equatable.dart';

class IcebreakerQuestion extends Equatable {
  const IcebreakerQuestion({
    required this.id,
    required this.text,
    this.active = true,
    this.category,
    this.weight = 1,
    this.createdAt,
  });

  final String id;
  final String text;
  final bool active;
  final String? category;
  final int weight;
  final int? createdAt; // epoch millis

  IcebreakerQuestion copyWith({
    String? id,
    String? text,
    bool? active,
    String? category,
    int? weight,
    int? createdAt,
  }) => IcebreakerQuestion(
    id: id ?? this.id,
    text: text ?? this.text,
    active: active ?? this.active,
    category: category ?? this.category,
    weight: weight ?? this.weight,
    createdAt: createdAt ?? this.createdAt,
  );

  static IcebreakerQuestion fromJson(Map<String, dynamic> json) {
    return IcebreakerQuestion(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      active: json['active'] == true,
      category: json['category']?.toString(),
      weight: json['weight'] is int
          ? json['weight']
          : int.tryParse(json['weight']?.toString() ?? '') ?? 1,
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [id, text, active, category, weight, createdAt];
}

class Icebreaker extends Equatable {
  const Icebreaker({
    required this.id,
    required this.text,
    this.answered = false,
    this.answer,
  });

  final String id;
  final String text;
  final bool answered;
  final String? answer;

  Icebreaker copyWith({
    String? id,
    String? text,
    bool? answered,
    String? answer,
  }) => Icebreaker(
    id: id ?? this.id,
    text: text ?? this.text,
    answered: answered ?? this.answered,
    answer: answer ?? this.answer,
  );

  static Icebreaker fromJson(Map<String, dynamic> json) {
    return Icebreaker(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      answered: json['answered'] == true,
      answer: json['answer']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, text, answered, answer];
}

class IcebreakerAnswer extends Equatable {
  const IcebreakerAnswer({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.answer,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String questionId;
  final String answer;
  final int createdAt; // epoch millis

  IcebreakerAnswer copyWith({
    String? id,
    String? userId,
    String? questionId,
    String? answer,
    int? createdAt,
  }) => IcebreakerAnswer(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    questionId: questionId ?? this.questionId,
    answer: answer ?? this.answer,
    createdAt: createdAt ?? this.createdAt,
  );

  static IcebreakerAnswer fromJson(Map<String, dynamic> json) {
    return IcebreakerAnswer(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      questionId: json['questionId']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      createdAt: json['createdAt'] is int
          ? json['createdAt']
          : int.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  List<Object?> get props => [id, userId, questionId, answer, createdAt];
}

class IcebreakerSubmissionResult extends Equatable {
  const IcebreakerSubmissionResult({
    required this.success,
    this.created = false,
    this.updated = false,
    this.incremented = false,
    this.error,
  });

  final bool success;
  final bool created;
  final bool updated;
  final bool incremented;
  final String? error;

  IcebreakerSubmissionResult copyWith({
    bool? success,
    bool? created,
    bool? updated,
    bool? incremented,
    String? error,
  }) => IcebreakerSubmissionResult(
    success: success ?? this.success,
    created: created ?? this.created,
    updated: updated ?? this.updated,
    incremented: incremented ?? this.incremented,
    error: error ?? this.error,
  );

  static IcebreakerSubmissionResult fromJson(Map<String, dynamic> json) {
    return IcebreakerSubmissionResult(
      success: json['success'] == true,
      created: json['created'] == true,
      updated: json['updated'] == true,
      incremented: json['incremented'] == true,
      error: json['error']?.toString(),
    );
  }

  @override
  List<Object?> get props => [success, created, updated, incremented, error];
}
