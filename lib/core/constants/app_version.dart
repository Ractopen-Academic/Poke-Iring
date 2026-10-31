class AppVersion {
  AppVersion._();

  // Major remains locked at 0 during pre-release until full functional stability
  static const int major = 0;
  static const int feature = 25;
  static const int patch = 0;
  static const String flag = 'f'; // f = feature, b = bugfix, r = refactor
  static const int iteration = 31;
  static const String stage = 'Pre-Alpha';
  static const String buildDate = '2026.10.31';

  static String get semanticVersion => '$major.$feature.$patch';
  static String get releaseTag => 'v$semanticVersion-$flag$iteration';
  static String get badgeDisplay => '$releaseTag ($stage)';
  static String get buildSubtitle =>
      'Build $buildDate • Silhouette Sticker Pins & Multi-Factor Scoring Matrix';
}
