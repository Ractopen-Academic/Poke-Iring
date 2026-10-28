class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool emailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.emailVerified = false,
  });

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  static const empty = AuthUser(id: '', email: '');
}
