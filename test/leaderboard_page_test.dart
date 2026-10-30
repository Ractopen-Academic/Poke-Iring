import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:pokeiring/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:pokeiring/features/leaderboard/presentation/widgets/podium_card.dart';
import 'package:pokeiring/features/leaderboard/presentation/widgets/user_standing_card.dart';

void main() {
  group('LeaderboardPage Widget', () {
    testWidgets('renders season banner, category tabs, podium and standing card', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LeaderboardPage(
            repository: LeaderboardRepositoryImpl(),
            currentUserId: 'test-user',
            initialBarangay: 'Bankal',
            initialCity: 'Lapu-Lapu City',
            initialRegion: 'Central Visayas',
            initialCountry: 'Philippines',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Explorer Leaderboard'), findsOneWidget);
      expect(find.text('Season 1: Sunshine Strays'), findsOneWidget);
      expect(find.text('Overall'), findsOneWidget);
      expect(find.text('Most Snapped'), findsOneWidget);
      expect(find.text('Most Walked'), findsOneWidget);

      expect(find.textContaining('Central Visayas (300)'), findsOneWidget);
      expect(find.byType(PodiumView), findsOneWidget);
      expect(find.byType(UserStandingCard), findsOneWidget);
      expect(find.textContaining('You are at Rank'), findsOneWidget);
    });

    testWidgets('switching category tab updates view', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LeaderboardPage(
            repository: LeaderboardRepositoryImpl(),
            currentUserId: 'test-user',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Most Snapped'
      await tester.tap(find.text('Most Snapped'));
      await tester.pumpAndSettle();

      expect(find.textContaining('cats'), findsWidgets);
    });
  });
}
