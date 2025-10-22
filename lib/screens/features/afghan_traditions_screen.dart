import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../features/islamic_education/models.dart';
import '../../features/islamic_education/services.dart';

class AfghanTraditionsScreen extends ConsumerStatefulWidget {
  const AfghanTraditionsScreen({super.key});

  @override
  ConsumerState<AfghanTraditionsScreen> createState() => _AfghanTraditionsScreenState();
}

class _AfghanTraditionsScreenState extends ConsumerState<AfghanTraditionsScreen> {
  bool _isLoading = false;
  CulturalCategory? _selectedCategory;
  List<AfghanCulturalTradition> _traditions = [];

  @override
  void initState() {
    super.initState();
    _loadTraditions();
  }

  Future<void> _loadTraditions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final traditions = await IslamicEducationService.getAfghanCulturalTraditions(
        category: _selectedCategory,
        limit: 50,
      );
      
      setState(() {
        _traditions = traditions;
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
              'Failed to load traditions: $e',
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
          'Afghan Cultural Traditions',
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(),
          
          // Traditions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _traditions.isEmpty
                    ? _buildEmptyState()
                    : _buildTraditionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(null, 'All'),
                const SizedBox(width: 8),
                ...CulturalCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(category, _getCategoryLabel(category)),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CulturalCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
        _loadTraditions();
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.orange,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diversity_3_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Traditions Found',
            style: GoogleFonts.nunitoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _traditions.length,
      itemBuilder: (context, index) {
        final tradition = _traditions[index];
        return _TraditionCard(tradition: tradition);
      },
    );
  }

  String _getCategoryLabel(CulturalCategory category) {
    switch (category) {
      case CulturalCategory.wedding:
        return 'Weddings';
      case CulturalCategory.engagement:
        return 'Engagements';
      case CulturalCategory.family:
        return 'Family';
      case CulturalCategory.social:
        return 'Social';
      case CulturalCategory.religious:
        return 'Religious';
      case CulturalCategory.seasonal:
        return 'Seasonal';
      case CulturalCategory.culinary:
        return 'Culinary';
      case CulturalCategory.artistic:
        return 'Artistic';
    }
  }
}

class _TraditionCard extends StatelessWidget {
  final AfghanCulturalTradition tradition;

  const _TraditionCard({
    super.key,
    required this.tradition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCategoryLabel(tradition.category),
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        color: Colors.orange,
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
                      tradition.region,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tradition.name,
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tradition.description,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Practices section
              if (tradition.practices.isNotEmpty) ...[
                Text(
                  'Key Practices:',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                ...tradition.practices.take(3).map((practice) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            practice,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (tradition.practices.length > 3)
                  Text(
                    '... and ${tradition.practices.length - 3} more',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              
              // Modern adaptation
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modern: ${tradition.modernAdaptation}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          color: Colors.blue[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(CulturalCategory category) {
    switch (category) {
      case CulturalCategory.wedding:
        return 'Wedding';
      case CulturalCategory.engagement:
        return 'Engagement';
      case CulturalCategory.family:
        return 'Family';
      case CulturalCategory.social:
        return 'Social';
      case CulturalCategory.religious:
        return 'Religious';
      case CulturalCategory.seasonal:
        return 'Seasonal';
      case CulturalCategory.culinary:
        return 'Culinary';
      case CulturalCategory.artistic:
        return 'Artistic';
    }
  }
}
