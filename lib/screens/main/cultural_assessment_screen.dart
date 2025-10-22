import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/core/api_error_handler.dart';
import 'package:aroosi_flutter/theme/colors.dart';

class CulturalAssessmentScreen extends ConsumerStatefulWidget {
  const CulturalAssessmentScreen({super.key});

  @override
  ConsumerState<CulturalAssessmentScreen> createState() => _CulturalAssessmentScreenState();
}

class _CulturalAssessmentScreenState extends ConsumerState<CulturalAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final Map<String, dynamic> _answers = {};
  bool _isLoading = false;

  final List<AssessmentStep> _steps = [
    AssessmentStep(
      id: 'religion',
      title: 'Religious Values',
      icon: Icons.mosque,
      questions: [
        AssessmentQuestion(
          id: 'religion',
          text: 'What is your religious affiliation?',
          type: 'single_choice',
          options: [
            'Islam (Sunni)',
            'Islam (Shia)',
            'Christianity',
            'Other',
            'Not religious',
          ],
        ),
        AssessmentQuestion(
          id: 'religiousPractice',
          text: 'How religious are you?',
          type: 'scale',
          scale: {
            'min': 1,
            'max': 10,
            'labels': {
              1: 'Not at all',
              10: 'Very religious',
            },
          },
        ),
        AssessmentQuestion(
          id: 'importanceOfReligion',
          text: 'How important is religion in your partner?',
          type: 'scale',
          scale: {
            'min': 1,
            'max': 10,
            'labels': {
              1: 'Not important',
              10: 'Very important',
            },
          },
        ),
      ],
    ),
    AssessmentStep(
      id: 'language',
      title: 'Language & Communication',
      icon: Icons.language,
      questions: [
        AssessmentQuestion(
          id: 'motherTongue',
          text: 'What is your mother tongue?',
          type: 'single_choice',
          options: ['Farsi (Dari)', 'Pashto', 'Uzbek', 'Turkmen', 'Other'],
        ),
        AssessmentQuestion(
          id: 'languages',
          text: 'What other languages do you speak?',
          type: 'multiple_choice',
          options: [
            'Farsi (Dari)',
            'Pashto',
            'Uzbek',
            'Turkmen',
            'English',
            'Arabic',
            'Urdu',
          ],
        ),
        AssessmentQuestion(
          id: 'languagePreference',
          text: 'What language do you prefer for communication with your partner?',
          type: 'single_choice',
          options: [
            'Same language as me',
            'English is fine',
            'Any language as long as we communicate well',
          ],
        ),
      ],
    ),
    AssessmentStep(
      id: 'family',
      title: 'Family Values',
      icon: Icons.family_restroom,
      questions: [
        AssessmentQuestion(
          id: 'familyValues',
          text: 'How would you describe your family values?',
          type: 'single_choice',
          options: [
            'Very traditional',
            'Somewhat traditional',
            'Modern with traditional elements',
            'Very modern',
          ],
        ),
        AssessmentQuestion(
          id: 'marriageViews',
          text: 'What are your views on marriage?',
          type: 'single_choice',
          options: [
            'Traditional marriage is essential',
            'Marriage with some traditional elements',
            'Modern marriage approach',
            'Open to different types of partnerships',
          ],
        ),
        AssessmentQuestion(
          id: 'familyInvolvement',
          text: 'How involved should family be in your relationship?',
          type: 'scale',
          scale: {
            'min': 1,
            'max': 10,
            'labels': {
              1: 'Not involved at all',
              10: 'Very involved',
            },
          },
        ),
      ],
    ),
    AssessmentStep(
      id: 'lifestyle',
      title: 'Lifestyle & Traditions',
      icon: Icons.celebration,
      questions: [
        AssessmentQuestion(
          id: 'traditionalValues',
          text: 'How important are traditional Afghan values in your life?',
          type: 'scale',
          scale: {
            'min': 1,
            'max': 10,
            'labels': {
              1: 'Not important',
              10: 'Very important',
            },
          },
        ),
        AssessmentQuestion(
          id: 'culturalEvents',
          text: 'How often do you participate in cultural events?',
          type: 'single_choice',
          options: [
            'Very often',
            'Sometimes',
            'Rarely',
            'Never',
          ],
        ),
        AssessmentQuestion(
          id: 'foodPreferences',
          text: 'How important is Afghan cuisine in your lifestyle?',
          type: 'scale',
          scale: {
            'min': 1,
            'max': 10,
            'labels': {
              1: 'Not important',
              10: 'Very important',
            },
          },
        ),
      ],
    ),
  ];

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
          'Cultural Assessment',
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return _buildStepContent(step);
              },
            ),
          ),

          // Navigation buttons
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
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${((_currentStep + 1) / _steps.length * 100).round()}%',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: AppColors.borderPrimary,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(AssessmentStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  step.icon,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    step.title,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Questions
          ...step.questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildQuestion(question),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(AssessmentQuestion question) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuestionInput(question),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(AssessmentQuestion question) {
    switch (question.type) {
      case 'single_choice':
        return Column(
          children: question.options!.map(
            (option) => RadioListTile<String>(
              title: Text(
                option,
                style: GoogleFonts.nunitoSans(fontSize: 14),
              ),
              value: option,
              groupValue: _answers[question.id],
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
              },
            ),
          ).toList(),
        );
      case 'multiple_choice':
        return Column(
          children: question.options!.map(
            (option) => CheckboxListTile(
              title: Text(
                option,
                style: GoogleFonts.nunitoSans(fontSize: 14),
              ),
              value: (_answers[question.id] as List<String>?)?.contains(option) ?? false,
              onChanged: (value) {
                setState(() {
                  final currentAnswers = _answers[question.id] as List<String>? ?? [];
                  if (value == true) {
                    currentAnswers.add(option);
                  } else {
                    currentAnswers.remove(option);
                  }
                  _answers[question.id] = currentAnswers;
                });
              },
            ),
          ).toList(),
        );
      case 'scale':
        final scale = question.scale!;
        return Column(
          children: [
            Slider(
              value: (_answers[question.id] as int?)?.toDouble() ?? 5.0,
              min: scale['min']!.toDouble(),
              max: scale['max']!.toDouble(),
              divisions: scale['max']! - scale['min']!,
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value.round();
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: scale['labels']!.entries.map(
                (entry) => Text(
                  '${entry.key}: ${entry.value}',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Current: ${_answers[question.id] ?? 5}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      _currentStep == _steps.length - 1 ? 'Complete' : 'Next',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _submitAssessment();
    }
  }

  Future<void> _submitAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Use the correct endpoint: /api/cultural/profile/[userId]
      final response = await ApiClient.dio.post(
        '/api/cultural/profile/${currentUser.uid}',
        data: {
          'religion': _answers['religion'] ?? '',
          'religiousPractice': _answers['religiousPractice'] ?? '',
          'motherTongue': _answers['motherTongue'] ?? '',
          'languages': _answers['languages'] ?? [],
          'familyValues': _answers['familyValues'] ?? '',
          'marriageViews': _answers['marriageViews'] ?? '',
          'traditionalValues': _answers['traditionalValues'] ?? '',
          'importanceOfReligion': int.tryParse(_answers['importanceOfReligion']?.toString() ?? '5') ?? 5,
          'importanceOfCulture': int.tryParse(_answers['importanceOfCulture']?.toString() ?? '5') ?? 5,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save assessment (${response.statusCode})'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ApiErrorHandler.logError(e, 'Submit cultural assessment');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHandler.getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: AppColors.error,
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

  void _showExitDialog() {
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
              style: GoogleFonts.nunitoSans(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Exit',
              style: GoogleFonts.nunitoSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Assessment Complete!',
          style: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Thank you for completing the cultural assessment. We\'ll use this information to find better matches for you.',
          style: GoogleFonts.nunitoSans(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Great!',
              style: GoogleFonts.nunitoSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class AssessmentStep {
  final String id;
  final String title;
  final IconData icon;
  final List<AssessmentQuestion> questions;

  const AssessmentStep({
    required this.id,
    required this.title,
    required this.icon,
    required this.questions,
  });
}

class AssessmentQuestion {
  final String id;
  final String text;
  final String type;
  final List<String>? options;
  final Map<String, dynamic>? scale;

  const AssessmentQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.scale,
  });
}