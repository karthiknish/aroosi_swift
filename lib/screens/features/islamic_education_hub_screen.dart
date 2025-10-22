import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../features/islamic_education/models.dart';
import '../../features/islamic_education/services.dart';
import 'islamic_education_content_screen.dart';
import 'islamic_education_quiz_screen.dart';
import 'afghan_traditions_screen.dart';

class IslamicEducationHubScreen extends ConsumerStatefulWidget {
  const IslamicEducationHubScreen({super.key});

  @override
  ConsumerState<IslamicEducationHubScreen> createState() => _IslamicEducationHubScreenState();
}

class _IslamicEducationHubScreenState extends ConsumerState<IslamicEducationHubScreen> {
  EducationCategory? _selectedCategory;
  DifficultyLevel? _selectedDifficulty;
  bool _isLoading = false;
  List<IslamicEducationalContent> _featuredContent = [];
  List<IslamicEducationalContent> _allContent = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final featured = await IslamicEducationService.getFeaturedContent(limit: 6);
      final all = await IslamicEducationService.getEducationalContent(limit: 20);
      
      setState(() {
        _featuredContent = featured;
        _allContent = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load content: $e',
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
          'Islamic Education',
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _navigateToBookmarks(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _navigateToHistory(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 24),
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),
                  _buildFilterSection(),
                  const SizedBox(height: 24),
                  _buildFeaturedSection(),
                  const SizedBox(height: 24),
                  _buildQuickAccessSection(),
                  const SizedBox(height: 24),
                  _buildAllContentSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.menu_book,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Learn Islamic Marriage Principles',
            style: GoogleFonts.nunitoSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comprehensive guidance on Islamic marriage, Afghan traditions, and family values',
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      _CategoryItem(
        icon: Icons.favorite,
        title: 'Marriage Principles',
        subtitle: 'Core Islamic marriage teachings',
        category: EducationCategory.marriagePrinciples,
        color: Colors.pink,
      ),
      _CategoryItem(
        icon: Icons.book,
        title: 'Quranic Guidance',
        subtitle: 'Verses about marriage & family',
        category: EducationCategory.quranicGuidance,
        color: Colors.green,
      ),
      _CategoryItem(
        icon: Icons.mosque,
        title: 'Prophetic Teachings',
        subtitle: 'Sunnah of the Prophet',
        category: EducationCategory.propheticTeachings,
        color: Colors.blue,
      ),
      _CategoryItem(
        icon: Icons.diversity_3,
        title: 'Afghan Culture',
        subtitle: 'Wedding traditions & customs',
        category: EducationCategory.afghanCulture,
        color: Colors.orange,
      ),
      _CategoryItem(
        icon: Icons.family_restroom,
        title: 'Family Life',
        subtitle: 'Building strong families',
        category: EducationCategory.familyLife,
        color: Colors.purple,
      ),
      _CategoryItem(
        icon: Icons.chat,
        title: 'Communication',
        subtitle: 'Healthy relationships',
        category: EducationCategory.communication,
        color: Colors.teal,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: GoogleFonts.nunitoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(_CategoryItem category) {
    final isSelected = _selectedCategory == category.category;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : category.category;
        });
        _filterContent();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? category.color.withValues(alpha: 0.1) : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? category.color : AppColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                size: 32,
                color: category.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.title,
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? category.color : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              category.subtitle,
              style: GoogleFonts.nunitoSans(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Icon(
          Icons.filter_list,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Difficulty Level',
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Wrap(
          spacing: 8,
          children: DifficultyLevel.values.map((level) {
            final isSelected = _selectedDifficulty == level;
            return FilterChip(
              label: Text(
                _getDifficultyLabel(level),
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDifficulty = selected ? level : null;
                });
                _filterContent();
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    if (_featuredContent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Featured Content',
              style: GoogleFonts.nunitoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _featuredContent.length,
            itemBuilder: (context, index) {
              final content = _featuredContent[index];
              return _buildFeaturedContentCard(content);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedContentCard(IslamicEducationalContent content) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _navigateToContent(content),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    _getCategoryLabel(content.category),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    content.title,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content.description,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${content.estimatedReadTime} min',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (content.quiz != null)
                      Icon(
                        Icons.quiz,
                        size: 14,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
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
            'Quick Access',
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAccessButton(
                  icon: Icons.quiz,
                  label: 'Take Quiz',
                  onTap: () => _navigateToQuizHub(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAccessButton(
                  icon: Icons.diversity_3,
                  label: 'Afghan Traditions',
                  onTap: () => _navigateToAfghanTraditions(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllContentSection() {
    final filteredContent = _getFilteredContent();
    
    if (filteredContent.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No content found',
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Content',
          style: GoogleFonts.nunitoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...filteredContent.map((content) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ContentListItem(
              content: content,
              onTap: () => _navigateToContent(content),
            ),
          );
        }).toList(),
      ],
    );
  }

  List<IslamicEducationalContent> _getFilteredContent() {
    return _allContent.where((content) {
      if (_selectedCategory != null && content.category != _selectedCategory) {
        return false;
      }
      if (_selectedDifficulty != null && content.difficultyLevel != _selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _filterContent() async {
    // Load filtered content based on selected filters
    setState(() {
      _isLoading = true;
    });

    try {
      final filtered = await IslamicEducationService.getEducationalContent(
        category: _selectedCategory,
        difficultyLevel: _selectedDifficulty,
        limit: 20,
      );
      
      setState(() {
        _allContent = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToContent(IslamicEducationalContent content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IslamicEducationContentScreen(content: content),
      ),
    );
  }

  void _navigateToQuizHub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IslamicEducationQuizHubScreen(),
      ),
    );
  }

  void _navigateToAfghanTraditions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AfghanTraditionsScreen(),
      ),
    );
  }

  void _navigateToBookmarks() {
    // Navigate to bookmarks screen
  }

  void _navigateToHistory() {
    // Navigate to history screen
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

class _CategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final EducationCategory category;
  final Color color;

  const _CategoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.color,
  });
}

class _ContentListItem extends StatelessWidget {
  final IslamicEducationalContent content;
  final VoidCallback onTap;

  const _ContentListItem({
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getCategoryLabel(content.category),
                            style: GoogleFonts.nunitoSans(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getDifficultyLabel(content.difficultyLevel),
                            style: GoogleFonts.nunitoSans(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                      content.description,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${content.estimatedReadTime}m',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (content.quiz != null) ...[
                    const SizedBox(height: 8),
                    Icon(
                      Icons.quiz,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(EducationCategory category) {
    switch (category) {
      case EducationCategory.marriagePrinciples:
        return 'Marriage';
      case EducationCategory.quranicGuidance:
        return 'Quran';
      case EducationCategory.propheticTeachings:
        return 'Sunnah';
      case EducationCategory.afghanCulture:
        return 'Afghan';
      case EducationCategory.familyLife:
        return 'Family';
      case EducationCategory.communication:
        return 'Communication';
      case EducationCategory.conflictResolution:
        return 'Conflict';
      case EducationCategory.financialManagement:
        return 'Finance';
      case EducationCategory.parenting:
        return 'Parenting';
      case EducationCategory.general:
        return 'General';
    }
  }

  String _getDifficultyLabel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return 'Basic';
      case DifficultyLevel.intermediate:
        return 'Medium';
      case DifficultyLevel.advanced:
        return 'Advanced';
    }
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
