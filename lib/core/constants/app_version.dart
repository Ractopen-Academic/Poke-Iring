class AppVersion {
  AppVersion._();

  // Major remains locked at 0 during pre-release until full functional stability
  static const int major = 0;
  static const int feature = 17;
  static const int patch = 0;
  static const String flag = 'f'; // f = feature, b = bugfix, r = refactor
  static const int iteration = 23;
  static const String stage = 'Pre-Alpha';
  static const String buildDate = '2026.10.31';

  static String get semanticVersion => '$major.$feature.$patch';
  static String get releaseTag => 'v$semanticVersion-$flag$iteration';
  static String get badgeDisplay => '$releaseTag ($stage)';
  static String get buildSubtitle =>
      'Build $buildDate • Feline Club Subscription & RAW Photo Vault';
}
