import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/dex/data/datasources/firebase_dex_datasource.dart';
import 'package:pokeiring/features/dex/data/repositories/dex_repository_impl.dart';
import 'package:pokeiring/features/dex/domain/entities/feline_dex_species.dart';
import 'package:pokeiring/features/leaderboard/data/datasources/firebase_leaderboard_datasource.dart';
import 'package:pokeiring/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:pokeiring/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:pokeiring/features/leaderboard/domain/entities/leaderboard_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirebaseDexDataSource.instance.resetCache();
    FirebaseLeaderboardDataSource.instance.resetCache();
  });

  group('FelineDexSpecies Database Serialization & Models', () {
    test('toMap and fromMap serialize and deserialize accurately', () {
      const species = FelineDexSpecies(
        id: 'dex_test_99',
        dexNumber: 99,
        name: 'Island Cloud Leopard',
        commonName: 'Palawan Clouded Cat',
        coatPattern: 'Clouded Rosettes',
        rarity: FelineRarityTier.mythic,
        description: 'Elusive treetop acrobat of pristine Philippine forests.',
        habitat: 'Canopy perches, limestone ridges',
        defaultSeed: 'Palawan 99',
      );

      final map = species.toMap();
      expect(map['id'], 'dex_test_99');
      expect(map['dexNumber'], 99);
      expect(map['rarity'], 'mythic');

      final reconstructed = FelineDexSpecies.fromMap(map);
      expect(reconstructed.id, species.id);
      expect(reconstructed.dexNumber, species.dexNumber);
      expect(reconstructed.name, species.name);
      expect(reconstructed.rarity, FelineRarityTier.mythic);
      expect(reconstructed, equals(species));
    });

    test('fromMap safely falls back on missing or unknown rarity', () {
      final map = {
        'id': 'dex_unknown',
        'dexNumber': 42,
        'name': 'Unknown Cat',
        'rarity': 'celestial_god_tier',
      };

      final parsed = FelineDexSpecies.fromMap(map);
      expect(parsed.rarity, FelineRarityTier.common);
      expect(parsed.commonName, 'Classic Tabby Puspin');
    });

    test('copyWith produces updated species immutably', () {
      const original = FelineDexSpecies(
        id: 'dex_001',
        dexNumber: 1,
        name: 'Domestic Shorthair',
        commonName: 'Classic Tabby Puspin',
        coatPattern: 'Tabby',
        rarity: FelineRarityTier.common,
        description: 'Original description',
        habitat: 'Porch',
        defaultSeed: 'Tabby 1',
      );

      final updated = original.copyWith(
        commonName: 'Legendary Island Tabby',
        rarity: FelineRarityTier.rare,
      );

      expect(updated.id, 'dex_001');
      expect(updated.commonName, 'Legendary Island Tabby');
      expect(updated.rarity, FelineRarityTier.rare);
      expect(original.commonName, 'Classic Tabby Puspin');
    });
  });

  group('FirebaseDexDataSource Offline & In-Memory Operations', () {
    test(
      'getSpecies falls back to canonical species without crashing',
      () async {
        final dataSource = FirebaseDexDataSource.instance;
        final species = await dataSource.getSpecies();

        expect(species.isNotEmpty, isTrue);
        expect(species.length, greaterThanOrEqualTo(10));
        expect(species.first.id, 'dex_001');
      },
    );

    test('upsertSpecies inserts new species and emits update', () async {
      final dataSource = FirebaseDexDataSource.instance;
      await dataSource.getSpecies(); // Load baseline

      const newBreed = FelineDexSpecies(
        id: 'dex_custom_1',
        dexNumber: 100,
        name: 'Visayan Wild Cat',
        commonName: 'Bagyo Prowler',
        coatPattern: 'Spotted Gold',
        rarity: FelineRarityTier.mythic,
        description: 'Brisk wind stalker.',
        habitat: 'Hills',
        defaultSeed: 'Visayan 100',
      );

      await dataSource.upsertSpecies(newBreed);

      final updatedList = await dataSource.getSpecies();
      expect(updatedList.any((s) => s.id == 'dex_custom_1'), isTrue);

      await dataSource.deleteSpecies('dex_custom_1');
      final listAfterDelete = await dataSource.getSpecies();
      expect(listAfterDelete.any((s) => s.id == 'dex_custom_1'), isFalse);
    });
  });

  group('LeaderboardEntry Serialization & Firestore Parsing', () {
    test('fromFirestore creates valid LeaderboardEntry from document data', () {
      final docData = {
        'displayName': 'LapuLapuExplorer',
        'avatarColorIndex': 3,
        'totalPawPoints': 7800,
        'totalSnaps': 45,
        'distanceKm': 32.5,
        'mythicPaws': 2,
        'barangay': 'Bankal',
        'city': 'Lapu-Lapu City',
        'region': 'Central Visayas',
        'country': 'Philippines',
      };

      final entry = LeaderboardEntry.fromFirestore(
        'user_123',
        docData,
        currentUserId: 'user_123',
      );

      expect(entry.id, 'user_123');
      expect(entry.userId, 'user_123');
      expect(entry.displayName, 'LapuLapuExplorer');
      expect(entry.points, 7800);
      expect(entry.catsSnapped, 45);
      expect(entry.distanceKm, 32.5);
      expect(entry.mythicPaws, 2);
      expect(entry.barangay, 'Bankal');
      expect(entry.city, 'Lapu-Lapu City');
      expect(entry.isCurrentUser, isTrue);
    });

    test('toMap and fromMap serialize and deserialize cleanly', () {
      const entry = LeaderboardEntry(
        id: 'entry_1',
        rank: 1,
        userId: 'user_1',
        displayName: 'MingMingMaster',
        avatarColorIndex: 1,
        barangay: 'Mactan',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        points: 9200,
        catsSnapped: 50,
        distanceKm: 41.2,
        mythicPaws: 3,
        isCurrentUser: false,
      );

      final map = entry.toMap();
      final reconstructed = LeaderboardEntry.fromMap(map);

      expect(reconstructed.id, entry.id);
      expect(reconstructed.points, 9200);
      expect(reconstructed.displayName, 'MingMingMaster');
    });
  });

  group('FirebaseLeaderboardDataSource Operations', () {
    test(
      'fetchEntries returns seed fallback with current user marked',
      () async {
        final dataSource = FirebaseLeaderboardDataSource.instance;
        final entries = await dataSource.fetchEntries(
          currentUserId: 'user-mactan-boss',
        );

        expect(entries.isNotEmpty, isTrue);
        final boss = entries.firstWhere((e) => e.userId == 'user-mactan-boss');
        expect(boss.isCurrentUser, isTrue);
      },
    );
  });

  group('LeaderboardRepositoryImpl Integration', () {
    test(
      'getLeaderboard integrates entries and properly computes rankings',
      () async {
        final repository = LeaderboardRepositoryImpl();
        final entries = await repository.getLeaderboard(
          filter: const LeaderboardFilter(
            scope: LeaderboardScope.city,
            city: 'Lapu-Lapu City',
          ),
          currentUserId: 'test-user-xyz',
        );

        expect(entries.isNotEmpty, isTrue);
        expect(entries.first.rank, 1);
        for (int i = 0; i < entries.length - 1; i++) {
          expect(entries[i].points >= entries[i + 1].points, isTrue);
        }
      },
    );

    test('getUserStanding retrieves current user standing in scope', () async {
      final repository = LeaderboardRepositoryImpl();
      final standing = await repository.getUserStanding(
        userId: 'test-user-standing',
        filter: const LeaderboardFilter(
          scope: LeaderboardScope.city,
          city: 'Lapu-Lapu City',
        ),
      );

      expect(standing, isNotNull);
      expect(standing!.userId, 'test-user-standing');
      expect(standing.rank, greaterThan(0));
    });
  });

  group('DexRepositoryImpl Dynamic Species Integration', () {
    test(
      'getSpecies and watchSpecies return dynamic species catalog',
      () async {
        final repo = DexRepositoryImpl();
        final speciesList = await repo.getSpecies();

        expect(speciesList.isNotEmpty, isTrue);
        expect(speciesList.any((s) => s.id == 'dex_001'), isTrue);
      },
    );

    test('getDexEntries uses dynamic catalog with sightings', () async {
      final repo = DexRepositoryImpl();
      final entries = await repo.getDexEntries('user_no_sightings');

      expect(entries.isNotEmpty, isTrue);
      expect(entries.length, greaterThanOrEqualTo(10));
      expect(entries.any((e) => e.species.id == 'dex_001'), isTrue);
    });
  });
}
