import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/quests/data/datasources/firebase_quest_datasource.dart';
import 'package:pokeiring/features/quests/data/repositories/paw_quests_repository_impl.dart';
import 'package:pokeiring/features/quests/domain/entities/paw_quest.dart';
import 'package:pokeiring/features/quests/domain/entities/quest_template.dart';
import 'package:pokeiring/features/quests/presentation/widgets/quest_pool_editor_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuestTemplate Entity', () {
    test('serializes toMap and fromMap cleanly', () {
      const template = QuestTemplate(
        id: 'tpl_test_calico',
        title: 'Calico Quest',
        description: 'Spot a calico friend',
        category: QuestCategory.daily,
        type: QuestType.scanBreed,
        targetValue: 1.0,
        rewardPawPoints: 50,
        targetBreed: 'Calico',
        isActive: true,
        weight: 12,
      );

      final map = template.toMap();
      final restored = QuestTemplate.fromMap(map);

      expect(restored.id, equals('tpl_test_calico'));
      expect(restored.title, equals('Calico Quest'));
      expect(restored.category, equals(QuestCategory.daily));
      expect(restored.type, equals(QuestType.scanBreed));
      expect(restored.targetBreed, equals('Calico'));
      expect(restored.targetValue, equals(1.0));
      expect(restored.rewardPawPoints, equals(50));
      expect(restored.isActive, isTrue);
      expect(restored.weight, equals(12));
    });

    test('default catalog provides balanced variety of quests', () {
      final defaults = QuestTemplate.defaultCatalog();
      expect(defaults.length, greaterThanOrEqualTo(15));

      final dailyTemplates = defaults
          .where((t) => t.category == QuestCategory.daily)
          .toList();
      final weeklyTemplates = defaults
          .where((t) => t.category == QuestCategory.weekly)
          .toList();

      expect(dailyTemplates.length, greaterThanOrEqualTo(8));
      expect(weeklyTemplates.length, greaterThanOrEqualTo(5));

      // Contains steps, distance, scan, and boop quests
      expect(defaults.any((t) => t.type == QuestType.steps), isTrue);
      expect(defaults.any((t) => t.type == QuestType.distance), isTrue);
      expect(defaults.any((t) => t.type == QuestType.scanBreed), isTrue);
      expect(defaults.any((t) => t.type == QuestType.boopSightings), isTrue);
    });
  });

  group('FirebaseQuestDataSource', () {
    test('reads default catalog and toggles template state', () async {
      final dataSource = FirebaseQuestDataSource.instance;
      final pool = await dataSource.getQuestPool();

      expect(pool.isNotEmpty, isTrue);
      final first = pool.first;

      await dataSource.toggleTemplateActive(first.id, false);
      final updatedPool = await dataSource.getQuestPool();
      final updatedFirst = updatedPool.firstWhere((t) => t.id == first.id);
      expect(updatedFirst.isActive, isFalse);

      // Re-enable
      await dataSource.toggleTemplateActive(first.id, true);
      final reEnabledPool = await dataSource.getQuestPool();
      final reEnabledFirst = reEnabledPool.firstWhere((t) => t.id == first.id);
      expect(reEnabledFirst.isActive, isTrue);
    });
  });

  group('Dynamic Quest Pool Rotation in PawQuestsRepositoryImpl', () {
    test(
      'generates deterministic daily and weekly quests from active pool',
      () async {
        final repo = PawQuestsRepositoryImpl();
        const userId = 'explorer_rotation_user';

        final quests = await repo.watchQuests(userId).first;
        final dailyQuests = quests
            .where((q) => q.category == QuestCategory.daily)
            .toList();
        final weeklyQuests = quests
            .where((q) => q.category == QuestCategory.weekly)
            .toList();

        expect(dailyQuests.length, equals(3));
        expect(weeklyQuests.length, equals(2));

        // Second emission on same date should yield identical IDs (deterministic seed)
        final questsAgain = await repo.watchQuests(userId).first;
        expect(
          questsAgain.map((q) => q.id).toList(),
          equals(quests.map((q) => q.id).toList()),
        );
      },
    );

    test('deactivated templates are excluded from quest rotation', () async {
      final dataSource = FirebaseQuestDataSource.instance;
      final pool = await dataSource.getQuestPool();

      // Deactivate morning prowl
      final prowl = pool.firstWhere((t) => t.id == 'tpl_morning_prowl');
      await dataSource.toggleTemplateActive(prowl.id, false);

      final repo = PawQuestsRepositoryImpl();
      final quests = await repo.watchQuests('user_test_inactive').first;

      expect(quests.any((q) => q.id.startsWith('tpl_morning_prowl')), isFalse);

      // Restore active state
      await dataSource.toggleTemplateActive(prowl.id, true);
    });
  });

  group('QuestPoolEditorSheet Presentation Widget', () {
    testWidgets(
      'renders pool manager sheet, filters and toggles active switch',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => QuestPoolEditorSheet.show(context),
                  child: const Text('Open Pool Manager'),
                ),
              ),
            ),
          ),
        );

        // Open sheet
        await tester.tap(find.text('Open Pool Manager'));
        await tester.pumpAndSettle();

        expect(find.text('Quest Pool Manager'), findsOneWidget);
        expect(
          find.textContaining('templates active in rotation'),
          findsOneWidget,
        );

        // Verify category filter tabs
        expect(find.textContaining('All ('), findsOneWidget);
        expect(find.textContaining('Daily ('), findsOneWidget);
        expect(find.textContaining('Weekly ('), findsOneWidget);

        // Filter to Weekly
        await tester.tap(find.textContaining('Weekly ('));
        await tester.pumpAndSettle();

        expect(find.text('WEEKLY'), findsWidgets);

        // Toggle first Switch
        final switchFinder = find.byType(Switch).first;
        expect(switchFinder, findsOneWidget);
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
      },
    );
  });
}
