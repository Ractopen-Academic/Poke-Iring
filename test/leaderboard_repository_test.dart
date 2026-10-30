import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:pokeiring/features/leaderboard/domain/entities/leaderboard_query.dart';
import 'package:pokeiring/features/leaderboard/domain/entities/leaderboard_tier.dart';

void main() {
  group('LeaderboardTier', () {
    test('fromPoints evaluates proper tiers', () {
      expect(
        LeaderboardTier.fromPoints(250),
        equals(LeaderboardTier.sleepyKitten),
      );
      expect(
        LeaderboardTier.fromPoints(600),
        equals(LeaderboardTier.alleyProwler),
      );
      expect(
        LeaderboardTier.fromPoints(2000),
        equals(LeaderboardTier.whiskersTracker),
      );
      expect(
        LeaderboardTier.fromPoints(4500),
        equals(LeaderboardTier.felineRanger),
      );
      expect(
        LeaderboardTier.fromPoints(8000),
        equals(LeaderboardTier.territoryAlpha),
      );
      expect(
        LeaderboardTier.fromPoints(15000),
        equals(LeaderboardTier.mythicGuardian),
      );
    });

    test('progress calculates fractional progress between thresholds', () {
      final tier = LeaderboardTier.alleyProwler; // 500 to 1500
      expect(tier.progress(500), equals(0.0));
      expect(tier.progress(1000), equals(0.5));
      expect(tier.progress(1500), equals(1.0));
    });

    test('pointsToNextTier returns difference to next threshold', () {
      final tier = LeaderboardTier.sleepyKitten;
      expect(tier.pointsToNextTier(300), equals(200));

      final maxTier = LeaderboardTier.mythicGuardian;
      expect(maxTier.pointsToNextTier(15000), equals(0));
    });
  });

  group('LeaderboardScope', () {
    test('pool capacities match tiered structure', () {
      expect(LeaderboardScope.barangay.poolCapacity, equals(50));
      expect(LeaderboardScope.city.poolCapacity, equals(150));
      expect(LeaderboardScope.region.poolCapacity, equals(300));
      expect(LeaderboardScope.national.poolCapacity, equals(300));
      expect(LeaderboardScope.global.poolCapacity, equals(500));
    });
  });

  group('LeaderboardRepositoryImpl', () {
    const repository = LeaderboardRepositoryImpl();

    test('filters entries strictly by barangay scope', () async {
      final entries = await repository.getLeaderboard(
        filter: const LeaderboardFilter(
          scope: LeaderboardScope.barangay,
          barangay: 'Bankal',
        ),
        currentUserId: 'test-user',
      );

      expect(entries.isNotEmpty, isTrue);
      for (final entry in entries) {
        expect(entry.barangay.toLowerCase(), equals('bankal'));
      }
    });

    test('filters entries strictly by region scope', () async {
      final entries = await repository.getLeaderboard(
        filter: const LeaderboardFilter(
          scope: LeaderboardScope.region,
          region: 'Central Visayas',
        ),
        currentUserId: 'test-user',
      );

      expect(entries.isNotEmpty, isTrue);
      for (final entry in entries) {
        expect(entry.region.toLowerCase(), equals('central visayas'));
      }
    });

    test(
      'sorts descending by catsSnapped when snaps category is selected',
      () async {
        final entries = await repository.getLeaderboard(
          filter: const LeaderboardFilter(
            category: LeaderboardCategory.snaps,
            scope: LeaderboardScope.city,
            city: 'Lapu-Lapu City',
          ),
          currentUserId: 'test-user',
        );

        for (int i = 0; i < entries.length - 1; i++) {
          expect(entries[i].catsSnapped >= entries[i + 1].catsSnapped, isTrue);
          expect(entries[i].rank, equals(i + 1));
        }
      },
    );

    test(
      'sorts descending by distanceKm when distance category is selected',
      () async {
        final entries = await repository.getLeaderboard(
          filter: const LeaderboardFilter(
            category: LeaderboardCategory.distance,
            scope: LeaderboardScope.global,
          ),
          currentUserId: 'test-user',
        );

        for (int i = 0; i < entries.length - 1; i++) {
          expect(entries[i].distanceKm >= entries[i + 1].distanceKm, isTrue);
        }
      },
    );

    test('getUserStanding returns accurate rank for current user', () async {
      final standing = await repository.getUserStanding(
        userId: 'test-user',
        filter: const LeaderboardFilter(
          scope: LeaderboardScope.barangay,
          barangay: 'Bankal',
        ),
      );

      expect(standing, isNotNull);
      expect(standing!.isCurrentUser, isTrue);
      expect(standing.rank > 0, isTrue);
    });

    test('pagination returns constrained sublist', () async {
      final entries = await repository.getLeaderboard(
        filter: const LeaderboardFilter(
          scope: LeaderboardScope.global,
          limit: 3,
          offset: 0,
        ),
        currentUserId: 'test-user',
      );

      expect(entries.length, equals(3));
      expect(entries.first.rank, equals(1));
    });
  });
}
