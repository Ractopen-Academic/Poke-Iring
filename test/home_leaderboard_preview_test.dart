import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/leaderboard/presentation/widgets/home_leaderboard_preview.dart';

void main() {
  group('HomeLeaderboardPreview Widget', () {
    testWidgets('renders top 3 champions and triggers onTap callback', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeLeaderboardPreview(
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Territory Champions'), findsOneWidget);
      expect(find.text('View Ranks'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);

      await tester.tap(find.text('Territory Champions'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
