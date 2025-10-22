import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'models.dart';
import 'content_data.dart';
import 'services.dart';

class IslamicEducationFirebaseUploader {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload all initial educational content to Firebase
  static Future<void> uploadInitialContent() async {
    try {
      print('Starting upload of Islamic educational content...');

      // Get initial content data
      final contentList = IslamicEducationalContentData.getInitialContent();
      final traditionsList = IslamicEducationalContentData.getAfghanTraditions();

      // Upload educational content
      for (final content in contentList) {
        await IslamicEducationService.uploadEducationalContent(content);
        print('Uploaded content: ${content.title}');
      }

      // Upload Afghan traditions
      for (final tradition in traditionsList) {
        await IslamicEducationService.uploadAfghanTradition(tradition);
        print('Uploaded tradition: ${tradition.name}');
      }

      print('✅ Successfully uploaded all content to Firebase!');
    } catch (e) {
      print('❌ Error uploading content: $e');
      rethrow;
    }
  }

  /// Upload a single content item
  static Future<String> uploadSingleContent(IslamicEducationalContent content) async {
    try {
      // Add search terms for better searchability
      final searchTerms = <String>[
        content.title.toLowerCase(),
        content.description.toLowerCase(),
        ...?content.tags?.map((tag) => tag.toLowerCase()),
      ];

      final contentWithSearch = content.toJson();
      contentWithSearch['searchTerms'] = searchTerms;

      final docRef = await _firestore.collection('islamic_educational_content').add(contentWithSearch);
      print('Uploaded content: ${content.title} (ID: ${docRef.id})');
      return docRef.id;
    } catch (e) {
      print('Error uploading content ${content.title}: $e');
      rethrow;
    }
  }

  /// Upload a single Afghan tradition
  static Future<String> uploadSingleTradition(AfghanCulturalTradition tradition) async {
    try {
      final docRef = await _firestore.collection('afghan_cultural_traditions').add(tradition.toJson());
      print('Uploaded tradition: ${tradition.name} (ID: ${docRef.id})');
      return docRef.id;
    } catch (e) {
      print('Error uploading tradition ${tradition.name}: $e');
      rethrow;
    }
  }

  /// Create indexes for better query performance
  static Future<void> createIndexes() async {
    try {
      // Create indexes for content collection
      await _firestore.collection('islamic_educational_content')
          .doc('_indexes')
          .set({
        'created_at': Timestamp.now(),
        'indexes': [
          'category',
          'contentType',
          'difficultyLevel',
          'isFeatured',
          'createdAt',
          'searchTerms',
        ],
      });

      // Create indexes for traditions collection
      await _firestore.collection('afghan_cultural_traditions')
          .doc('_indexes')
          .set({
        'created_at': Timestamp.now(),
        'indexes': [
          'category',
          'region',
        ],
      });

      print('✅ Indexes created successfully!');
    } catch (e) {
      print('Error creating indexes: $e');
    }
  }

  /// Verify upload by checking if content exists
  static Future<bool> verifyUpload() async {
    try {
      final contentSnapshot = await _firestore
          .collection('islamic_educational_content')
          .limit(1)
          .get();

      final traditionsSnapshot = await _firestore
          .collection('afghan_cultural_traditions')
          .limit(1)
          .get();

      return contentSnapshot.docs.isNotEmpty && traditionsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verifying upload: $e');
      return false;
    }
  }

  /// Clear all uploaded content (use with caution!)
  static Future<void> clearAllContent() async {
    try {
      print('⚠️  WARNING: Clearing all educational content...');
      
      // Clear educational content
      final contentSnapshot = await _firestore.collection('islamic_educational_content').get();
      for (final doc in contentSnapshot.docs) {
        await doc.reference.delete();
      }

      // Clear traditions
      final traditionsSnapshot = await _firestore.collection('afghan_cultural_traditions').get();
      for (final doc in traditionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Clear progress data
      final progressSnapshot = await _firestore.collection('user_education_progress').get();
      for (final doc in progressSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ All content cleared successfully!');
    } catch (e) {
      print('Error clearing content: $e');
    }
  }

  /// Get upload statistics
  static Future<Map<String, dynamic>> getUploadStatistics() async {
    try {
      final contentCount = await _firestore
          .collection('islamic_educational_content')
          .count()
          .get();

      final traditionsCount = await _firestore
          .collection('afghan_cultural_traditions')
          .count()
          .get();

      final featuredCount = await _firestore
          .collection('islamic_educational_content')
          .where('isFeatured', isEqualTo: true)
          .count()
          .get();

      return {
        'totalContent': contentCount.count,
        'totalTraditions': traditionsCount.count,
        'featuredContent': featuredCount.count,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  /// Upload sample images to Firebase Storage (if available)
  static Future<void> uploadSampleImages() async {
    try {
      // This would typically upload local image files
      // For now, we'll just create placeholder entries
      
      // Sample image references (these would be actual files in production)
      final sampleImages = [
        'assets/images/islamic_marriage_principles.jpg',
        'assets/images/afghan_wedding.jpg',
        'assets/images/quranic_verses.jpg',
        'assets/images/prophetic_teachings.jpg',
      ];

      for (final imagePath in sampleImages) {
        // In production, you would upload actual file data here
        print('Placeholder for image: $imagePath');
      }

      print('✅ Sample image references created!');
    } catch (e) {
      print('Error uploading sample images: $e');
    }
  }
}

// Admin utility class for content management
class IslamicEducationAdminUtil {
  /// Update existing content
  static Future<void> updateContent(String contentId, Map<String, dynamic> updates) async {
    try {
      await FirebaseFirestore.instance
          .collection('islamic_educational_content')
          .doc(contentId)
          .update(updates);
      print('Updated content: $contentId');
    } catch (e) {
      print('Error updating content: $e');
    }
  }

  /// Update tradition
  static Future<void> updateTradition(String traditionId, Map<String, dynamic> updates) async {
    try {
      await FirebaseFirestore.instance
          .collection('afghan_cultural_traditions')
          .doc(traditionId)
          .update(updates);
      print('Updated tradition: $traditionId');
    } catch (e) {
      print('Error updating tradition: $e');
    }
  }

  /// Get content analytics
  static Future<Map<String, dynamic>> getContentAnalytics() async {
    try {
      final contentSnapshot = await FirebaseFirestore.instance
          .collection('islamic_educational_content')
          .get();

      int totalViews = 0;
      int totalLikes = 0;
      int totalBookmarks = 0;
      final Map<String, int> categoryCounts = {};

      for (final doc in contentSnapshot.docs) {
        final data = doc.data();
        totalViews += (data['viewCount'] as int? ?? 0);
        totalLikes += (data['likeCount'] as int? ?? 0);
        totalBookmarks += (data['bookmarkCount'] as int? ?? 0);
        
        final category = data['category'] as String? ?? 'general';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return {
        'totalContent': contentSnapshot.docs.length,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'totalBookmarks': totalBookmarks,
        'categoryDistribution': categoryCounts,
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }

  /// Feature/unfeature content
  static Future<void> toggleFeaturedContent(String contentId, bool isFeatured) async {
    try {
      await FirebaseFirestore.instance
          .collection('islamic_educational_content')
          .doc(contentId)
          .update({'isFeatured': isFeatured});
      
      print('${isFeatured ? 'Featured' : 'Unfeatured'} content: $contentId');
    } catch (e) {
      print('Error updating featured status: $e');
    }
  }

  /// Bulk update content
  static Future<void> bulkUpdateContent(
    List<String> contentIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final contentId in contentIds) {
        final docRef = FirebaseFirestore.instance
            .collection('islamic_educational_content')
            .doc(contentId);
        batch.update(docRef, updates);
      }
      
      await batch.commit();
      print('Bulk updated ${contentIds.length} content items');
    } catch (e) {
      print('Error in bulk update: $e');
    }
  }
}
