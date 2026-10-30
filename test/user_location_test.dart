import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/map/domain/entities/user_location.dart';

void main() {
  group('UserLocation', () {
    test('fallback factory produces valid default coordinates in Bankal', () {
      final loc = UserLocation.fallback();
      expect(loc.latitude, equals(10.3140));
      expect(loc.longitude, equals(123.9720));
      expect(loc.heading, equals(0.0));
      expect(loc.accuracy, equals(5.0));
    });

    test('copyWith updates specified fields and retains others', () {
      final initial = UserLocation(
        latitude: 10.3140,
        longitude: 123.9720,
        heading: 45.0,
        accuracy: 4.0,
        speed: 1.2,
        altitude: 15.0,
        timestamp: DateTime(2026, 10, 30, 12, 0, 0),
      );

      final updated = initial.copyWith(latitude: 10.3200, heading: 90.0);

      expect(updated.latitude, equals(10.3200));
      expect(updated.longitude, equals(123.9720));
      expect(updated.heading, equals(90.0));
      expect(updated.accuracy, equals(4.0));
      expect(updated.speed, equals(1.2));
      expect(updated.altitude, equals(15.0));
    });

    test('value equality evaluates equivalent instances', () {
      final now = DateTime(2026, 10, 30, 12, 0, 0);
      final loc1 = UserLocation(
        latitude: 10.3140,
        longitude: 123.9720,
        heading: 180.0,
        accuracy: 3.0,
        speed: 0.5,
        altitude: 10.0,
        timestamp: now,
      );
      final loc2 = UserLocation(
        latitude: 10.3140,
        longitude: 123.9720,
        heading: 180.0,
        accuracy: 3.0,
        speed: 0.5,
        altitude: 10.0,
        timestamp: now,
      );

      expect(loc1, equals(loc2));
      expect(loc1.hashCode, equals(loc2.hashCode));
    });
  });
}
