import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/quests/data/repositories/paw_quests_repository_impl.dart';
import 'package:pokeiring/features/quests/domain/entities/paw_quest.dart';
import 'package:pokeiring/features/quests/presentation/widgets/paw_quest_card.dart';
import 'package:pokeiring/features/quests/presentation/widgets/paw_quests_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PawQuest Entity', () {
    test('calculates completion and progress fractions correctly', () {
      final now = DateTime.now();

      final inProgressQuest = PawQuest(
        id: 'quest-steps-1',
        title: 'Morning Steps',
        description: 'Walk 1,500 steps',
        category: QuestCategory.daily,
        type: QuestType.steps,
        targetValue: 1500,
        currentValue: 750,
        rewardPawPoints: 40,
        expiresAt: now.add(const Duration(hours: 4)),
      );

      expect(inProgressQuest.isCompleted, isFalse);
      expect(inProgressQuest.progressFraction, equals(0.5));
      expect(inProgressQuest.progressFormatted, equals('750 / 1500 steps'));

      final completedQuest = inProgressQuest.copyWith(currentValue: 1500);
      expect(completedQuest.isCompleted, isTrue);
      expect(completedQuest.progressFraction, equals(1.0));

      final distanceQuest = inProgressQuest.copyWith(
        type: QuestType.distance,
        targetValue: 2.0,
        currentValue: 1.5,
      );
      expect(distanceQuest.progressFormatted, equals('1.5 / 2.0 km'));

      final overcompletedQuest = inProgressQuest.copyWith(
        type: QuestType.scanCat,
        targetValue: 1.0,
        currentValue: 2.0,
      );
      expect(overcompletedQuest.isCompleted, isTrue);
      expect(overcompletedQuest.progressFraction, equals(1.0));
      expect(overcompletedQuest.progressFormatted, equals('1 / 1'));
    });

    test('serializes toMap and fromMap cleanly', () {
      final now = DateTime.now();
      final quest = PawQuest(
        id: 'q-serial-1',
        title: 'Calico Bounty',
        description: 'Spot a calico cat',
        category: QuestCategory.daily,
        type: QuestType.scanBreed,
        targetValue: 1,
        currentValue: 1,
        rewardPawPoints: 50,
        isClaimed: true,
        expiresAt: now,
        targetBreed: 'Calico',
      );

      final map = quest.toMap();
      final reconstructed = PawQuest.fromMap(map);

      expect(reconstructed.id, equals(quest.id));
      expect(reconstructed.title, equals(quest.title));
      expect(reconstructed.category, equals(QuestCategory.daily));
      expect(reconstructed.type, equals(QuestType.scanBreed));
      expect(reconstructed.isClaimed, isTrue);
      expect(reconstructed.targetBreed, equals('Calico'));
    });
  });

  group('PawQuestsRepositoryImpl', () {
    test('generates daily and weekly quests and updates progress', () async {
      final repo = PawQuestsRepositoryImpl();
      const userId = 'explorer_test_1';

      final quests = await repo.watchQuests(userId).first;
      expect(quests.length, greaterThanOrEqualTo(5));

      final dailySteps = quests.firstWhere((q) => q.type == QuestType.steps);
      expect(dailySteps.category, equals(QuestCategory.daily));

      // Sync health progress
      await repo.syncHealthProgress(
        userId: userId,
        stepsToday: 1600,
        distanceKm: 1.5,
      );

      final updatedQuests = await repo.watchQuests(userId).first;
      final updatedSteps = updatedQuests.firstWhere(
        (q) => q.id == dailySteps.id,
      );

      expect(updatedSteps.currentValue, equals(1600.0));
      expect(updatedSteps.isCompleted, isTrue);

      // Claim reward
      final claimedPoints = await repo.claimReward(
        userId: userId,
        questId: dailySteps.id,
      );
      expect(claimedPoints, equals(updatedSteps.rewardPawPoints));

      // Attempt duplicate claim
      final duplicatePoints = await repo.claimReward(
        userId: userId,
        questId: dailySteps.id,
      );
      expect(duplicatePoints, equals(0));
    });
  });

  group('Paw Quests Presentation Widgets', () {
    testWidgets('PawQuestCard renders title, progress and claim button', (
      tester,
    ) async {
      bool claimed = false;
      final now = DateTime.now();

      final quest = PawQuest(
        id: 'card-quest-1',
        title: 'Morning Prowl',
        description: 'Walk 1,500 steps today',
        category: QuestCategory.daily,
        type: QuestType.steps,
        targetValue: 1500,
        currentValue: 1500,
        rewardPawPoints: 40,
        isClaimed: false,
        expiresAt: now.add(const Duration(hours: 6)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PawQuestCard(quest: quest, onClaim: () => claimed = true),
          ),
        ),
      );

      expect(find.text('Morning Prowl'), findsOneWidget);
      expect(find.text('+40'), findsOneWidget);
      expect(find.text('Claim +40 Paw Points'), findsOneWidget);

      await tester.tap(find.text('Claim +40 Paw Points'));
      expect(claimed, isTrue);
    });

    testWidgets('PawQuestsSection switches between daily and weekly tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PawQuestsSection(userId: 'test_user_ui'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Paw Quests'), findsOneWidget);
      expect(find.text('Daily Quests'), findsOneWidget);
      expect(find.text('Weekly Missions'), findsOneWidget);

      // Switch to Weekly tab
      await tester.tap(find.text('Weekly Missions'));
      await tester.pumpAndSettle();

      expect(find.text('Territory Wanderer'), findsOneWidget);
    });
  });
}
