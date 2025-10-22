import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:equatable/equatable.dart';

import 'package:aroosi_flutter/core/firebase_service.dart';

/// Result from Apple Sign In operation
class AppleSignInResult extends Equatable {
  final bool isEmailHidden;
  final String? email;
  final String? givenName;
  final String? familyName;

  const AppleSignInResult({
    required this.isEmailHidden,
    this.email,
    this.givenName,
    this.familyName,
  });

  @override
  List<Object?> get props => [isEmailHidden, email, givenName, familyName];
}

class AuthRepository {
  final FirebaseService _firebase = FirebaseService();

  // Helper no longer needed; keep repository minimal.

  // Removed legacy multi-method exchange helper; bearer-token auth is used now.


  /// Sign in with Apple using Firebase
  /// Supports Apple's "Hide My Email" feature where users can choose to hide their real email address.
  Future<AppleSignInResult> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Check if the credential has the required tokens
      if (credential.identityToken == null) {
        throw Exception('Apple Sign In failed: Missing identity token');
      }

      await _firebase.signInWithApple(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Determine if the email is hidden (proxy email from Apple)
      final isEmailHidden = _isProxyEmail(credential.email);

      return AppleSignInResult(
        isEmailHidden: isEmailHidden,
        email: credential.email,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle Apple Sign In specific errors
      String errorMessage = 'Apple Sign In failed';
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          errorMessage = 'Apple Sign In was canceled';
          break;
        case AuthorizationErrorCode.failed:
          errorMessage = 'Apple Sign In failed';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'Invalid response from Apple Sign In';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage = 'Apple Sign In not handled';
          break;
        case AuthorizationErrorCode.unknown:
          errorMessage = 'Unknown Apple Sign In error';
          break;
        case AuthorizationErrorCode.notInteractive:
          errorMessage = 'Apple Sign In not interactive';
          break;
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Handle other errors
      throw Exception('Apple Sign In failed: ${e.toString()}');
    }
  }

  /// Check if an email is a proxy email from Apple's "Hide My Email" feature
  bool _isProxyEmail(String? email) {
    if (email == null) return false;
    return email.endsWith('@privaterelay.appleid.com');
  }

  /// Request to share the real email address for a user who previously hid it
  /// This would typically involve calling Apple's API to request email sharing
  Future<bool> requestEmailSharing() async {
    try {
      final currentUser = _firebase.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Apple email sharing requires additional OAuth setup and server-side implementation
      // For production, this would involve:
      // 1. Server-side Apple API integration
      // 2. Proper OAuth token handling
      // 3. Privacy policy compliance

      // For now, return false indicating feature not available
      return false;
    } catch (e) {
      throw Exception('Failed to request email sharing: ${e.toString()}');
    }
  }

  /// Sign in with email/password via Firebase
  Future<void> signin({required String email, required String password}) async {
    try {
      await _firebase.signInWithEmailPassword(email: email, password: password);
    } on fb.FirebaseAuthException catch (e) {
      String msg = 'Sign in failed';
      if (e.code == 'user-not-found') msg = 'No account for this email';
      if (e.code == 'wrong-password') msg = 'Invalid password';
      if (e.code == 'too-many-requests') msg = 'Too many attempts. Try later';
      throw Exception(msg);
    }
  }

  /// Sign up and create a profile
  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _firebase.createEmailPasswordUser(
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Check current session; returns true if authenticated
  Future<bool> me() async {
    try {
      return _firebase.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Logout session
  Future<void> logout() async {
    try {
      await _firebase.signOut();
    } catch (_) {
      // ignore
    }
  }

  /// Fetch the current user's profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      return await _firebase.getCurrentUserProfile();
    } catch (e) {
      return null;
    }
  }

  /// Request forgot password email
  Future<void> requestPasswordReset(String email) async {
    try {
      await _firebase.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception('Failed to request password reset: ${e.toString()}');
    }
  }

  /// Reset password directly - Firebase handles this via email links
  Future<void> resetPassword(String email, String password) async {
    // Firebase password reset is handled via email links
    // This method would require custom implementation for direct password reset
    throw Exception('Password reset must be done via email link');
  }

  /// Resend the email verification link. Returns true if the request appears successful.
  Future<bool> resendEmailVerification() async {
    try {
      await _firebase.resendEmailVerification();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reload the user's email verification status
  /// Returns true if the user's email is verified.
  Future<bool> refreshEmailVerified() async {
    try {
      return await _firebase.isEmailVerified();
    } catch (_) {
      return false;
    }
  }

  /// Delete user account and all associated data
  Future<void> deleteAccount({required String password, String? reason}) async {
    try {
      // Note: Firebase Auth requires recent authentication for account deletion
      // Password re-authentication might be needed before deletion
      await _firebase.deleteAccount();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}
