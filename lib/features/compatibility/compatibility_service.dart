import 'package:uuid/uuid.dart';
import 'models.dart';
import 'questions_data.dart';

class CompatibilityService {
  static const Uuid _uuid = Uuid();

  /// Calculate compatibility between two users based on their responses
  static CompatibilityScore calculateCompatibility(
    CompatibilityResponse user1Response,
    CompatibilityResponse user2Response,
  ) {
    final categories = IslamicCompatibilityQuestions.getCategories();
    final Map<String, double> categoryScores = {};
    double totalWeightedScore = 0.0;

    for (final category in categories) {
      final double categoryScore = _calculateCategoryScore(
        category,
        user1Response.responses,
        user2Response.responses,
      );
      categoryScores[category.id] = categoryScore;
      totalWeightedScore += categoryScore * category.weight;
    }

    // Normalize to 0-100 scale
    final double overallScore = (totalWeightedScore * 100);

    return CompatibilityScore(
      userId1: user1Response.userId,
      userId2: user2Response.userId,
      overallScore: overallScore,
      categoryScores: categoryScores,
      calculatedAt: DateTime.now(),
      detailedBreakdown: _generateDetailedBreakdown(categoryScores, categories),
    );
  }

  /// Calculate score for a specific category
  static double _calculateCategoryScore(
    IslamicCompatibilityCategory category,
    Map<String, dynamic> user1Responses,
    Map<String, dynamic> user2Responses,
  ) {
    double totalScore = 0.0;
    int questionCount = 0;

    for (final question in category.questions) {
      final double questionScore = _calculateQuestionScore(
        question,
        user1Responses[question.id],
        user2Responses[question.id],
      );
      
      if (questionScore >= 0) { // Valid comparison
        totalScore += questionScore;
        questionCount++;
      }
    }

    return questionCount > 0 ? totalScore / questionCount : 0.0;
  }

  /// Calculate score for a single question
  static double _calculateQuestionScore(
    CompatibilityQuestion question,
    dynamic user1Answer,
    dynamic user2Answer,
  ) {
    if (user1Answer == null || user2Answer == null) {
      return -1.0; // Invalid comparison
    }

    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.yesNo:
        return _compareSingleChoice(question, user1Answer, user2Answer);
      
      case QuestionType.scale:
        return _compareScale(question, user1Answer, user2Answer);
      
      case QuestionType.multipleChoice:
        return _compareMultipleChoice(question, user1Answer, user2Answer);
    }
  }

  /// Compare single choice answers
  static double _compareSingleChoice(
    CompatibilityQuestion question,
    String user1Answer,
    String user2Answer,
  ) {
    final option1 = question.options.firstWhere((opt) => opt.id == user1Answer);
    final option2 = question.options.firstWhere((opt) => opt.id == user2Answer);
    
    // Direct value comparison
    if (option1.value == option2.value) {
      return 1.0;
    }
    
    // Calculate similarity based on value difference
    final double difference = (option1.value - option2.value).abs();
    return 1.0 - difference;
  }

  /// Compare scale answers
  static double _compareScale(
    CompatibilityQuestion question,
    String user1Answer,
    String user2Answer,
  ) {
    final option1 = question.options.firstWhere((opt) => opt.id == user1Answer);
    final option2 = question.options.firstWhere((opt) => opt.id == user2Answer);
    
    // Calculate similarity based on value difference
    final double difference = (option1.value - option2.value).abs();
    return 1.0 - difference;
  }

  /// Compare multiple choice answers
  static double _compareMultipleChoice(
    CompatibilityQuestion question,
    List<String> user1Answers,
    List<String> user2Answers,
  ) {
    if (user1Answers.isEmpty && user2Answers.isEmpty) {
      return 1.0;
    }
    
    // Calculate overlap
    final Set<String> set1 = user1Answers.toSet();
    final Set<String> set2 = user2Answers.toSet();
    final Set<String> intersection = set1.intersection(set2);
    final Set<String> union = set1.union(set2);
    
    if (union.isEmpty) {
      return 1.0;
    }
    
    return intersection.length / union.length;
  }

  /// Generate detailed breakdown for analysis
  static Map<String, dynamic> _generateDetailedBreakdown(
    Map<String, double> categoryScores,
    List<IslamicCompatibilityCategory> categories,
  ) {
    final Map<String, dynamic> breakdown = {};
    
    for (final category in categories) {
      final score = categoryScores[category.id] ?? 0.0;
      breakdown[category.id] = {
        'name': category.name,
        'score': score,
        'weight': category.weight,
        'weightedScore': score * category.weight,
        'description': _getCategoryDescription(score),
      };
    }
    
    return breakdown;
  }

  /// Get description for category score
  static String _getCategoryDescription(double score) {
    if (score >= 0.9) {
      return 'Excellent alignment in this area';
    } else if (score >= 0.8) {
      return 'Strong compatibility in this area';
    } else if (score >= 0.7) {
      return 'Good match in this area';
    } else if (score >= 0.6) {
      return 'Moderate compatibility - some discussion needed';
    } else if (score >= 0.5) {
      return 'Fair compatibility - may require compromise';
    } else {
      return 'Low compatibility - careful consideration needed';
    }
  }

  /// Generate personalized recommendations based on compatibility scores
  static List<String> generateRecommendations(CompatibilityScore score) {
    final List<String> recommendations = [];
    
    // Overall recommendations
    if (score.overallScore >= 80) {
      recommendations.add('You have excellent compatibility! Focus on building on your shared strengths.');
    } else if (score.overallScore >= 70) {
      recommendations.add('Good compatibility! Discuss minor differences to strengthen your connection.');
    } else if (score.overallScore >= 60) {
      recommendations.add('Moderate compatibility. Open communication about differences will be important.');
    } else {
      recommendations.add('Take time to understand your differences before making commitments.');
    }
    
    // Category-specific recommendations
    for (final categoryEntry in score.categoryScores.entries) {
      final categoryId = categoryEntry.key;
      final categoryScore = categoryEntry.value;
      
      if (categoryScore < 0.6) {
        recommendations.add(_getCategoryRecommendation(categoryId, categoryScore));
      }
    }
    
    return recommendations;
  }

  /// Get specific recommendation for a category
  static String _getCategoryRecommendation(String categoryId, double score) {
    switch (categoryId) {
      case 'religious_practice':
        return 'Discuss your religious practices and find common ground in daily worship.';
      case 'family_structure':
        return 'Have open conversations about family expectations and parenting approaches.';
      case 'cultural_values':
        return 'Explore each other\'s cultural backgrounds and find ways to honor both traditions.';
      case 'financial_management':
        return 'Create a financial plan that respects both your values regarding halal income and charity.';
      case 'education_career':
        return 'Discuss career goals and work-life balance expectations early in your relationship.';
      case 'social_life':
        return 'Find a balance between community involvement and personal time together.';
      case 'conflict_resolution':
        return 'Establish healthy communication patterns for resolving disagreements respectfully.';
      case 'life_goals':
        return 'Align on major life decisions including location and family planning.';
      default:
        return 'Take time to understand your differences in this important area.';
    }
  }

  /// Create a shareable compatibility report
  static CompatibilityReport createReport(
    CompatibilityScore scores,
    String userId1,
    String userId2, {
    List<FamilyFeedback>? familyFeedback,
  }) {
    return CompatibilityReport(
      id: _uuid.v4(),
      userId1: userId1,
      userId2: userId2,
      scores: scores,
      generatedAt: DateTime.now(),
      familyFeedback: familyFeedback,
    );
  }

  /// Add family feedback to a report
  static FamilyFeedback addFamilyFeedback({
    required String reportId,
    required String familyMemberName,
    required String relationship,
    required String feedback,
  }) {
    return FamilyFeedback(
      id: _uuid.v4(),
      reportId: reportId,
      familyMemberName: familyMemberName,
      relationship: relationship,
      feedback: feedback,
      createdAt: DateTime.now(),
    );
  }

  /// Validate that all required questions are answered
  static bool validateResponse(
    CompatibilityResponse response,
    List<IslamicCompatibilityCategory> categories,
  ) {
    for (final category in categories) {
      for (final question in category.questions) {
        if (question.isRequired && !response.responses.containsKey(question.id)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Get unanswered questions for a response
  static List<CompatibilityQuestion> getUnansweredQuestions(
    CompatibilityResponse response,
    List<IslamicCompatibilityCategory> categories,
  ) {
    final List<CompatibilityQuestion> unanswered = [];
    
    for (final category in categories) {
      for (final question in category.questions) {
        if (question.isRequired && !response.responses.containsKey(question.id)) {
          unanswered.add(question);
        }
      }
    }
    
    return unanswered;
  }
}
