class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
  });

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  static const empty = AuthUser(id: '', email: '');
}
