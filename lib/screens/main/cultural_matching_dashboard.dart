import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;


import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/widgets/safe_image_network.dart';
import 'package:aroosi_flutter/features/cultural/cultural_repository.dart';

class CulturalMatchingDashboard extends ConsumerStatefulWidget {
  const CulturalMatchingDashboard({super.key});

  @override
  ConsumerState<CulturalMatchingDashboard> createState() => _CulturalMatchingDashboardState();
}

class _CulturalMatchingDashboardState extends ConsumerState<CulturalMatchingDashboard> {
  bool _isLoading = false;
  List<CulturalMatch> _matches = [];
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final culturalRepository = CulturalRepository();
      
      // Load cultural recommendations using the API path that matches Next.js
      final recommendations = await culturalRepository.getCulturalRecommendations();
      
      // Load user's cultural profile
      final userProfile = await culturalRepository.getCulturalProfile();

      if (mounted) {
        setState(() {
          _matches = recommendations.map((rec) {
            // Calculate compatibility breakdown for each match
            final breakdown = _calculateCompatibilityBreakdown(rec);
            return CulturalMatch(
              userId: rec['userId'] ?? '',
              name: rec['fullName'] ?? 'Unknown',
              age: rec['age'] ?? 25,
              profileImage: rec['profileImageUrls']?.first ?? '',
              compatibilityScore: rec['compatibilityScore'],
              compatibilityBreakdown: breakdown,
              matchingFactors: List<String>.from(rec['matchingFactors'] ?? []),
              culturalHighlights: List<String>.from(rec['culturalHighlights'] ?? []),
            );
          }).toList();
          _userProfile = userProfile?.toJson();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Load cultural matching data error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cultural matching data'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<String, int> _calculateCompatibilityBreakdown(dynamic recommendation) {
    // This would normally come from the API, but we'll calculate it based on typical weights
    // Religion: 40%, Language: 20%, Values: 25%, Family: 15%
    final score = recommendation.compatibilityScore as int? ?? 0;
    
    return {
      'religion': ((score * 0.4).round()),
      'language': ((score * 0.2).round()),
      'values': ((score * 0.25).round()),
      'family': ((score * 0.15).round()),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cultural Matches',
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                  // User Profile Summary
                  if (_userProfile != null) _buildUserProfileSummary(),
                  const SizedBox(height: 24),

                  // Cultural Preferences
                  _buildCulturalPreferences(),

                  const SizedBox(height: 24),

                  // Matches Header
                  Row(
                    children: [
                      Text(
                        '${_matches.length} Cultural Matches',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/main/cultural-assessment'),
                        child: Text(
                          'Update Preferences',
                          style: GoogleFonts.nunitoSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Matches List
                  _matches.isEmpty ? _buildEmptyState() : _buildMatchesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserProfileSummary() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Cultural Profile',
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Religion: ${_userProfile!['religion'] ?? 'Not specified'}',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          Text(
            'Language: ${_userProfile!['motherTongue'] ?? 'Not specified'}',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          Text(
            'Family Values: ${_userProfile!['familyValues'] ?? 'Not specified'}',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulturalPreferences() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Cultural Matching Preferences',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_userProfile != null) ...[
            _buildPreferenceItem('Religion', _userProfile!['religion'] ?? 'Not specified'),
            _buildPreferenceItem('Mother Tongue', _userProfile!['motherTongue'] ?? 'Not specified'),
            _buildPreferenceItem('Family Values', _userProfile!['familyValues'] ?? 'Not specified'),
            _buildPreferenceItem('Marriage Views', _userProfile!['marriageViews'] ?? 'Not specified'),
          ] else ...[
            _buildPreferenceItem('Religious Alignment', 'Not set'),
            _buildPreferenceItem('Language Compatibility', 'Not set'),
            _buildPreferenceItem('Family Values', 'Not set'),
            _buildPreferenceItem('Traditional Values', 'Not set'),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunitoSans(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: value == 'High'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value == 'High' ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.diversity_3,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Cultural Matches Yet',
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your cultural assessment to find compatible matches',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/main/cultural-assessment'),
            icon: const Icon(Icons.edit),
            label: Text(
              'Complete Assessment',
              style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    return Column(
      children: _matches.map((match) => _buildMatchCard(match)).toList(),
    );
  }

  Widget _buildMatchCard(CulturalMatch match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SafeImageNetwork(
                  imageUrl: match.profileImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                  errorWidget: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.name,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        match.age.toString(),
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _CompatibilityScore(score: match.compatibilityScore),
              ],
            ),
            const SizedBox(height: 16),

            // Compatibility Breakdown
            Text(
              'Cultural Compatibility',
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCompatibilityBar('Religion (40%)', match.compatibilityBreakdown['religion'] ?? 0),
            _buildCompatibilityBar('Language (20%)', match.compatibilityBreakdown['language'] ?? 0),
            _buildCompatibilityBar('Values (25%)', match.compatibilityBreakdown['values'] ?? 0),
            _buildCompatibilityBar('Family (15%)', match.compatibilityBreakdown['family'] ?? 0),
            
            if (match.matchingFactors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: match.matchingFactors.take(3).map((factor) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      factor,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewCompatibilityDetails(match),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewProfile(match),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'View Profile',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityBar(String label, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.nunitoSans(fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$score%',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: AppColors.borderPrimary,
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 80 ? AppColors.success :
              score >= 60 ? AppColors.warning : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _viewCompatibilityDetails(CulturalMatch match) {
    // Use current user's ID and match's user ID for compatibility
    final currentUser = fb.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      context.go('/main/cultural-compatibility/${currentUser.uid}/${match.userId}');
    }
  }

  void _viewProfile(CulturalMatch match) {
    context.go('/details/${match.userId}');
  }
}

class _CompatibilityScore extends StatelessWidget {
  final int score;

  const _CompatibilityScore({required this.score});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (score >= 80) {
      color = AppColors.success;
      text = 'Excellent';
    } else if (score >= 60) {
      color = AppColors.warning;
      text = 'Good';
    } else {
      color = AppColors.error;
      text = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            text,
            style: GoogleFonts.nunitoSans(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class CulturalMatch {
  final String userId;
  final String name;
  final int age;
  final String profileImage;
  final int compatibilityScore;
  final Map<String, int> compatibilityBreakdown;
  final List<String> matchingFactors;
  final List<String> culturalHighlights;

  CulturalMatch({
    required this.userId,
    required this.name,
    required this.age,
    required this.profileImage,
    required this.compatibilityScore,
    required this.compatibilityBreakdown,
    this.matchingFactors = const [],
    this.culturalHighlights = const [],
  });

  factory CulturalMatch.fromJson(Map<String, dynamic> json) {
    return CulturalMatch(
      userId: json['userId'] ?? '',
      name: json['profile']?['fullName'] ?? json['name'] ?? 'Unknown',
      age: json['profile']?['age'] ?? 25,
      profileImage: json['profileImage'] ?? '',
      compatibilityScore: json['compatibilityScore'] ?? 0,
      compatibilityBreakdown: Map<String, int>.from(json['compatibilityBreakdown'] ?? {}),
      matchingFactors: List<String>.from(json['matchingFactors'] ?? []),
      culturalHighlights: List<String>.from(json['culturalHighlights'] ?? []),
    );
  }
}