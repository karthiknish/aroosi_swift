import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../utils/debug_logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth methods
  fb.User? get currentUser => _auth.currentUser;

  Future<fb.UserCredential> signInWithApple({String? idToken, String? accessToken}) async {
    final credential = fb.OAuthProvider('apple.com').credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<fb.UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<fb.UserCredential> createEmailPasswordUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Update display name
    await userCredential.user?.updateDisplayName(name);
    
    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    await currentUser?.delete();
  }

  // Firestore methods
  DocumentReference get userProfileRef => 
      _firestore.collection('users').doc(currentUser?.uid);

  CollectionReference get usersRef => _firestore.collection('users');

  CollectionReference get profilesRef => _firestore.collection('profiles');

  CollectionReference get conversationsRef => _firestore.collection('conversations');

  CollectionReference get matchesRef => _firestore.collection('matches');

  CollectionReference get interestsRef => _firestore.collection('interests');

  CollectionReference get reportsRef => _firestore.collection('reports');

  CollectionReference get blocksRef => _firestore.collection('blocks');

  // Profile methods
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final doc = await userProfileRef.get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      logDebug('Error getting current user profile', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final doc = await usersRef.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      logDebug('Error getting profile by ID', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> createProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      profileData['userId'] = userId;
      profileData['createdAt'] = FieldValue.serverTimestamp();
      profileData['updatedAt'] = FieldValue.serverTimestamp();
      
      await usersRef.doc(userId).set(profileData);
      return profileData;
    } catch (e) {
      logDebug('Error creating profile', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await usersRef.doc(userId).update(updates);
      
      // Return updated profile
      return await getProfileById(userId);
    } catch (e) {
      logDebug('Error updating profile', error: e);
      rethrow;
    }
  }

  // Search and matching methods
  Future<List<Map<String, dynamic>>> searchProfiles({
    Map<String, dynamic>? filters,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = usersRef.limit(limit);
      
      if (filters != null) {
        // Apply filters based on available data
        if (filters['minAge'] != null) {
          query = query.where('age', isGreaterThanOrEqualTo: filters['minAge']);
        }
        if (filters['maxAge'] != null) {
          query = query.where('age', isLessThanOrEqualTo: filters['maxAge']);
        }
        if (filters['gender'] != null) {
          query = query.where('gender', isEqualTo: filters['gender']);
        }
        if (filters['location'] != null) {
          // Geopoint filtering would need additional implementation
        }
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      logDebug('Error searching profiles', error: e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMatches({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      Query query = matchesRef
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'matched')
          .orderBy('matchedAt', descending: true)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      logDebug('Error getting matches', error: e);
      return [];
    }
  }

  // Interest methods
  Future<void> sendInterest(String toUserId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      await interestsRef.add({
        'fromUserId': userId,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logDebug('Error sending interest', error: e);
      rethrow;
    }
  }

  Future<void> respondToInterest(String interestId, String status) async {
    try {
      await interestsRef.doc(interestId).update({
        'status': status,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logDebug('Error responding to interest', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getInterests({
    required String mode, // 'sent', 'received', 'mutual'
    int limit = 20,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      Query query;
      switch (mode) {
        case 'sent':
          query = interestsRef
              .where('fromUserId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(limit);
          break;
        case 'received':
          query = interestsRef
              .where('toUserId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(limit);
          break;
        case 'mutual':
          query = interestsRef
              .where('status', isEqualTo: 'accepted')
              .orderBy('createdAt', descending: true)
              .limit(limit);
          break;
        default:
          return [];
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      logDebug('Error getting interests', error: e);
      return [];
    }
  }

  // Shortlist methods
  Future<void> addToShortlist(String userId) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');
      
      await usersRef.doc(currentUserId).collection('shortlist').doc(userId).set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logDebug('Error adding to shortlist', error: e);
      rethrow;
    }
  }

  Future<void> removeFromShortlist(String userId) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');
      
      await usersRef.doc(currentUserId).collection('shortlist').doc(userId).delete();
    } catch (e) {
      logDebug('Error removing from shortlist', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getShortlist({int limit = 20}) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await usersRef
          .doc(userId)
          .collection('shortlist')
          .orderBy('addedAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      logDebug('Error getting shortlist', error: e);
      return [];
    }
  }

  // Safety methods
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      await reportsRef.add({
        'reporterId': userId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      logDebug('Error reporting user', error: e);
      rethrow;
    }
  }

  Future<void> blockUser(String blockedUserId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      await blocksRef.add({
        'blockerId': userId,
        'blockedUserId': blockedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logDebug('Error blocking user', error: e);
      rethrow;
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await blocksRef
          .where('blockerId', isEqualTo: userId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      logDebug('Error unblocking user', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await blocksRef
          .where('blockerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      logDebug('Error getting blocked users', error: e);
      return [];
    }
  }

  // Chat methods
  Future<String> createConversation(List<String> participantIds) async {
    try {
      final doc = await conversationsRef.add({
        'participants': participantIds,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {},
      });
      return doc.id;
    } catch (e) {
      logDebug('Error creating conversation', error: e);
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String fromUserId,
    String? toUserId,
    String type = 'text',
  }) async {
    try {
      final messageRef = conversationsRef
          .doc(conversationId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'id': messageRef.id,
        'conversationId': conversationId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'text': text,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      // Update conversation metadata
      await conversationsRef.doc(conversationId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'lastMessageFrom': fromUserId,
      });
    } catch (e) {
      logDebug('Error sending message', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = conversationsRef
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      logDebug('Error getting messages', error: e);
      return [];
    }
  }

  // Storage methods
  Future<String> uploadProfileImage(XFile file, String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await ref.putFile(File(file.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      logDebug('Error uploading profile image', error: e);
      rethrow;
    }
  }

  Future<String> uploadVoiceMessage(String conversationId, List<int> bytes) async {
    try {
      final ref = _storage.ref().child('voice_messages/$conversationId/${DateTime.now().millisecondsSinceEpoch}.m4a');
      final uploadTask = await ref.putData(Uint8List.fromList(bytes));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      logDebug('Error uploading voice message', error: e);
      rethrow;
    }
  }

  Future<String> uploadChatImage(String conversationId, XFile file) async {
    try {
      final ref = _storage.ref().child('chat_images/$conversationId/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await ref.putFile(File(file.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      logDebug('Error uploading chat image', error: e);
      rethrow;
    }
  }

  // Utility methods
  Future<bool> isEmailVerified() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      // Reload user to get latest email verification status
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      logDebug('Error checking email verification', error: e);
      return false;
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      logDebug('Error resending email verification', error: e);
      rethrow;
    }
  }
}
