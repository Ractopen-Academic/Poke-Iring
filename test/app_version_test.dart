import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_version.dart';

void main() {
  group('AppVersion', () {
    test('strictly enforces major version 0 during pre-release', () {
      expect(AppVersion.major, equals(0));
      expect(AppVersion.semanticVersion.startsWith('0.'), isTrue);
    });

    test('badgeDisplay and buildSubtitle format correctly', () {
      expect(AppVersion.badgeDisplay, contains(AppVersion.releaseTag));
      expect(AppVersion.badgeDisplay, contains('Pre-Alpha'));
      expect(AppVersion.buildSubtitle, contains(AppVersion.buildDate));
    });

    test('exposes separate APK targets for Android 13, 14, and 15+', () {
      expect(AppVersion.apkTargets.length, equals(3));
      expect(
        AppVersion.apkTargets.map((t) => t.id).toList(),
        equals(['android13', 'android14', 'android15up']),
      );
      expect(
        AppVersion.android13ApkDownloadUrl,
        endsWith('/pokeiring-android13.apk'),
      );
      expect(
        AppVersion.android14ApkDownloadUrl,
        endsWith('/pokeiring-android14.apk'),
      );
      expect(
        AppVersion.android15UpApkDownloadUrl,
        endsWith('/pokeiring-android15up.apk'),
      );
      expect(AppVersion.devApkDownloadUrl, endsWith('/pokeiring-dev.apk'));
    });
  });
}
