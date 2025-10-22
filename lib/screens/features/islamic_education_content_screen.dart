import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../features/islamic_education/models.dart';
import '../../features/islamic_education/services.dart';

class IslamicEducationContentScreen extends ConsumerStatefulWidget {
  final IslamicEducationalContent content;

  const IslamicEducationContentScreen({
    super.key,
    required this.content,
  });

  @override
  ConsumerState<IslamicEducationContentScreen> createState() => _IslamicEducationContentScreenState();
}

class _IslamicEducationContentScreenState extends ConsumerState<IslamicEducationContentScreen> {
  bool _isLoading = false;
  double _readingProgress = 0.0;
  bool _isBookmarked = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _trackContentStart();
  }

  Future<void> _trackContentStart() async {
    // Track that user started reading this content
    // This would normally get current user ID from auth
    final userId = 'current_user_id';
    await IslamicEducationService.trackContentProgress(
      userId: userId,
      contentId: widget.content.id,
      progress: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.content.title,
          style: GoogleFonts.nunitoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: _toggleLike,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  ...widget.content.content.sections.map((section) {
                    return _buildContentSection(section);
                  }).toList(),
                  
                  if (widget.content.content.quranicVerses != null) ...[
                    const SizedBox(height: 24),
                    _buildQuranicVerses(),
                  ],
                  
                  if (widget.content.content.hadiths != null) ...[
                    const SizedBox(height: 24),
                    _buildHadiths(),
                  ],
                  
                  if (widget.content.content.keyTakeaways != null) ...[
                    const SizedBox(height: 24),
                    _buildKeyTakeaways(),
                  ],
                  
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LinearProgressIndicator(
        value: _readingProgress,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getCategoryLabel(widget.content.category),
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getDifficultyLabel(widget.content.difficultyLevel),
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.content.title,
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.content.description,
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.content.estimatedReadTime} min read',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.visibility,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.content.viewCount} views',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentSection(ContentSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.nunitoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            section.content,
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranicVerses() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Quranic Verses',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.content.content.quranicVerses!.map((verse) {
            return _QuranicVerseCard(verse: verse);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHadiths() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mosque,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Prophetic Teachings',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.content.content.hadiths!.map((hadith) {
            return _HadithCard(hadith: hadith);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildKeyTakeaways() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Takeaways',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.content.content.keyTakeaways!.map((takeaway) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      takeaway,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.content.quiz != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToQuiz,
              icon: const Icon(Icons.quiz),
              label: Text(
                'Take Quiz',
                style: GoogleFonts.nunitoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        
        if (widget.content.quiz != null) const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareContent,
            icon: const Icon(Icons.share),
            label: Text(
              'Share',
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    if (_isBookmarked) {
      final userId = 'current_user_id';
      await IslamicEducationService.bookmarkContent(widget.content.id, userId);
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      final userId = 'current_user_id';
      await IslamicEducationService.likeContent(widget.content.id, userId);
    }
  }

  void _navigateToQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IslamicEducationQuizScreen(
          quiz: widget.content.quiz!,
          contentId: widget.content.id,
          contentTitle: widget.content.title,
        ),
      ),
    );
  }

  void _shareContent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share feature coming soon!',
          style: GoogleFonts.nunitoSans(),
        ),
      ),
    );
  }

  String _getCategoryLabel(EducationCategory category) {
    switch (category) {
      case EducationCategory.marriagePrinciples:
        return 'Marriage Principles';
      case EducationCategory.quranicGuidance:
        return 'Quranic Guidance';
      case EducationCategory.propheticTeachings:
        return 'Prophetic Teachings';
      case EducationCategory.afghanCulture:
        return 'Afghan Culture';
      case EducationCategory.familyLife:
        return 'Family Life';
      case EducationCategory.communication:
        return 'Communication';
      case EducationCategory.conflictResolution:
        return 'Conflict Resolution';
      case EducationCategory.financialManagement:
        return 'Financial Management';
      case EducationCategory.parenting:
        return 'Parenting';
      case EducationCategory.general:
        return 'General';
    }
  }

  String _getDifficultyLabel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
    }
  }
}

class _QuranicVerseCard extends StatelessWidget {
  final QuranicVerse verse;

  const _QuranicVerseCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Surah ${verse.surahNumber}:${verse.ayahNumber}',
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verse.arabicText,
            style: GoogleFonts.notoSansArabic(
              fontSize: 18,
              height: 1.8,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          Text(
            verse.englishTranslation,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (verse.transliteration.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              verse.transliteration,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (verse.relevanceToMarriage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💡 ${verse.relevanceToMarriage}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.green[800],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final Hadith hadith;

  const _HadithCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getHadithSourceLabel(hadith.source),
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getAuthenticityColor(hadith.authenticityGrade).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getAuthenticityLabel(hadith.authenticityGrade),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 10,
                    color: _getAuthenticityColor(hadith.authenticityGrade),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Narrated by ${hadith.narrator}',
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hadith.arabicText,
            style: GoogleFonts.notoSansArabic(
              fontSize: 16,
              height: 1.8,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          Text(
            hadith.englishTranslation,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
            ),
          ),
          if (hadith.relevanceToMarriage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💡 ${hadith.relevanceToMarriage}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
          if (hadith.explanation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '📖 ${hadith.explanation}',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getHadithSourceLabel(HadithSource source) {
    switch (source) {
      case HadithSource.bukhari:
        return 'Sahih Bukhari';
      case HadithSource.muslim:
        return 'Sahih Muslim';
      case HadithSource.abuDawud:
        return 'Abu Dawud';
      case HadithSource.tirmidhi:
        return 'Tirmidhi';
      case HadithSource.nasai:
        return 'Nasai';
      case HadithSource.ibnMajah:
        return 'Ibn Majah';
      case HadithSource.malik:
        return 'Muwatta Malik';
      case HadithSource.ahmad:
        return 'Musnad Ahmad';
    }
  }

  String _getAuthenticityLabel(AuthenticityGrade grade) {
    switch (grade) {
      case AuthenticityGrade.sahih:
        return 'Sahih';
      case AuthenticityGrade.hasan:
        return 'Hasan';
      case AuthenticityGrade.daif:
        return 'Daif';
      case AuthenticityGrade.mawdu:
        return 'Mawdu';
    }
  }

  Color _getAuthenticityColor(AuthenticityGrade grade) {
    switch (grade) {
      case AuthenticityGrade.sahih:
        return Colors.green;
      case AuthenticityGrade.hasan:
        return Colors.blue;
      case AuthenticityGrade.daif:
        return Colors.orange;
      case AuthenticityGrade.mawdu:
        return Colors.red;
    }
  }
}

// Placeholder quiz screen
class IslamicEducationQuizScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: $contentTitle'),
      ),
      body: Center(
        child: Text('Quiz functionality coming soon!'),
      ),
    );
  }
}
