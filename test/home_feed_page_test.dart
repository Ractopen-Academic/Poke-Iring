import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/home/presentation/pages/home_feed_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = AuthUser(
    id: 'test-home-user',
    email: 'calico@pokeiring.ph',
    displayName: 'AmberPaws',
    photoUrl: '',
    emailVerified: true,
  );

  group('HomeFeedPage Presentation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders explorer greeting, health metrics, and section titles', (
      tester,
    ) async {
      bool leaderboardOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeFeedPage(
            user: testUser,
            onOpenLeaderboard: () {
              leaderboardOpened = true;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Welcome back,'), findsOneWidget);
      expect(find.text('AmberPaws'), findsOneWidget);
      expect(find.text('Explorer Health'), findsOneWidget);
      expect(find.text('STEPS'), findsOneWidget);
      expect(find.text('DISTANCE'), findsOneWidget);
      expect(find.text('CALORIES'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      final championWidget = find.text('Territory Champions');
      if (championWidget.evaluate().isNotEmpty) {
        await tester.tap(championWidget);
        expect(leaderboardOpened, isTrue);
      }
    });
  });
}
