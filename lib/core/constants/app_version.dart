class AndroidApkTarget {
  final String id;
  final String label;
  final String apiBadge;
  final String subtitle;
  final String downloadUrl;

  const AndroidApkTarget({
    required this.id,
    required this.label,
    required this.apiBadge,
    required this.subtitle,
    required this.downloadUrl,
  });
}

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

  static const String androidTargetLabel = String.fromEnvironment(
    'ANDROID_TARGET_LABEL',
    defaultValue: 'universal',
  );

  static const String _devReleaseBaseUrl =
      'https://github.com/Ractopen-Academic/Poke-Iring/releases/download/dev-latest';

  /// Direct download URL for the universal fallback Dev APK (Android 13+).
  static const String devApkDownloadUrl =
      '$_devReleaseBaseUrl/pokeiring-dev.apk';

  /// Separate target-specific Dev APK download URLs from GitHub Actions Releases.
  static const String android13ApkDownloadUrl =
      '$_devReleaseBaseUrl/pokeiring-android13.apk';
  static const String android14ApkDownloadUrl =
      '$_devReleaseBaseUrl/pokeiring-android14.apk';
  static const String android15UpApkDownloadUrl =
      '$_devReleaseBaseUrl/pokeiring-android15up.apk';

  static const List<AndroidApkTarget> apkTargets = [
    AndroidApkTarget(
      id: 'android13',
      label: 'Android 13',
      apiBadge: 'API 33',
      subtitle: 'Android 13 (arm64-v8a)',
      downloadUrl: android13ApkDownloadUrl,
    ),
    AndroidApkTarget(
      id: 'android14',
      label: 'Android 14',
      apiBadge: 'API 34',
      subtitle: 'Android 14 (arm64-v8a)',
      downloadUrl: android14ApkDownloadUrl,
    ),
    AndroidApkTarget(
      id: 'android15up',
      label: 'Android 15+',
      apiBadge: 'API 35+',
      subtitle: 'Android 15 & 16+ (arm64-v8a)',
      downloadUrl: android15UpApkDownloadUrl,
    ),
  ];

  /// GitHub Release page for the latest development build.
  static const String devReleasePageUrl =
      'https://github.com/Ractopen-Academic/Poke-Iring/releases/tag/dev-latest';

  static String get semanticVersion => '$major.$feature.$patch';
  static String get releaseTag => 'v$semanticVersion-$flag$iteration';
  static String get badgeDisplay => '$releaseTag ($stage)';
  static String get buildSubtitle =>
      'Build $buildDate • Calico Theme Cohesion & Live Deployment Ready';
}
