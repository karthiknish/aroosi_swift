import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../features/compatibility/models.dart';
import '../../features/compatibility/questions_data.dart';

class IslamicCompatibilityAssessmentScreen extends ConsumerStatefulWidget {
  const IslamicCompatibilityAssessmentScreen({super.key});

  @override
  ConsumerState<IslamicCompatibilityAssessmentScreen> createState() => _IslamicCompatibilityAssessmentScreenState();
}

class _IslamicCompatibilityAssessmentScreenState extends ConsumerState<IslamicCompatibilityAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentCategoryIndex = 0;
  final Map<String, dynamic> _responses = {};
  bool _isLoading = false;
  
  late List<IslamicCompatibilityCategory> _categories;

  @override
  void initState() {
    super.initState();
    _categories = IslamicCompatibilityQuestions.getCategories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Islamic Compatibility Assessment',
          style: GoogleFonts.nunitoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmationDialog(),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          
          // Category Name
          _buildCategoryHeader(),
          
          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentCategoryIndex = index;
                });
              },
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryQuestions(_categories[index]);
              },
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentCategoryIndex + 1} of ${_categories.length}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${(_getProgressPercentage() * 100).round()}% Complete',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _getProgressPercentage(),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    final category = _categories[_currentCategoryIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: GoogleFonts.nunitoSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.description,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryQuestions(IslamicCompatibilityCategory category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: category.questions.asMap().entries.map((entry) {
          final questionIndex = entry.key;
          final question = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _QuestionCard(
              question: question,
              questionNumber: questionIndex + 1,
              initialAnswer: _responses[question.id],
              onAnswerChanged: (answer) {
                setState(() {
                  _responses[question.id] = answer;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentCategoryIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _goToPreviousCategory,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (_currentCategoryIndex > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _goToNextCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentCategoryIndex == _categories.length - 1
                          ? 'Complete Assessment'
                          : 'Next',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  double _getProgressPercentage() {
    int answeredQuestions = 0;
    int totalQuestions = 0;
    
    for (int i = 0; i <= _currentCategoryIndex; i++) {
      final category = _categories[i];
      totalQuestions += category.questions.length;
      
      if (i < _currentCategoryIndex) {
        answeredQuestions += category.questions.length;
      } else {
        // Count answered questions in current category
        for (final question in category.questions) {
          if (_responses.containsKey(question.id)) {
            answeredQuestions++;
          }
        }
      }
    }
    
    return totalQuestions > 0 ? answeredQuestions / totalQuestions : 0.0;
  }

  void _goToPreviousCategory() {
    if (_currentCategoryIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextCategory() async {
    // Validate current category
    final currentCategory = _categories[_currentCategoryIndex];
    final unansweredQuestions = currentCategory.questions
        .where((q) => q.isRequired && !_responses.containsKey(q.id))
        .toList();
    
    if (unansweredQuestions.isNotEmpty) {
      _showValidationDialog(unansweredQuestions);
      return;
    }
    
    if (_currentCategoryIndex < _categories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete assessment
      await _completeAssessment();
    }
  }

  void _showValidationDialog(List<CompatibilityQuestion> unansweredQuestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Please Complete All Questions',
          style: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please answer the following required questions:',
              style: GoogleFonts.nunitoSans(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...unansweredQuestions.map(
              (question) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        question.text ?? 'Question text not available',
                        style: GoogleFonts.nunitoSans(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.nunitoSans(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Assessment?',
          style: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: GoogleFonts.nunitoSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunitoSans(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit screen
            },
            child: Text(
              'Exit',
              style: GoogleFonts.nunitoSans(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeAssessment() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create response object (would normally get user ID from auth)
      CompatibilityResponse(
        userId: 'current_user_id', // This should come from auth
        responses: _responses,
        completedAt: DateTime.now(),
      );
      
      // Here you would normally save the response to your backend
      // For now, we'll just show completion dialog
      
      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error completing assessment: $e',
              style: GoogleFonts.nunitoSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Assessment Complete!',
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thank you for completing the Islamic Compatibility Assessment. Your responses will help us find better matches for you based on shared Islamic values and lifestyle preferences.',
              style: GoogleFonts.nunitoSans(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can retake this assessment anytime from your profile settings.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit screen
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.nunitoSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final CompatibilityQuestion question;
  final int questionNumber;
  final dynamic initialAnswer;
  final Function(dynamic) onAnswerChanged;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.initialAnswer,
    required this.onAnswerChanged,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  dynamic _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _selectedAnswer = widget.initialAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      widget.questionNumber.toString(),
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.question.text,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.question.isRequired)
                  const Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnswerOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    switch (widget.question.type) {
      case QuestionType.singleChoice:
      case QuestionType.yesNo:
        return _buildSingleChoiceOptions();
      case QuestionType.scale:
        return _buildScaleOptions();
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOptions();
    }
    return const SizedBox(); // Default case
  }

  Widget _buildSingleChoiceOptions() {
    return Column(
      children: widget.question.options.map((option) {
        final isSelected = _selectedAnswer == option.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswer = option.id;
              });
              widget.onAnswerChanged(option.id);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.text,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: isSelected ? AppColors.primary : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScaleOptions() {
    return Column(
      children: widget.question.options.map((option) {
        final isSelected = _selectedAnswer == option.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswer = option.id;
              });
              widget.onAnswerChanged(option.id);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.text,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: isSelected ? AppColors.primary : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceOptions() {
    final List<String> selectedAnswers = _selectedAnswer is List ? List<String>.from(_selectedAnswer) : [];
    
    return Column(
      children: widget.question.options.map((option) {
        final isSelected = selectedAnswers.contains(option.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedAnswers.remove(option.id);
                } else {
                  selectedAnswers.add(option.id);
                }
                _selectedAnswer = selectedAnswers;
              });
              widget.onAnswerChanged(selectedAnswers);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.text,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: isSelected ? AppColors.primary : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
