class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool emailVerified;
  final bool isAdmin;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.emailVerified = false,
    this.isAdmin = false,
  });

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
  bool get isAdminRole =>
      isAdmin ||
      email.toLowerCase().endsWith('@iring.ph') ||
      email.toLowerCase() == 'admin@pokeiring.app';

  static const empty = AuthUser(id: '', email: '');
}
