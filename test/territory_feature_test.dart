import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokeiring/features/territory/data/datasources/ph_territory_catalog.dart';
import 'package:pokeiring/features/territory/data/services/territory_service_impl.dart';
import 'package:pokeiring/features/territory/domain/entities/explorer_territory.dart';
import 'package:pokeiring/features/leaderboard/domain/entities/leaderboard_tier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PhTerritoryCatalog', () {
    test('contains key Philippine cities and barangays', () {
      expect(PhTerritoryCatalog.cities, isNotEmpty);
      final lapuLapu = PhTerritoryCatalog.cities.firstWhere(
        (c) => c.city == 'Lapu-Lapu City',
      );
      expect(lapuLapu.barangays, contains('Bankal'));
      expect(lapuLapu.barangays, contains('Mactan'));
    });

    test('resolves coordinates within Lapu-Lapu accurately', () {
      final resolved = PhTerritoryCatalog.resolveCoordinates(
        latitude: 10.3140,
        longitude: 123.9720,
      );
      expect(resolved.city, equals('Lapu-Lapu City'));
      expect(resolved.barangay, equals('Bankal'));
    });

    test('resolves coordinates within Cebu City accurately', () {
      final resolved = PhTerritoryCatalog.resolveCoordinates(
        latitude: 10.3300,
        longitude: 123.9050,
      );
      expect(resolved.city, equals('Cebu City'));
      expect(resolved.barangay, equals('Lahug'));
    });
  });

  group('TerritoryServiceImpl', () {
    test(
      'returns default territory when no stored preferences exist',
      () async {
        final service = TerritoryServiceImpl();
        final territory = await service.getTerritory('user_123');
        expect(
          territory.barangay,
          equals(ExplorerTerritory.defaultTerritory.barangay),
        );
        expect(territory.city, equals(ExplorerTerritory.defaultTerritory.city));
      },
    );

    test('persists and broadcasts updated territory', () async {
      final service = TerritoryServiceImpl();
      const newTerritory = ExplorerTerritory(
        barangay: 'Lahug',
        city: 'Cebu City',
        province: 'Cebu',
        country: 'Philippines',
        isHomeConfirmed: true,
      );

      final events = <ExplorerTerritory>[];
      final subscription = service
          .watchTerritory('user_456')
          .listen(events.add);

      await service.updateTerritory('user_456', newTerritory);

      final retrieved = await service.getTerritory('user_456');
      expect(retrieved.barangay, equals('Lahug'));
      expect(retrieved.city, equals('Cebu City'));
      expect(retrieved.isHomeConfirmed, isTrue);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.any((e) => e.barangay == 'Lahug'), isTrue);

      await subscription.cancel();
    });
  });

  group('LeaderboardTier Division Formats', () {
    test('maps all tiers to ordered competitive divisions', () {
      expect(LeaderboardTier.sleepyKitten.divisionLabel, equals('Division 1'));
      expect(LeaderboardTier.alleyProwler.divisionLabel, equals('Division 2'));
      expect(
        LeaderboardTier.whiskersTracker.divisionLabel,
        equals('Division 3'),
      );
      expect(LeaderboardTier.felineRanger.divisionLabel, equals('Division 4'));
      expect(
        LeaderboardTier.territoryAlpha.divisionLabel,
        equals('Division 5'),
      );
      expect(
        LeaderboardTier.mythicGuardian.divisionLabel,
        equals('Division 6'),
      );

      expect(
        LeaderboardTier.whiskersTracker.fullTitle,
        equals('Division 3 • Whiskers Tracker'),
      );
    });
  });
}
