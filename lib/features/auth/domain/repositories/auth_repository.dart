import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser> signInWithEmailPassword(String email, String password);
  Future<AuthUser> registerWithEmailPassword(String email, String password);
  Future<AuthUser> signInWithGoogle();
  Future<void> sendEmailVerification();
  Future<void> reloadCurrentUser();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}
