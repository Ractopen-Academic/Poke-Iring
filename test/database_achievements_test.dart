import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/achievements/data/datasources/achievements_catalog.dart';
import 'package:pokeiring/features/achievements/data/datasources/firebase_achievements_datasource.dart';
import 'package:pokeiring/features/achievements/data/repositories/achievements_repository_impl.dart';
import 'package:pokeiring/features/achievements/domain/entities/achievement_tier.dart';
import 'package:pokeiring/features/achievements/domain/entities/explorer_title.dart';
import 'package:pokeiring/features/achievements/domain/entities/tiered_achievement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirebaseAchievementsDataSource.instance.resetCache();
  });

  group('TieredAchievement Serialization', () {
    test('toMap and fromMap serialize and deserialize achievement tracks accurately', () {
      const milestone = AchievementMilestone(
        tier: AchievementTier.gold,
        targetValue: 50000,
        rewardPawPoints: 200,
        rewardTitle: ExplorerTitle(
          id: 'title_gold_paws',
          name: 'Gold Paws',
          description: 'Achieved 50,000 steps.',
          rarity: TitleRarity.rare,
          tier: AchievementTier.gold,
        ),
      );

      const track = TieredAchievement(
        id: 'movement_custom_run',
        title: 'Island Runner',
        description: 'Run through island streets.',
        category: AchievementCategory.movement,
        unit: 'km',
        milestones: [milestone],
      );

      final map = track.toMap();
      expect(map['id'], 'movement_custom_run');
      expect(map['category'], 'movement');
      expect(map['milestones'], isA<List>());

      final reconstructed = TieredAchievement.fromMap(map);
      expect(reconstructed.id, track.id);
      expect(reconstructed.title, track.title);
      expect(reconstructed.category, AchievementCategory.movement);
      expect(reconstructed.milestones.length, 1);
      expect(reconstructed.milestones.first.rewardTitle?.name, 'Gold Paws');
    });

    test('fromMap gracefully handles unknown category and nulls', () {
      final map = {
        'id': 'mystery_track',
        'title': 'Mystery Track',
        'category': 'interstellar_exploration',
      };

      final parsed = TieredAchievement.fromMap(map);
      expect(parsed.id, 'mystery_track');
      expect(parsed.category, AchievementCategory.movement);
      expect(parsed.milestones, isEmpty);
    });
  });

  group('FirebaseAchievementsDataSource Operations', () {
    test('getCatalog falls back to initial catalog without error', () async {
      final dataSource = FirebaseAchievementsDataSource.instance;
      final catalog = await dataSource.getCatalog();

      expect(catalog.isNotEmpty, isTrue);
      expect(
        catalog.length,
        equals(AchievementsCatalog.getInitialCatalog().length),
      );
      expect(catalog.any((t) => t.id == 'movement_steps'), isTrue);
    });

    test(
      'upsertTrack and deleteTrack dynamically update in-memory catalog',
      () async {
        final dataSource = FirebaseAchievementsDataSource.instance;
        await dataSource.getCatalog();

        const newTrack = TieredAchievement(
          id: 'track_community_boops',
          title: 'Master Booper',
          description: 'Boop 500 roaming community cats.',
          category: AchievementCategory.community,
          unit: 'boops',
          milestones: [
            AchievementMilestone(
              tier: AchievementTier.bronze,
              targetValue: 10,
              rewardPawPoints: 50,
            ),
          ],
        );

        await dataSource.upsertTrack(newTrack);
        final catalogAfterAdd = await dataSource.getCatalog();
        expect(
          catalogAfterAdd.any((t) => t.id == 'track_community_boops'),
          isTrue,
        );

        await dataSource.deleteTrack('track_community_boops');
        final catalogAfterDelete = await dataSource.getCatalog();
        expect(
          catalogAfterDelete.any((t) => t.id == 'track_community_boops'),
          isFalse,
        );
      },
    );
  });

  group('AchievementsRepositoryImpl Dynamic Integration', () {
    test('watchAchievements emits initial tracks and titles', () async {
      final repo = AchievementsRepositoryImpl.instance;
      final stream = repo.watchAchievements('test_user_achievements');

      final tracks = await stream.first;
      expect(tracks.isNotEmpty, isTrue);
      expect(tracks.any((t) => t.id == 'movement_steps'), isTrue);
    });

    test(
      'recordProgressMetric and claimMilestoneReward work with dynamic catalog',
      () async {
        final repo = AchievementsRepositoryImpl.instance;
        const userId = 'test_user_progress';

        // Record steps to pass bronze target (1,000 steps)
        await repo.recordProgressMetric(
          userId: userId,
          metricKey: 'movement_steps',
          incrementBy: 1500,
        );

        // Claim reward for bronze milestone
        final reward = await repo.claimMilestoneReward(
          userId: userId,
          achievementId: 'movement_steps',
          tier: AchievementTier.bronze,
        );

        expect(reward, equals(25)); // 25 paw points reward

        // Re-claiming should return 0
        final duplicateClaim = await repo.claimMilestoneReward(
          userId: userId,
          achievementId: 'movement_steps',
          tier: AchievementTier.bronze,
        );
        expect(duplicateClaim, equals(0));
      },
    );
  });
}
