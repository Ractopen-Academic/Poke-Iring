import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokeiring/features/seasons/data/services/season_service_impl.dart';
import 'package:pokeiring/features/seasons/domain/entities/season_period.dart';
import 'package:pokeiring/features/seasons/domain/entities/season_prestige_record.dart';
import 'package:pokeiring/features/seasons/presentation/widgets/season_details_sheet.dart';
import 'package:pokeiring/features/seasons/presentation/widgets/season_rollover_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SeasonPeriod Entity', () {
    test('calculates remaining time and formatted label correctly', () {
      final now = DateTime.now();
      final season = SeasonPeriod(
        id: 's_test',
        number: 1,
        title: 'Season 1: Test Strays',
        description: 'Test season',
        startsAt: now.subtract(const Duration(days: 5)),
        endsAt: now.add(const Duration(days: 10, hours: 3, minutes: 30)),
      );

      expect(season.isEnded, isFalse);
      expect(season.remainingDays, equals(10));
      expect(season.remainingHours, equals(3));
      expect(season.remainingFormatted, contains('10 days, 3h remaining'));
    });

    test('serializes toMap and fromMap cleanly', () {
      final season = SeasonPeriod.defaultSeason1();
      final map = season.toMap();
      final reconstructed = SeasonPeriod.fromMap(map);

      expect(reconstructed.id, equals(season.id));
      expect(reconstructed.number, equals(season.number));
      expect(reconstructed.title, equals(season.title));
    });
  });

  group('SeasonServiceImpl Logic', () {
    test('calculates soft reset starting placement floor correctly', () {
      final service = SeasonServiceImpl();

      // Mythic Guardian -> 1200 floor (Division 4)
      expect(service.calculatePlacementPoints(3500), equals(1200));

      // Territory Alpha -> 700 floor (Division 3)
      expect(service.calculatePlacementPoints(1800), equals(700));

      // Feline Ranger -> 350 floor (Division 2)
      expect(service.calculatePlacementPoints(950), equals(350));

      // Whiskers Tracker -> 150 floor (Division 2)
      expect(service.calculatePlacementPoints(450), equals(150));

      // Alley Prowler -> 50 floor (Division 1)
      expect(service.calculatePlacementPoints(150), equals(50));

      // Sleepy Kitten -> 0 floor (Division 1)
      expect(service.calculatePlacementPoints(40), equals(0));
    });

    test('calculates rollover prestige bonus and trophy crest', () {
      final service = SeasonServiceImpl();
      final season = SeasonPeriod.defaultSeason1();

      // Top 3 finisher -> Gold Mythic Paw + 1000 bonus
      final topRank = service.calculateRollover(
        userId: 'u_champion',
        season: season,
        currentPoints: 2400,
        currentRank: 2,
        divisionTitle: 'Division 5 • Territory Alpha',
      );
      expect(topRank.trophyCrest, equals(SeasonTrophyCrest.goldMythic));
      expect(topRank.prestigeEarned, equals(3400)); // 2400 + 1000

      // Rank 8 finisher -> Silver Mythic Paw + 500 bonus
      final midRank = service.calculateRollover(
        userId: 'u_veteran',
        season: season,
        currentPoints: 1200,
        currentRank: 8,
        divisionTitle: 'Division 4 • Feline Ranger',
      );
      expect(midRank.trophyCrest, equals(SeasonTrophyCrest.silverMythic));
      expect(midRank.prestigeEarned, equals(1700)); // 1200 + 500
    });

    test('completes rollover and persists history and prestige', () async {
      final service = SeasonServiceImpl();

      final record = await service.completeSeasonRollover(
        userId: 'test_user_99',
        currentPoints: 800,
        currentRank: 5,
        divisionTitle: 'Division 4 • Feline Ranger',
      );

      expect(record.finalPoints, equals(800));
      expect(record.prestigeEarned, equals(1300)); // 800 + 500 bonus

      final prestige = await service.getMythicPrestige('test_user_99');
      expect(prestige, equals(1300));

      final history = await service.getSeasonHistory('test_user_99');
      expect(history.length, equals(1));
      expect(history.first.seasonNumber, equals(1));
    });
  });

  group('Season Presentation Widgets', () {
    testWidgets('SeasonRolloverDialog renders final recap and prestige', (
      tester,
    ) async {
      final record = SeasonPrestigeRecord(
        seasonId: 'season_1',
        seasonNumber: 1,
        seasonTitle: 'Season 1: Sunshine Strays',
        finalPoints: 2150,
        finalRank: 2,
        finalDivision: 'Division 5 • Territory Alpha',
        prestigeEarned: 3150,
        trophyCrest: SeasonTrophyCrest.goldMythic,
        completedAt: DateTime(2026, 10, 31),
        startingPlacementDivision: 'Division 3: Whiskers Tracker',
        startingPlacementPoints: 700,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SeasonRolloverDialog(record: record)),
        ),
      );

      expect(find.text('Season 1: Sunshine Strays Concluded'), findsOneWidget);
      expect(find.text('+3150 pts'), findsOneWidget);
      expect(find.text('Gold Mythic Paw'), findsOneWidget);
      expect(find.text('Enter Next Season'), findsOneWidget);
    });

    testWidgets('SeasonDetailsSheet renders soft reset breakdown', (
      tester,
    ) async {
      final season = SeasonPeriod.defaultSeason1();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonDetailsSheet(
              season: season,
              userId: 'u_1',
              userPoints: 1200,
              userRank: 4,
              divisionTitle: 'Division 4 • Feline Ranger',
            ),
          ),
        ),
      );

      expect(find.text('Projected Season Rewards'), findsOneWidget);
      expect(find.text('How Seasonal Resets Work'), findsOneWidget);
      expect(find.text('Simulate Season Rollover Ceremony'), findsOneWidget);
    });
  });
}
