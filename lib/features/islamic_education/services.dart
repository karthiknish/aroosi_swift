import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'models.dart';

class IslamicEducationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _contentCollection = 'islamic_educational_content';
  static const String _traditionsCollection = 'afghan_cultural_traditions';
  static const String _userProgressCollection = 'user_education_progress';

  // Content Management
  static Future<List<IslamicEducationalContent>> getEducationalContent({
    EducationCategory? category,
    EducationContentType? contentType,
    DifficultyLevel? difficultyLevel,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection(_contentCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (contentType != null) {
      query = query.where('contentType', isEqualTo: contentType.name);
    }
    if (difficultyLevel != null) {
      query = query.where('difficultyLevel', isEqualTo: difficultyLevel.name);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => IslamicEducationalContent.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<IslamicEducationalContent?> getContentById(String contentId) async {
    final doc = await _firestore.collection(_contentCollection).doc(contentId).get();
    if (doc.exists) {
      return IslamicEducationalContent.fromJson(doc.data()!);
    }
    return null;
  }

  static Future<List<IslamicEducationalContent>> getFeaturedContent({
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection(_contentCollection)
        .where('isFeatured', isEqualTo: true)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => IslamicEducationalContent.fromJson(doc.data()))
        .toList();
  }

  static Future<List<IslamicEducationalContent>> getRelatedContent(
    String contentId, {
    int limit = 5,
  }) async {
    final content = await getContentById(contentId);
    if (content?.relatedContent == null) return [];

    final relatedIds = content!.relatedContent!;
    final List<IslamicEducationalContent> relatedContent = [];

    for (final id in relatedIds.take(limit)) {
      final related = await getContentById(id);
      if (related != null) {
        relatedContent.add(related);
      }
    }

    return relatedContent;
  }

  static Future<List<IslamicEducationalContent>> searchContent(
    String query, {
    int limit = 20,
  }) async {
    // For now, basic search. In production, consider using Algolia or similar
    final snapshot = await _firestore
        .collection(_contentCollection)
        .where('searchTerms', arrayContains: query.toLowerCase())
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => IslamicEducationalContent.fromJson(doc.data()))
        .toList();
  }

  // Afghan Cultural Traditions
  static Future<List<AfghanCulturalTradition>> getAfghanCulturalTraditions({
    CulturalCategory? category,
    String? region,
    int limit = 20,
  }) async {
    Query query = _firestore.collection(_traditionsCollection).limit(limit);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (region != null) {
      query = query.where('region', isEqualTo: region);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AfghanCulturalTradition.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<AfghanCulturalTradition?> getTraditionById(String traditionId) async {
    final doc = await _firestore.collection(_traditionsCollection).doc(traditionId).get();
    if (doc.exists) {
      return AfghanCulturalTradition.fromJson(doc.data()!);
    }
    return null;
  }

  // User Progress Tracking
  static Future<void> trackContentProgress({
    required String userId,
    required String contentId,
    required double progress, // 0.0 to 1.0
    bool isCompleted = false,
  }) async {
    final progressData = {
      'userId': userId,
      'contentId': contentId,
      'progress': progress,
      'isCompleted': isCompleted,
      'lastAccessedAt': FieldValue.serverTimestamp(),
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
    };

    await _firestore
        .collection(_userProgressCollection)
        .doc('${userId}_$contentId')
        .set(progressData, SetOptions(merge: true));

    // Update content view count if this is the first access
    if (progress == 0.0) {
      await _incrementContentView(contentId);
    }
  }

  static Future<Map<String, dynamic>?> getUserProgress(
    String userId,
    String contentId,
  ) async {
    final doc = await _firestore
        .collection(_userProgressCollection)
        .doc('${userId}_$contentId')
        .get();
    return doc.data();
  }

  static Future<List<IslamicEducationalContent>> getUserCompletedContent(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection(_userProgressCollection)
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    final List<IslamicEducationalContent> completedContent = [];
    
    for (final doc in snapshot.docs) {
      final contentId = doc.data()['contentId'] as String;
      final content = await getContentById(contentId);
      if (content != null) {
        completedContent.add(content);
      }
    }

    return completedContent;
  }

  static Future<List<IslamicEducationalContent>> getRecommendedContent(
    String userId, {
    int limit = 10,
  }) async {
    // Get user's completed content to analyze preferences
    final completedContent = await getUserCompletedContent(userId, limit: 20);
    
    if (completedContent.isEmpty) {
      // If no history, return featured content
      return getFeaturedContent(limit: limit);
    }

    // Analyze user's preferred categories and difficulty levels
    final categoryCount = <EducationCategory, int>{};
    final difficultyCount = <DifficultyLevel, int>{};

    for (final content in completedContent) {
      categoryCount[content.category] = (categoryCount[content.category] ?? 0) + 1;
      difficultyCount[content.difficultyLevel] = 
          (difficultyCount[content.difficultyLevel] ?? 0) + 1;
    }

    // Find user's most preferred category and difficulty
    final preferredCategory = categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final preferredDifficulty = difficultyCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Get recommendations based on preferences
    return getEducationalContent(
      category: preferredCategory,
      difficultyLevel: preferredDifficulty,
      limit: limit,
    );
  }

  // Quiz Results
  static Future<void> saveQuizResults({
    required String userId,
    required String contentId,
    required String quizId,
    required List<String> answers,
    required double score,
    required bool passed,
    required int timeSpent, // in seconds
  }) async {
    final results = {
      'userId': userId,
      'contentId': contentId,
      'quizId': quizId,
      'answers': answers,
      'score': score,
      'passed': passed,
      'timeSpent': timeSpent,
      'completedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('quiz_results')
        .add(results);

    // If passed, mark content as completed
    if (passed) {
      await trackContentProgress(
        userId: userId,
        contentId: contentId,
        progress: 1.0,
        isCompleted: true,
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getUserQuizResults(
    String userId, {
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection('quiz_results')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Content Interaction
  static Future<void> likeContent(String contentId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(_contentCollection).doc(contentId);
      final doc = await transaction.get(docRef);
      
      if (doc.exists) {
        final currentLikes = doc.data()?['likeCount'] as int? ?? 0;
        transaction.update(docRef, {'likeCount': currentLikes + 1});
        
        // Track user like
        await _firestore.collection('content_likes').add({
          'contentId': contentId,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static Future<void> bookmarkContent(String contentId, String userId) async {
    await _firestore.collection('user_bookmarks').add({
      'contentId': contentId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(_contentCollection).doc(contentId);
      final doc = await transaction.get(docRef);
      
      if (doc.exists) {
        final currentBookmarks = doc.data()?['bookmarkCount'] as int? ?? 0;
        transaction.update(docRef, {'bookmarkCount': currentBookmarks + 1});
      }
    });
  }

  static Future<List<IslamicEducationalContent>> getUserBookmarks(
    String userId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('user_bookmarks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final List<IslamicEducationalContent> bookmarkedContent = [];
    
    for (final doc in snapshot.docs) {
      final contentId = doc.data()['contentId'] as String;
      final content = await getContentById(contentId);
      if (content != null) {
        bookmarkedContent.add(content);
      }
    }

    return bookmarkedContent;
  }

  // Analytics
  static Future<Map<String, dynamic>> getContentAnalytics(String contentId) async {
    final doc = await _firestore.collection(_contentCollection).doc(contentId).get();
    if (!doc.exists) return {};

    final data = doc.data()!;
    final progressSnapshot = await _firestore
        .collection(_userProgressCollection)
        .where('contentId', isEqualTo: contentId)
        .get();

    final completedCount = progressSnapshot.docs
        .where((doc) => doc.data()['isCompleted'] == true)
        .length;

    final averageProgress = progressSnapshot.docs.isEmpty
        ? 0.0
        : progressSnapshot.docs
                .map((doc) => doc.data()['progress'] as double)
                .reduce((a, b) => a + b) /
            progressSnapshot.docs.length;

    return {
      'viewCount': data['viewCount'] ?? 0,
      'likeCount': data['likeCount'] ?? 0,
      'bookmarkCount': data['bookmarkCount'] ?? 0,
      'completedCount': completedCount,
      'averageProgress': averageProgress,
      'totalStarts': progressSnapshot.docs.length,
    };
  }

  // Helper methods
  static Future<void> _incrementContentView(String contentId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(_contentCollection).doc(contentId);
      final doc = await transaction.get(docRef);
      
      if (doc.exists) {
        final currentViews = doc.data()?['viewCount'] as int? ?? 0;
        transaction.update(docRef, {'viewCount': currentViews + 1});
      }
    });
  }

  // Content upload for admin
  static Future<String> uploadEducationalContent(
    IslamicEducationalContent content,
  ) async {
    // Add search terms for better searchability
    final searchTerms = <String>[
      content.title.toLowerCase(),
      content.description.toLowerCase(),
      ...?content.tags?.map((tag) => tag.toLowerCase()),
    ];

    final contentWithSearch = content.toJson();
    contentWithSearch['searchTerms'] = searchTerms;

    final docRef = await _firestore.collection(_contentCollection).add(contentWithSearch);
    return docRef.id;
  }

  static Future<String> uploadAfghanTradition(
    AfghanCulturalTradition tradition,
  ) async {
    final docRef = await _firestore.collection(_traditionsCollection).add(tradition.toJson());
    return docRef.id;
  }

  static Future<String> uploadImageToStorage(
    String filePath,
    String fileName,
  ) async {
    final ref = _storage.ref().child('educational_content/$fileName');
    final uploadTask = await ref.putFile(filePath as File);
    return await uploadTask.ref.getDownloadURL();
  }
}

// Note: Add File import at the top when using this in your actual project
// import 'dart:io';
