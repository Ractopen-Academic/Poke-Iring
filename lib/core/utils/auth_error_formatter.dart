import 'package:firebase_auth/firebase_auth.dart';

/// Formats raw Firebase Authentication exceptions and error strings
/// into clear, user-friendly, and production-ready messages.
class AuthErrorFormatter {
  AuthErrorFormatter._();

  static String format(dynamic error) {
    if (error == null) return '';

    if (error is FirebaseAuthException) {
      return _formatFirebaseCode(error.code, error.message);
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();

    // Check if error message contains a Firebase code in brackets (e.g. [firebase_auth/invalid-credential])
    final codeMatch = RegExp(r'\[(?:firebase_auth/)?([a-zA-Z0-9_-]+)\]')
        .firstMatch(raw);
    if (codeMatch != null) {
      final code = codeMatch.group(1)!;
      return _formatFirebaseCode(code, raw);
    }

    final lower = raw.toLowerCase();

    if (lower.contains('passwords do not match')) {
      return 'Passwords do not match. Please ensure both fields are identical.';
    }
    if (lower.contains('invalid-credential') ||
        lower.contains('wrong-password') ||
        lower.contains('user-not-found') ||
        lower.contains('invalid password') ||
        lower.contains('no user corresponding')) {
      return 'Incorrect email or password. Please double-check your credentials or reset your password.';
    }
    if (lower.contains('email-already-in-use') ||
        lower.contains('already in use')) {
      return 'An account with this email address already exists. Please sign in instead.';
    }
    if (lower.contains('invalid-email') || lower.contains('badly formatted')) {
      return 'Please enter a valid email address (e.g., explorer@pokeiring.app).';
    }
    if (lower.contains('weak-password') ||
        lower.contains('password should be at least')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (lower.contains('too-many-requests') ||
        lower.contains('blocked all requests')) {
      return 'Too many failed login attempts. Please wait a moment before trying again.';
    }
    if (lower.contains('network') ||
        lower.contains('socketexception') ||
        lower.contains('timeout')) {
      return 'Unable to connect to game servers. Please check your network connection.';
    }
    if (lower.contains('user-disabled')) {
      return 'This explorer account has been disabled. Please contact support.';
    }
    if (lower.contains('popup-closed-by-user') ||
        lower.contains('sign_in_canceled') ||
        lower.contains('cancelled')) {
      return 'Sign-in was cancelled.';
    }

    // Default friendly production error fallback (strip any technical prefix or code)
    if (raw.isNotEmpty && !raw.contains('[') && raw.length < 90) {
      return raw;
    }

    return 'Unable to sign in. Please verify your details and try again.';
  }

  static String _formatFirebaseCode(String code, [String? fallbackMessage]) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password. Please double-check your credentials or reset your password.';
      case 'email-already-in-use':
        return 'An account with this email address already exists. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address (e.g., explorer@pokeiring.app).';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please wait a moment before trying again.';
      case 'network-request-failed':
        return 'Unable to connect to game servers. Please check your network connection.';
      case 'user-disabled':
        return 'This explorer account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled. Please contact support.';
      case 'popup-closed-by-user':
      case 'sign_in_canceled':
        return 'Sign-in was cancelled.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this sensitive action.';
      default:
        if (fallbackMessage != null &&
            fallbackMessage.isNotEmpty &&
            !fallbackMessage.contains('[')) {
          return fallbackMessage;
        }
        return 'Unable to complete sign-in. Please try again.';
    }
  }
}
