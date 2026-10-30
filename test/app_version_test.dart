import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/core/constants/app_version.dart';

void main() {
  group('AppVersion', () {
    test('strictly enforces major version 0 during pre-release', () {
      expect(AppVersion.major, equals(0));
      expect(AppVersion.semanticVersion.startsWith('0.'), isTrue);
    });

    test('badgeDisplay and buildSubtitle format correctly', () {
      expect(AppVersion.badgeDisplay, contains('v0.7.0-f7'));
      expect(AppVersion.badgeDisplay, contains('Pre-Alpha'));
      expect(AppVersion.buildSubtitle, contains('2026.10.30'));
    });
  });
}
