import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../features/islamic_education/models.dart';
import '../../features/islamic_education/services.dart';

class IslamicEducationQuizHubScreen extends ConsumerStatefulWidget {
  const IslamicEducationQuizHubScreen({super.key});

  @override
  ConsumerState<IslamicEducationQuizHubScreen> createState() => _IslamicEducationQuizHubScreenState();
}

class _IslamicEducationQuizHubScreenState extends ConsumerState<IslamicEducationQuizHubScreen> {
  bool _isLoading = false;
  List<IslamicEducationalContent> _quizContent = [];

  @override
  void initState() {
    super.initState();
    _loadQuizContent();
  }

  Future<void> _loadQuizContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load content that has quizzes
      final content = await IslamicEducationService.getEducationalContent(limit: 20);
      final quizContent = content.where((item) => item.quiz != null).toList();
      
      setState(() {
        _quizContent = quizContent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load quiz content: $e',
              style: GoogleFonts.nunitoSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Hub',
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizContent.isEmpty
              ? _buildEmptyState()
              : _buildQuizList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Quizzes Available',
            style: GoogleFonts.nunitoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for new quizzes!',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizContent.length,
      itemBuilder: (context, index) {
        final content = _quizContent[index];
        return _QuizCard(
          content: content,
          onTap: () => _navigateToQuiz(content),
        );
      },
    );
  }

  void _navigateToQuiz(IslamicEducationalContent content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IslamicEducationQuizScreen(
          quiz: content.quiz!,
          contentId: content.id,
          contentTitle: content.title,
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final IslamicEducationalContent content;
  final VoidCallback onTap;

  const _QuizCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  size: 24,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${content.quiz!.questions.length} questions • ${content.estimatedReadTime} min',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quiz taking screen
class IslamicEducationQuizScreen extends StatefulWidget {
  final EducationalQuiz quiz;
  final String contentId;
  final String contentTitle;

  const IslamicEducationQuizScreen({
    super.key,
    required this.quiz,
    required this.contentId,
    required this.contentTitle,
  });

  @override
  State<IslamicEducationQuizScreen> createState() => _IslamicEducationQuizScreenState();
}

class _IslamicEducationQuizScreenState extends State<IslamicEducationQuizScreen> {
  int _currentQuestionIndex = 0;
  List<String> _selectedAnswers = [];
  bool _isLoading = false;
  Map<String, dynamic>? _results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.contentTitle}'),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
      ),
      body: _results != null
          ? _buildResultsScreen()
          : _buildQuestionScreen(),
    );
  }

  Widget _buildQuestionScreen() {
    if (_currentQuestionIndex >= widget.quiz.questions.length) {
      return _buildCompletionScreen();
    }

    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 16),
          
          // Question number and title
          Text(
            'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentQuestion.question,
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                final option = currentQuestion.options[index];
                final isSelected = _selectedAnswers.length > _currentQuestionIndex && 
                                _selectedAnswers[_currentQuestionIndex] == option;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _selectAnswer(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? Colors.green.withValues(alpha: 0.1) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? Colors.green : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 16,
                                color: isSelected ? Colors.green : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Navigation buttons
          SafeArea(
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Previous',
                        style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAnswers.length > _currentQuestionIndex ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentQuestionIndex == widget.quiz.questions.length - 1 ? 'Submit' : 'Next',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Calculating your results...',
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final score = _results?['score'] as double? ?? 0.0;
    final passed = _results?['passed'] as bool? ?? false;
    final percentage = (score * 100).toInt();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Results header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: passed ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: passed ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  passed ? Icons.check_circle : Icons.cancel,
                  size: 64,
                  color: passed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  passed ? 'Quiz Completed!' : 'Quiz Failed',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Score: $percentage%',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Back to Quiz Hub',
                style: GoogleFonts.nunitoSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String answer) {
    setState(() {
      if (_selectedAnswers.length <= _currentQuestionIndex) {
        _selectedAnswers.add(answer);
      } else {
        _selectedAnswers[_currentQuestionIndex] = answer;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate score
      int correctAnswers = 0;
      for (int i = 0; i < widget.quiz.questions.length; i++) {
        if (i < _selectedAnswers.length && 
            _selectedAnswers[i] == widget.quiz.questions[i].correctAnswer) {
          correctAnswers++;
        }
      }
      
      final score = correctAnswers / widget.quiz.questions.length;
      final passed = score >= widget.quiz.passingScore;
      
      // Save results to Firebase
      final userId = 'current_user_id'; // This should come from auth
      await IslamicEducationService.saveQuizResults(
        userId: userId,
        contentId: widget.contentId,
        quizId: widget.quiz.id,
        answers: _selectedAnswers,
        score: score,
        passed: passed,
        timeSpent: 0, // Would track actual time
      );
      
      setState(() {
        _results = {
          'score': score,
          'passed': passed,
          'correctAnswers': correctAnswers,
          'totalQuestions': widget.quiz.questions.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error submitting quiz: $e',
              style: GoogleFonts.nunitoSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
