import 'dart:async';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class DevAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  DevAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthUser> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = AuthUser(
      id: 'dev_${email.hashCode.abs()}',
      email: email.trim(),
      displayName: email.split('@').first,
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    return signInWithEmailPassword(email, password);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 400));
    const user = AuthUser(
      id: 'dev_google_user',
      email: 'explorer@pokeiring.app',
      displayName: 'Explorer Dev',
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
