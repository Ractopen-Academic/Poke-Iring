import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;

  AuthRepositoryImpl({FirebaseAuthDatasource? datasource})
    : _datasource = datasource ?? FirebaseAuthDatasource();

  @override
  Stream<AuthUser?> get authStateChanges => _datasource.authStateChanges;

  @override
  AuthUser? get currentUser => _datasource.currentUser;

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) {
    return _datasource.signInWithEmailPassword(email, password);
  }

  @override
  Future<AuthUser> registerWithEmailPassword(String email, String password) {
    return _datasource.registerWithEmailPassword(email, password);
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    return _datasource.signInWithGoogle();
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _datasource.sendPasswordReset(email);
  }

  @override
  Future<void> signOut() {
    return _datasource.signOut();
  }
}
