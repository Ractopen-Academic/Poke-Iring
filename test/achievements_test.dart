import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/achievements/data/datasources/achievements_catalog.dart';
import 'package:pokeiring/features/achievements/data/repositories/achievements_repository_impl.dart';
import 'package:pokeiring/features/achievements/domain/entities/achievement_tier.dart';
import 'package:pokeiring/features/achievements/domain/entities/explorer_title.dart';
import 'package:pokeiring/features/achievements/domain/entities/tiered_achievement.dart';
import 'package:pokeiring/features/achievements/presentation/pages/achievements_page.dart';
import 'package:pokeiring/features/achievements/presentation/widgets/equipped_title_badge.dart';
import 'package:pokeiring/features/achievements/presentation/widgets/tiered_achievement_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Achievement Entities & Catalog', () {
    test('AchievementTier correctly defines 4 ascending tiers', () {
      expect(AchievementTier.bronze.tierLevel, 1);
      expect(AchievementTier.silver.tierLevel, 2);
      expect(AchievementTier.gold.tierLevel, 3);
      expect(AchievementTier.platinum.tierLevel, 4);

      expect(AchievementTier.fromName('silver'), AchievementTier.silver);
      expect(AchievementTier.fromName('platinum'), AchievementTier.platinum);
      expect(AchievementTier.fromName('unknown'), AchievementTier.bronze);
    });

    test(
      'AchievementsCatalog contains exactly 25 tracks and 100 tier milestones',
      () {
        final catalog = AchievementsCatalog.getInitialCatalog();
        expect(catalog.length, 25);

        int totalMilestones = 0;
        for (final track in catalog) {
          expect(track.milestones.length, 4);
          expect(track.milestones[0].tier, AchievementTier.bronze);
          expect(track.milestones[1].tier, AchievementTier.silver);
          expect(track.milestones[2].tier, AchievementTier.gold);
          expect(track.milestones[3].tier, AchievementTier.platinum);
          totalMilestones += track.milestones.length;
        }

        expect(totalMilestones, 100);
      },
    );

    test(
      'TieredAchievement computes progression and unlock status correctly',
      () {
        const achievement = TieredAchievement(
          id: 'test_steps',
          title: 'Step Master',
          description: 'Walk steps',
          category: AchievementCategory.movement,
          currentProgress: 6000.0,
          unit: 'steps',
          milestones: [
            AchievementMilestone(
              tier: AchievementTier.bronze,
              targetValue: 1000.0,
              rewardPawPoints: 20,
            ),
            AchievementMilestone(
              tier: AchievementTier.silver,
              targetValue: 5000.0,
              rewardPawPoints: 50,
            ),
            AchievementMilestone(
              tier: AchievementTier.gold,
              targetValue: 20000.0,
              rewardPawPoints: 150,
            ),
            AchievementMilestone(
              tier: AchievementTier.platinum,
              targetValue: 50000.0,
              rewardPawPoints: 500,
            ),
          ],
        );

        expect(achievement.highestUnlockedTier, AchievementTier.silver);
        expect(achievement.nextMilestone.tier, AchievementTier.gold);
        expect(achievement.isMaxTier, isFalse);
        expect(achievement.unlockedMilestonesCount, 2);
        expect(achievement.hasClaimableMilestone, isTrue);
        expect(achievement.progressFraction, closeTo(6000.0 / 20000.0, 0.01));
      },
    );

    test('ExplorerTitle serializes and deserializes correctly', () {
      final title = ExplorerTitle(
        id: 'title_test',
        name: 'Night Prowler',
        description: 'Master of the night',
        rarity: TitleRarity.epic,
        tier: AchievementTier.gold,
        isEquipped: true,
        unlockedAt: DateTime(2026, 10, 30),
      );

      final map = title.toMap();
      final restored = ExplorerTitle.fromMap(map);

      expect(restored.id, 'title_test');
      expect(restored.name, 'Night Prowler');
      expect(restored.rarity, TitleRarity.epic);
      expect(restored.tier, AchievementTier.gold);
      expect(restored.isEquipped, isTrue);
      expect(restored.isUnlocked, isTrue);
    });
  });

  group('AchievementsRepositoryImpl', () {
    test('emits initial tracks, records metric, and claims reward', () async {
      final repo = AchievementsRepositoryImpl.instance;
      const userId = 'user_achievement_test';

      final initialTracks = await repo.watchAchievements(userId).first;
      expect(initialTracks.length, 25);

      // Increment progress on Trail Paws
      await repo.recordProgressMetric(
        userId: userId,
        metricKey: 'movement_steps',
        incrementBy: 1500.0,
      );

      final updatedTracks = await repo.watchAchievements(userId).first;
      final stepsTrack = updatedTracks.firstWhere(
        (t) => t.id == 'movement_steps',
      );
      expect(stepsTrack.currentProgress, 1500.0);
      expect(
        stepsTrack.milestones.first.isUnlocked(stepsTrack.currentProgress),
        isTrue,
      );

      // Claim reward for bronze tier
      final reward = await repo.claimMilestoneReward(
        userId: userId,
        achievementId: 'movement_steps',
        tier: AchievementTier.bronze,
      );
      expect(reward, 25);

      // Idempotent: claiming second time yields 0
      final secondClaim = await repo.claimMilestoneReward(
        userId: userId,
        achievementId: 'movement_steps',
        tier: AchievementTier.bronze,
      );
      expect(secondClaim, 0);

      // Equip a title
      await repo.equipTitle(userId: userId, titleId: 'title_novice_scout');
      final equipped = await repo.watchEquippedTitle(userId).first;
      expect(equipped?.id, 'title_novice_scout');
    });
  });

  group('Presentation Widgets', () {
    testWidgets('EquippedTitleBadge renders title name and responds to tap', (
      tester,
    ) async {
      bool tapped = false;
      const title = ExplorerTitle(
        id: 'title_test',
        name: 'Shadow Walker',
        description: 'Test description',
        tier: AchievementTier.platinum,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EquippedTitleBadge(title: title, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('Shadow Walker'), findsOneWidget);
      await tester.tap(find.byType(EquippedTitleBadge));
      expect(tapped, isTrue);
    });

    testWidgets(
      'TieredAchievementCard renders title, progress, and claim action',
      (tester) async {
        const achievement = TieredAchievement(
          id: 'movement_steps',
          title: 'Trail Paws',
          description: 'Walk steps across your neighborhood',
          category: AchievementCategory.movement,
          currentProgress: 2000.0,
          unit: 'steps',
          milestones: [
            AchievementMilestone(
              tier: AchievementTier.bronze,
              targetValue: 1000.0,
              rewardPawPoints: 25,
              isClaimed: false,
            ),
            AchievementMilestone(
              tier: AchievementTier.silver,
              targetValue: 10000.0,
              rewardPawPoints: 75,
              isClaimed: false,
            ),
            AchievementMilestone(
              tier: AchievementTier.gold,
              targetValue: 50000.0,
              rewardPawPoints: 200,
              isClaimed: false,
            ),
            AchievementMilestone(
              tier: AchievementTier.platinum,
              targetValue: 250000.0,
              rewardPawPoints: 500,
              isClaimed: false,
            ),
          ],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TieredAchievementCard(
                achievement: achievement,
                userId: 'user_card_test',
              ),
            ),
          ),
        );

        expect(find.text('Trail Paws'), findsOneWidget);
        expect(find.text('2000 / 10000 steps'), findsOneWidget);
        expect(find.textContaining('Claim Bronze'), findsOneWidget);
      },
    );

    testWidgets(
      'AchievementsPage renders hero progress card and category chips',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AchievementsPage(userId: 'user_page_test')),
        );

        await tester.pumpAndSettle();

        expect(find.text('Achievements & Titles'), findsOneWidget);
        expect(find.text('Trophy Case Progress'), findsOneWidget);
        expect(find.text('Movement'), findsOneWidget);
        expect(find.text('Discovery'), findsOneWidget);
      },
    );
  });
}
