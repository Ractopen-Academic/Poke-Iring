import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/events/data/datasources/local_event_catalog.dart';
import 'package:pokeiring/features/events/data/repositories/event_repository_impl.dart';
import 'package:pokeiring/features/events/domain/entities/feline_event.dart';
import 'package:pokeiring/features/events/domain/entities/profile_border.dart';
import 'package:pokeiring/features/events/presentation/widgets/event_banner_card.dart';
import 'package:pokeiring/features/events/presentation/widgets/profile_border_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileBorder Entity & Catalog', () {
    test('serializes toMap and fromMap cleanly', () {
      const border = ProfileBorder(
        id: 'border_test_cosmic',
        name: 'Cosmic Ring',
        description: 'Deep starlight ring',
        rarity: EventBorderRarity.legendary,
        cost: 200,
        gradientColors: [0xFF6366F1, 0xFFA855F7],
        strokeWidth: 3.5,
        glowColorValue: 0x666366F1,
        glowBlurRadius: 8.0,
      );

      final map = border.toMap();
      final restored = ProfileBorder.fromMap(map);

      expect(restored.id, equals('border_test_cosmic'));
      expect(restored.name, equals('Cosmic Ring'));
      expect(restored.rarity, equals(EventBorderRarity.legendary));
      expect(restored.cost, equals(200));
      expect(restored.colors.length, equals(2));
      expect(restored.glowColor, isNotNull);
    });

    test('default catalog provides 6 distinct tiered borders', () {
      final borders = ProfileBorder.defaultBorders();
      expect(borders.length, equals(6));

      expect(borders.any((b) => b.rarity == EventBorderRarity.rare), isTrue);
      expect(borders.any((b) => b.rarity == EventBorderRarity.epic), isTrue);
      expect(
        borders.any((b) => b.rarity == EventBorderRarity.legendary),
        isTrue,
      );
      expect(borders.any((b) => b.rarity == EventBorderRarity.mythic), isTrue);

      expect(LocalEventCatalog.findBorder('border_cherry_blossom'), isNotNull);
      expect(LocalEventCatalog.findBorder('border_neon_pulse'), isNotNull);
      expect(LocalEventCatalog.findBorder('border_golden_aureole'), isNotNull);
      expect(LocalEventCatalog.findBorder('border_mythic_dragon'), isNotNull);
    });
  });

  group('FelineEvent Entity', () {
    test('calculates active and expiration time remaining', () {
      final now = DateTime.now();
      final event = FelineEvent(
        id: 'event_test_active',
        title: 'Active Festival',
        subtitle: 'Celebration',
        description: 'Festival details',
        currencyName: 'Moonlit Tokens',
        currencyCode: 'MLT',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5, hours: 4)),
        bannerColorValue: 0xFF4C1D95,
        accentColorValue: 0xFFF59E0B,
        quests: const [],
        borders: const [],
      );

      expect(event.isActive, isTrue);
      expect(event.isExpired, isFalse);
      expect(event.remainingFormatted, contains('5d'));

      final expired = FelineEvent(
        id: 'event_test_expired',
        title: 'Past Festival',
        subtitle: 'Concluded',
        description: 'Done',
        currencyName: 'Moonlit Tokens',
        currencyCode: 'MLT',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 1)),
        bannerColorValue: 0xFF4C1D95,
        accentColorValue: 0xFFF59E0B,
        quests: const [],
        borders: const [],
      );

      expect(expired.isExpired, isTrue);
      expect(expired.remainingFormatted, equals('Concluded'));
    });
  });

  group('EventRepositoryImpl Economy & Quests', () {
    test(
      'earns coins, completes quests, purchases and equips borders',
      () async {
        final repo = EventRepositoryImpl.instance;
        const userId = 'explorer_events_tester';
        final event = await repo.getActiveEvent();

        // Initial wallet
        final initialWallet = await repo.getUserWallet(userId, event.id);
        expect(initialWallet.coinBalance, equals(0));
        expect(initialWallet.unlockedBorderIds, isEmpty);

        // Complete quest
        final firstQuest = event.quests.first;
        final completed = await repo.completeEventQuest(
          userId: userId,
          eventId: event.id,
          questId: firstQuest.id,
        );
        expect(completed, isTrue);

        final walletAfterQuest = await repo.getUserWallet(userId, event.id);
        expect(walletAfterQuest.coinBalance, equals(firstQuest.rewardCoins));
        expect(walletAfterQuest.isQuestCompleted(firstQuest.id), isTrue);

        // Attempt duplicate completion
        final duplicate = await repo.completeEventQuest(
          userId: userId,
          eventId: event.id,
          questId: firstQuest.id,
        );
        expect(duplicate, isFalse);

        // Add more coins to afford a border
        await repo.earnEventCoins(
          userId: userId,
          eventId: event.id,
          amount: 300,
          reason: 'Bonus patrol milestone',
        );

        final richWallet = await repo.getUserWallet(userId, event.id);
        expect(richWallet.coinBalance, greaterThanOrEqualTo(350));

        // Purchase Cherry Blossom border (cost 80)
        final bought = await repo.purchaseBorder(
          userId: userId,
          eventId: event.id,
          borderId: 'border_cherry_blossom',
        );
        expect(bought, isTrue);

        final walletAfterBuy = await repo.getUserWallet(userId, event.id);
        expect(
          walletAfterBuy.isBorderUnlocked('border_cherry_blossom'),
          isTrue,
        );

        // Equip border
        final equipped = await repo.equipBorder(
          userId: userId,
          borderId: 'border_cherry_blossom',
        );
        expect(equipped, isTrue);

        final equippedId = await repo.getEquippedBorderId(userId);
        expect(equippedId, equals('border_cherry_blossom'));

        // Unequip border
        await repo.equipBorder(userId: userId, borderId: null);
        final unequippedId = await repo.getEquippedBorderId(userId);
        expect(unequippedId, isNull);
      },
    );
  });

  group('Presentation Widgets for Events & Borders', () {
    testWidgets(
      'ProfileBorderAvatar renders with explicit or streamed border',
      (tester) async {
        final cherry = LocalEventCatalog.findBorder('border_cherry_blossom')!;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ProfileBorderAvatar(
                  border: cherry,
                  radius: 30,
                  child: const CircleAvatar(radius: 30, child: Text('EX')),
                ),
              ),
            ),
          ),
        );

        expect(find.text('EX'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets(
      'EventBannerCard renders festival info and opens EventCenterSheet',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EventBannerCard(
                userId: 'ui_event_user',
                userDisplayName: 'Luna Explorer',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Moonlit Strays Festival'), findsOneWidget);
        expect(find.textContaining('MLT'), findsWidgets);

        // Tap banner to open bottom sheet
        await tester.tap(find.text('Moonlit Strays Festival'));
        await tester.pumpAndSettle();

        expect(find.text('Festival Quests'), findsOneWidget);
        expect(find.text('Border Shop'), findsOneWidget);

        // Switch to Border Shop
        await tester.tap(find.text('Border Shop'));
        await tester.pumpAndSettle();

        expect(find.text('Live Avatar Preview'), findsOneWidget);
        expect(find.text('Festival Collection'), findsOneWidget);
        expect(find.text('Cherry Blossom'), findsWidgets);
      },
    );
  });
}
