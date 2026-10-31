import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokeiring/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:pokeiring/features/leaderboard/domain/entities/leaderboard_query.dart';
import 'package:pokeiring/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:pokeiring/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:pokeiring/features/territory/domain/entities/explorer_territory.dart';
import 'package:pokeiring/features/territory/domain/services/territory_service.dart';
import 'package:pokeiring/features/territory/presentation/widgets/territory_locked_dialog.dart';
import 'package:pokeiring/features/territory/presentation/widgets/territory_setup_dialog.dart';

class _MockTerritoryService implements TerritoryService {
  ExplorerTerritory _territory;

  _MockTerritoryService(this._territory);

  @override
  Future<ExplorerTerritory> getTerritory(String userId) async => _territory;

  @override
  Stream<ExplorerTerritory> watchTerritory(String userId) =>
      Stream.value(_territory);

  @override
  Future<void> updateTerritory(
    String userId,
    ExplorerTerritory territory,
  ) async {
    _territory = territory;
  }

  @override
  Future<ExplorerTerritory> detectFromGps() async => _territory;

  @override
  Future<ExplorerTerritory?> autoDetectAndSync(String userId) async =>
      _territory;
}

class _MockLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardFilter filter,
    required String currentUserId,
  }) async => [];

  @override
  Future<LeaderboardEntry?> getUserStanding({
    required String userId,
    required LeaderboardFilter filter,
  }) async => const LeaderboardEntry(
    id: 'standing_1',
    rank: 7,
    userId: 'u_tester',
    displayName: 'Test Explorer',
    points: 2150,
    catsSnapped: 18,
    distanceKm: 12.5,
    barangay: 'Bankal',
    city: 'Lapu-Lapu City',
    country: 'Philippines',
    isCurrentUser: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExplorerTerritory Annual Lock Domain Tests', () {
    test(
      'unlocked territory has isChangeLocked = false and 0 days remaining',
      () {
        const unlocked = ExplorerTerritory(
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          lockedAt: null,
        );

        expect(unlocked.isChangeLocked, isFalse);
        expect(unlocked.daysUntilChangeAvailable, equals(0));
        expect(unlocked.nextChangeAvailableDate, isNull);
        expect(unlocked.nextChangeDateFormatted, equals('Available now'));
      },
    );

    test('locked territory under 365 days has isChangeLocked = true and correct remaining days', () {
      final now = DateTime.now();
      final locked60DaysAgo = ExplorerTerritory(
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        lockedAt: now.subtract(const Duration(days: 60)),
      );

      expect(locked60DaysAgo.isChangeLocked, isTrue);
      expect(locked60DaysAgo.daysUntilChangeAvailable, equals(305));
      expect(locked60DaysAgo.nextChangeAvailableDate, isNotNull);
    });

    test('locked territory after 365 days has isChangeLocked = false', () {
      final now = DateTime.now();
      final expiredLock = ExplorerTerritory(
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        lockedAt: now.subtract(const Duration(days: 366)),
      );

      expect(expiredLock.isChangeLocked, isFalse);
      expect(expiredLock.daysUntilChangeAvailable, equals(0));
    });

    test('toMap and fromMap preserves lockedAt correctly', () {
      final now = DateTime(2026, 10, 31, 12, 0, 0);
      final territory = ExplorerTerritory(
        barangay: 'Pajo',
        city: 'Lapu-Lapu City',
        lockedAt: now,
      );

      final map = territory.toMap();
      final restored = ExplorerTerritory.fromMap(map);

      expect(restored.barangay, equals('Pajo'));
      expect(restored.lockedAt, equals(now));
      expect(restored.isChangeLocked, isTrue);
    });
  });

  group('TerritorySetupDialog Widget Tests', () {
    testWidgets(
      'renders prompt for unconfirmed territory and locks on confirmation',
      (tester) async {
        final service = _MockTerritoryService(
          const ExplorerTerritory(
            barangay: 'Bankal',
            city: 'Lapu-Lapu City',
            isHomeConfirmed: false,
            lockedAt: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    TerritorySetupDialog.checkAndShow(
                      context,
                      userId: 'u_test',
                      territoryService: service,
                    );
                  },
                  child: const Text('Check Setup'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Setup'));
        await tester.pumpAndSettle();

        expect(find.text('Official Territory Setup'), findsOneWidget);
        expect(find.text('Bankal, Lapu-Lapu City'), findsOneWidget);
        expect(find.text('Confirm & Lock'), findsOneWidget);

        // Confirm & Lock
        await tester.tap(find.text('Confirm & Lock'));
        await tester.pumpAndSettle();

        expect(find.text('Official Territory Setup'), findsNothing);
        final updated = await service.getTerritory('u_test');
        expect(updated.isHomeConfirmed, isTrue);
        expect(updated.lockedAt, isNotNull);
        expect(updated.isChangeLocked, isTrue);
      },
    );
  });

  group('TerritoryLockedDialog Widget Tests', () {
    testWidgets(
      'displays cooldown details when locked and dismisses on Understood',
      (tester) async {
        final lockedTerritory = ExplorerTerritory(
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          lockedAt: DateTime.now().subtract(const Duration(days: 65)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TerritoryLockedDialog(
                territory: lockedTerritory,
                isAdmin: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Territory Locked'), findsOneWidget);
        expect(find.text('Annual Seasonal Cooldown'), findsOneWidget);
        expect(find.text('300 days'), findsOneWidget);
        expect(find.text('Understood'), findsOneWidget);

        await tester.tap(find.text('Understood'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('displays admin override button when isAdmin is true', (
      tester,
    ) async {
      final lockedTerritory = ExplorerTerritory(
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        lockedAt: DateTime.now().subtract(const Duration(days: 65)),
      );

      bool overrideCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerritoryLockedDialog(
              territory: lockedTerritory,
              isAdmin: true,
              onAdminOverride: () => overrideCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Admin Override: Change Territory'), findsOneWidget);
      await tester.tap(find.text('Admin Override: Change Territory'));
      await tester.pumpAndSettle();

      expect(overrideCalled, isTrue);
    });
  });

  group('LeaderboardPage Territory Change Gating Tests', () {
    testWidgets('clicking Change when locked triggers TerritoryLockedDialog', (
      tester,
    ) async {
      final lockedTerritory = ExplorerTerritory(
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        isHomeConfirmed: true,
        lockedAt: DateTime.now().subtract(const Duration(days: 50)),
      );

      final mockTerritoryService = _MockTerritoryService(lockedTerritory);

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardPage(
            currentUserId: 'u_tester',
            repository: _MockLeaderboardRepository(),
            territoryService: mockTerritoryService,
            initialBarangay: 'Bankal',
            initialCity: 'Lapu-Lapu City',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find "Change" buttons (in user standing card and scope bar)
      final changeFinders = find.text('Change');
      expect(changeFinders, findsWidgets);

      // Tap Change on scope bar
      await tester.tap(changeFinders.first);
      await tester.pumpAndSettle();

      // Should show Territory Locked Dialog!
      expect(find.byType(TerritoryLockedDialog), findsOneWidget);
      expect(find.text('Territory Locked'), findsOneWidget);
    });
  });
}
