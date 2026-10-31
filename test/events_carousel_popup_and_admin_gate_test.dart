import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/events/domain/entities/feline_event.dart';
import 'package:pokeiring/features/events/domain/entities/profile_border.dart';
import 'package:pokeiring/features/events/domain/entities/user_event_wallet.dart';
import 'package:pokeiring/features/events/domain/repositories/event_repository.dart';
import 'package:pokeiring/features/events/presentation/widgets/active_events_carousel.dart';
import 'package:pokeiring/features/events/presentation/widgets/event_popup_modal.dart';
import 'package:pokeiring/features/quests/domain/entities/paw_quest.dart';
import 'package:pokeiring/features/quests/domain/repositories/paw_quests_repository.dart';
import 'package:pokeiring/features/quests/presentation/widgets/paw_quests_section.dart';
import 'package:pokeiring/features/subscription/presentation/widgets/feline_club_paywall_sheet.dart';

class _FakeEventRepository implements EventRepository {
  final List<FelineEvent> events;

  _FakeEventRepository(this.events);

  @override
  Future<FelineEvent> getActiveEvent() async => events.first;

  @override
  Stream<FelineEvent> watchActiveEvent() => Stream.value(events.first);

  @override
  Future<List<FelineEvent>> getActiveEvents() async => events;

  @override
  Stream<List<FelineEvent>> watchActiveEvents() => Stream.value(events);

  @override
  Future<UserEventWallet> getUserWallet(String userId, String eventId) async {
    return UserEventWallet(
      userId: userId,
      eventId: eventId,
      coinBalance: 120,
      unlockedBorderIds: const [],
      completedQuestIds: const [],
    );
  }

  @override
  Stream<UserEventWallet> watchUserWallet(String userId, String eventId) {
    return Stream.value(
      UserEventWallet(
        userId: userId,
        eventId: eventId,
        coinBalance: 120,
        unlockedBorderIds: const [],
        completedQuestIds: const [],
      ),
    );
  }

  @override
  Future<bool> completeEventQuest({
    required String userId,
    required String eventId,
    required String questId,
  }) async => true;

  @override
  Future<int> earnEventCoins({
    required String userId,
    required String eventId,
    required int amount,
    required String reason,
  }) async => 120 + amount;

  @override
  Future<bool> equipBorder({
    required String userId,
    required String? borderId,
  }) async => true;

  @override
  Future<String?> getEquippedBorderId(String userId) async => null;

  @override
  Stream<String?> watchEquippedBorderId(String userId) => Stream.value(null);

  @override
  Future<bool> purchaseBorder({
    required String userId,
    required String eventId,
    required String borderId,
  }) async => true;
}

class _FakePawQuestsRepository implements PawQuestsRepository {
  @override
  Stream<List<PawQuest>> watchQuests(String userId) {
    return Stream.value([
      PawQuest(
        id: 'q_test_1',
        title: 'Morning Sighting',
        description: 'Scan 1 cat',
        category: QuestCategory.daily,
        type: QuestType.scanCat,
        rewardPawPoints: 50,
        targetValue: 1,
        currentValue: 0,
        isClaimed: false,
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      ),
    ]);
  }

  @override
  Future<void> syncHealthProgress({
    required String userId,
    required int stepsToday,
    required double distanceKm,
  }) async {}

  @override
  Future<void> recordCatScan({
    required String userId,
    required String breed,
    required DateTime timestamp,
  }) async {}

  @override
  Future<void> recordBoop({required String userId}) async {}

  @override
  Future<int> claimReward({
    required String userId,
    required String questId,
  }) async => 50;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleFestival = FelineEvent(
    id: 'ev_fest_1',
    title: 'Moonlit Strays Festival',
    subtitle: 'Limited Event',
    description: 'Map neighborhood cats and earn borders.',
    currencyName: 'Moonlit Tokens',
    currencyCode: 'MLT',
    startDate: DateTime.now().subtract(const Duration(days: 1)),
    endDate: DateTime.now().add(const Duration(days: 10)),
    bannerColorValue: 0xFF4C1D95,
    accentColorValue: 0xFFF59E0B,
    isFeaturedInCarousel: true,
    showPopupOnLaunch: true,
    eventType: 'festival',
    priority: 10,
    quests: const [
      EventQuestItem(
        id: 'eq_1',
        title: 'Twilight Scan',
        description: 'Scan a cat',
        rewardCoins: 50,
        targetValue: 1,
        type: 'scans',
      ),
    ],
    borders: ProfileBorder.defaultBorders(),
  );

  final samplePartnership = FelineEvent(
    id: 'ev_part_2',
    title: 'Cebu Sanctuary Care Drive',
    subtitle: 'Community Partnership',
    description: 'Collaborating with Island Rescue Org.',
    currencyName: 'Rescue Stars',
    currencyCode: 'STR',
    startDate: DateTime.now().subtract(const Duration(days: 1)),
    endDate: DateTime.now().add(const Duration(days: 15)),
    bannerColorValue: 0xFF0D9488,
    accentColorValue: 0xFF14B8A6,
    isFeaturedInCarousel: true,
    showPopupOnLaunch: false,
    eventType: 'partnership',
    partnerName: 'Island Rescue Org (IRO)',
    priority: 8,
    quests: const [],
    borders: ProfileBorder.defaultBorders(),
  );

  group('ActiveEventsCarousel Widget Tests', () {
    testWidgets(
      'renders active events and allows sliding between festival and partnership',
      (tester) async {
        final fakeRepo = _FakeEventRepository([
          sampleFestival,
          samplePartnership,
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActiveEventsCarousel(
                userId: 'u_test',
                userDisplayName: 'Tester',
                repository: fakeRepo,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Moonlit Strays Festival'), findsOneWidget);
        expect(find.text('Earn MLT'), findsOneWidget);

        // Verify PageView is present
        expect(find.byType(PageView), findsOneWidget);

        // Drag to next slide
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(find.text('Cebu Sanctuary Care Drive'), findsOneWidget);
        expect(find.text('Island Rescue Org (IRO)'), findsOneWidget);
      },
    );
  });

  group('EventPopupModal Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('displays modal on checkAndShow and persists dismissal', (
      tester,
    ) async {
      final fakeRepo = _FakeEventRepository([
        sampleFestival,
        samplePartnership,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  EventPopupModal.checkAndShow(
                    context,
                    userId: 'u_test',
                    userDisplayName: 'Tester',
                    repository: fakeRepo,
                  );
                },
                child: const Text('Trigger Popup'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Popup'));
      await tester.pumpAndSettle();

      expect(find.byType(EventPopupModal), findsOneWidget);
      expect(find.text('Moonlit Strays Festival'), findsOneWidget);
      expect(find.text('Explore Event'), findsOneWidget);

      // Toggle don't show again today
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Dismiss
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.byType(EventPopupModal), findsNothing);

      // Verify shouldShowEvent returns false for today
      final shouldShow = await EventPopupModal.shouldShowEvent(
        sampleFestival.id,
      );
      expect(shouldShow, isFalse);
    });
  });

  group('Quest Pool Admin Gating Tests', () {
    testWidgets('hides tune icon for standard non-admin users', (tester) async {
      final fakeQuestsRepo = _FakePawQuestsRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PawQuestsSection(
              userId: 'u_standard',
              repository: fakeQuestsRepo,
              isAdmin: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tune icon should NOT be visible
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
    });

    testWidgets('shows tune icon only for admin users', (tester) async {
      final fakeQuestsRepo = _FakePawQuestsRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PawQuestsSection(
              userId: 'u_admin',
              repository: fakeQuestsRepo,
              isAdmin: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tune icon SHOULD be visible
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    });

    test('AuthUser checks admin role correctly', () {
      const normalUser = AuthUser(id: '1', email: 'explorer@gmail.com');
      expect(normalUser.isAdminRole, isFalse);

      const iringPhUser = AuthUser(id: '2', email: 'curator@iring.ph');
      expect(iringPhUser.isAdminRole, isTrue);

      const pokeiringAdmin = AuthUser(id: '3', email: 'admin@pokeiring.app');
      expect(pokeiringAdmin.isAdminRole, isTrue);

      const explicitAdmin = AuthUser(
        id: '4',
        email: 'custom@domain.com',
        isAdmin: true,
      );
      expect(explicitAdmin.isAdminRole, isTrue);
    });
  });

  group('Feline Club Sandbox Payment Tests', () {
    testWidgets('allows selecting PayPal Sandbox, GCash, and Maya gateways', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FelineClubPaywallSheet(userId: 'u_tester')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sandbox Payment Method'), findsOneWidget);
      expect(find.text('PayPal'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);

      // Select GCash
      await tester.ensureVisible(find.text('GCash'));
      await tester.tap(find.text('GCash'));
      await tester.pumpAndSettle();

      // Tap Join Feline Club to trigger sandbox dialog
      await tester.ensureVisible(find.text('Join Feline Club'));
      await tester.tap(find.text('Join Feline Club'));
      await tester.pumpAndSettle();

      expect(find.text('GCash (PayMongo)'), findsOneWidget);
      expect(find.text('Sandbox Test Environment'), findsOneWidget);
      expect(find.text('Authorize Sandbox'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Sandbox Test Environment'), findsNothing);
    });
  });
}
