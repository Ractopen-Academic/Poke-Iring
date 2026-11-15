class AppVersion {
  AppVersion._();

  // Major remains locked at 0 during pre-release until full functional stability
  static const int major = 0;
  static const int feature = 33;
  static const int patch = 0;
  static const String flag = 'f'; // f = feature, b = bugfix, r = refactor
  static const int iteration = 42;
  static const String stage = 'Pre-Alpha';
  static const String buildDate = '2026.11.13';

  /// Direct download URL for the latest compiled Dev APK from GitHub Actions Releases.
  static const String devApkDownloadUrl =
      'https://github.com/Ractopen-Academic/Poke-Iring/releases/download/dev-latest/pokeiring-dev.apk';

  /// GitHub Release page for the latest development build.
  static const String devReleasePageUrl =
      'https://github.com/Ractopen-Academic/Poke-Iring/releases/tag/dev-latest';

  static String get semanticVersion => '$major.$feature.$patch';
  static String get releaseTag => 'v$semanticVersion-$flag$iteration';
  static String get badgeDisplay => '$releaseTag ($stage)';
  static String get buildSubtitle =>
      'Build $buildDate • Calico Theme Cohesion & Live Deployment Ready';
}
