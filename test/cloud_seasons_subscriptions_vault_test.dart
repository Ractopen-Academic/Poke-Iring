import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/seasons/data/datasources/firebase_seasons_datasource.dart';
import 'package:pokeiring/features/seasons/data/services/season_service_impl.dart';
import 'package:pokeiring/features/seasons/domain/entities/season_period.dart';
import 'package:pokeiring/features/seasons/domain/entities/season_prestige_record.dart';
import 'package:pokeiring/features/subscription/data/services/subscription_service_impl.dart';
import 'package:pokeiring/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pokeiring/features/vault/data/services/photo_vault_service_impl.dart';
import 'package:pokeiring/features/vault/domain/entities/vault_photo_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FirebaseSeasonsDataSource.instance.resetCache();
    SeasonServiceImpl.instance.resetLocalCache();
    SubscriptionServiceImpl.instance.resetCache();
    PhotoVaultServiceImpl.instance.resetCache();
  });

  group('FirebaseSeasonsDataSource Cloud & Cache Operations', () {
    test(
      'getActiveSeason returns initial default Season 1 when offline',
      () async {
        final dataSource = FirebaseSeasonsDataSource.instance;
        final season = await dataSource.getActiveSeason();

        expect(season.id, equals('season_1'));
        expect(season.number, equals(1));
        expect(season.status, equals(SeasonStatus.active));
        expect(season.title, contains('Season 1'));
      },
    );

    test('updateActiveSeason updates cache and notifies listeners', () async {
      final dataSource = FirebaseSeasonsDataSource.instance;
      final now = DateTime.now();
      final customSeason = SeasonPeriod(
        id: 'season_99',
        number: 99,
        title: 'Season 99: Cloud Whispers',
        description: 'Test season description',
        startsAt: now,
        endsAt: now.add(const Duration(days: 30)),
        status: SeasonStatus.active,
      );

      await dataSource.updateActiveSeason(customSeason);
      final active = await dataSource.getActiveSeason();

      expect(active.id, equals('season_99'));
      expect(active.number, equals(99));
      expect(active.title, equals('Season 99: Cloud Whispers'));
    });
  });

  group('SeasonServiceImpl Rollover & Sync Integration', () {
    test('calculateRollover evaluates prestige points and trophy crests', () {
      final service = SeasonServiceImpl.instance;
      final season = SeasonPeriod.defaultSeason1();

      final firstPlaceRecord = service.calculateRollover(
        userId: 'test_user_champ',
        season: season,
        currentPoints: 4500,
        currentRank: 1,
        divisionTitle: 'Division 4: Feline Ranger',
      );

      expect(firstPlaceRecord.prestigeEarned, equals(5500));
      expect(
        firstPlaceRecord.trophyCrest,
        equals(SeasonTrophyCrest.goldMythic),
      );
      expect(firstPlaceRecord.startingPlacementPoints, equals(1200));

      final midTierRecord = service.calculateRollover(
        userId: 'test_user_mid',
        season: season,
        currentPoints: 800,
        currentRank: 8,
        divisionTitle: 'Division 2: Alley Prowler',
      );

      expect(midTierRecord.prestigeEarned, equals(1300));
      expect(midTierRecord.trophyCrest, equals(SeasonTrophyCrest.silverMythic));
      expect(midTierRecord.startingPlacementPoints, equals(350));
    });

    test(
      'completeSeasonRollover advances season and records prestige',
      () async {
        final service = SeasonServiceImpl.instance;
        const userId = 'user_rollover_test';

        final record = await service.completeSeasonRollover(
          userId: userId,
          currentPoints: 2000,
          currentRank: 2,
          divisionTitle: 'Division 3: Whiskers Tracker',
        );

        expect(record.trophyCrest, equals(SeasonTrophyCrest.goldMythic));

        final prestige = await service.getMythicPrestige(userId);
        expect(prestige, equals(record.prestigeEarned));

        final history = await service.getSeasonHistory(userId);
        expect(history.length, equals(1));
        expect(history.first.seasonId, equals('season_1'));

        final nextSeason = await service.getCurrentSeason();
        expect(nextSeason.number, equals(2));
      },
    );
  });

  group('SubscriptionServiceImpl Cloud & Local Lifecycle', () {
    test('getSubscription defaults to free explorer tier', () async {
      final service = SubscriptionServiceImpl.instance;
      final status = await service.getSubscription('user_free_explorer');

      expect(status.isClubMember, isFalse);
      expect(status.tier, equals(SubscriptionTier.free));
    });

    test(
      'upgradeToClub and cancelSubscription toggle membership status',
      () async {
        final service = SubscriptionServiceImpl.instance;
        const userId = 'user_club_subscriber';

        final upgraded = await service.upgradeToClub(
          userId,
          interval: BillingInterval.annual,
        );

        expect(upgraded.isClubMember, isTrue);
        expect(upgraded.tier, equals(SubscriptionTier.felineClubMember));
        expect(upgraded.activeInterval, equals(BillingInterval.annual));

        final cancelled = await service.cancelSubscription(userId);
        expect(cancelled.isClubMember, isFalse);
        expect(cancelled.tier, equals(SubscriptionTier.free));
      },
    );
  });

  group('PhotoVaultServiceImpl Storage & Archiving', () {
    test('getVault returns default seed photos when empty', () async {
      final service = PhotoVaultServiceImpl.instance;
      final photos = await service.getVault('user_vault_demo');

      expect(photos.isNotEmpty, isTrue);
      expect(photos.length, equals(3));
      expect(photos.first.fileSizeBytes, greaterThan(0));
    });

    test(
      'archivePhoto appends photo and recalculates total storage bytes',
      () async {
        final service = PhotoVaultServiceImpl.instance;
        const userId = 'user_vault_uploader';

        final initialBytes = await service.getTotalVaultBytes(userId);

        final newPhoto = VaultPhotoEntry(
          id: 'photo_test_raw_1',
          userId: userId,
          sightingId: 'sighting_test_1',
          breedName: 'Island Puspin',
          photoUrl: 'https://images.unsplash.com/photo-test.jpg',
          fileSizeBytes: 8388608, // 8 MB
          resolutionWidth: 4032,
          resolutionHeight: 3024,
          capturedAt: DateTime.now(),
          locationLabel: 'Bankal, Lapu-Lapu City',
        );

        await service.archivePhoto(newPhoto);

        final updatedPhotos = await service.getVault(userId);
        expect(updatedPhotos.any((p) => p.id == 'photo_test_raw_1'), isTrue);

        final updatedBytes = await service.getTotalVaultBytes(userId);
        expect(updatedBytes, equals(initialBytes + 8388608));

        await service.removePhoto(userId, 'photo_test_raw_1');
        final afterRemove = await service.getVault(userId);
        expect(afterRemove.any((p) => p.id == 'photo_test_raw_1'), isFalse);
      },
    );
  });
}
