class IslamicCompatibilityCategory {
  const IslamicCompatibilityCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
    required this.questions,
  });

  final String id;
  final String name;
  final String description;
  final double weight; // Weight of this category in overall score (0.0-1.0)
  final List<CompatibilityQuestion> questions;
}

class CompatibilityQuestion {
  const CompatibilityQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    this.isRequired = true,
  });

  final String id;
  final String text;
  final QuestionType type;
  final List<QuestionOption> options;
  final bool isRequired;
}

class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.text,
    required this.value,
  });

  final String id;
  final String text;
  final double value; // Score value for this option (0.0-1.0)
}

enum QuestionType {
  singleChoice,
  multipleChoice,
  scale,
  yesNo,
}

class CompatibilityResponse {
  const CompatibilityResponse({
    required this.userId,
    required this.responses,
    required this.completedAt,
  });

  final String userId;
  final Map<String, dynamic> responses; // questionId -> selected answer(s)
  final DateTime completedAt;
}

class CompatibilityScore {
  const CompatibilityScore({
    required this.userId1,
    required this.userId2,
    required this.overallScore,
    required this.categoryScores,
    required this.calculatedAt,
    this.detailedBreakdown,
  });

  final String userId1;
  final String userId2;
  final double overallScore; // 0.0-100.0
  final Map<String, double> categoryScores; // categoryId -> score
  final DateTime calculatedAt;
  final Map<String, dynamic>? detailedBreakdown;

  String getCompatibilityLevel() {
    if (overallScore >= 90) return 'Excellent Match';
    if (overallScore >= 80) return 'Strong Match';
    if (overallScore >= 70) return 'Good Match';
    if (overallScore >= 60) return 'Moderate Match';
    if (overallScore >= 50) return 'Fair Match';
    return 'Low Compatibility';
  }

  String getCompatibilityDescription() {
    if (overallScore >= 90) {
      return 'Exceptional compatibility across all Islamic values and lifestyle preferences';
    }
    if (overallScore >= 80) {
      return 'Strong alignment in key areas of Islamic practice and values';
    }
    if (overallScore >= 70) {
      return 'Good compatibility with minor differences in some areas';
    }
    if (overallScore >= 60) {
      return 'Moderate compatibility with some areas requiring discussion';
    }
    if (overallScore >= 50) {
      return 'Fair compatibility that may need compromise and understanding';
    }
    return 'Significant differences that may require careful consideration';
  }
}

class CompatibilityReport {
  const CompatibilityReport({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.scores,
    required this.generatedAt,
    this.familyFeedback,
    this.isShared = false,
  });

  final String id;
  final String userId1;
  final String userId2;
  final CompatibilityScore scores;
  final DateTime generatedAt;
  final List<FamilyFeedback>? familyFeedback;
  final bool isShared;
}

class FamilyFeedback {
  const FamilyFeedback({
    required this.id,
    required this.reportId,
    required this.familyMemberName,
    required this.relationship,
    required this.feedback,
    required this.createdAt,
    this.approvalStatus = ApprovalStatus.pending,
  });

  final String id;
  final String reportId;
  final String familyMemberName;
  final String relationship;
  final String feedback;
  final DateTime createdAt;
  final ApprovalStatus approvalStatus;
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
}
