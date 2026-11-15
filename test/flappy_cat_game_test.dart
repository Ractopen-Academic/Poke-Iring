import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/games/domain/flappy_cat_engine.dart';
import 'package:pokeiring/features/games/presentation/pages/flappy_cat_game_page.dart';
import 'package:pokeiring/features/games/presentation/pages/games_hub_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FlappyCatEngine', () {
    test('starts ready, flaps to playing, and applies upward velocity', () {
      final engine = FlappyCatEngine(random: Random(42));
      expect(engine.status, FlappyGameStatus.ready);
      expect(engine.score, 0);

      engine.flap();
      expect(engine.status, FlappyGameStatus.playing);
      expect(engine.catVelocity, FlappyCatEngine.flapVelocity);
    });

    test('increments score when passing a pipe', () {
      final engine = FlappyCatEngine(random: Random(42));
      engine.flap();
      // Place a pipe just ahead of the cat with gap centered at catY
      engine.pipes.add(
        FlappyPipe(
          x: FlappyCatEngine.catX - 0.05,
          gapCenterY: engine.catY,
          gapHeight: 0.40,
          width: 0.10,
        ),
      );

      // Step enough for the pipe to pass catX
      var scored = false;
      for (var i = 0; i < 15; i++) {
        engine.catVelocity = 0; // keep cat steady inside gap
        final event = engine.step(0.03, nextGapY: 0.5);
        if (event == FlappyStepEvent.scored) {
          scored = true;
          break;
        }
      }

      expect(scored, isTrue);
      expect(engine.score, 1);
    });

    test('crashes when hitting the ground', () {
      final engine = FlappyCatEngine(random: Random(42));
      engine.flap();
      engine.catY = engine.playfieldBottom - FlappyCatEngine.catRadius - 0.001;
      engine.catVelocity = 0.5;

      final event = engine.step(0.04, nextGapY: 0.5);
      expect(event, FlappyStepEvent.crashed);
      expect(engine.status, FlappyGameStatus.gameOver);
    });

    test('crashes when colliding with a pipe', () {
      final engine = FlappyCatEngine(random: Random(42));
      engine.flap();
      engine.catY = 0.10; // high up in the top pipe zone
      engine.catVelocity = 0.0;
      engine.pipes.add(
        FlappyPipe(
          x: FlappyCatEngine.catX - 0.02,
          gapCenterY: 0.60,
          gapHeight: 0.24,
          width: 0.13,
        ),
      );

      final event = engine.step(0.02);
      expect(event, FlappyStepEvent.crashed);
      expect(engine.status, FlappyGameStatus.gameOver);
    });

    test('calculates Paw Points with new best bonus', () {
      expect(
        FlappyCatEngine.calculateEarnedPoints(score: 0, isNewBest: true),
        0,
      );
      expect(
        FlappyCatEngine.calculateEarnedPoints(score: 2, isNewBest: true),
        4,
      );
      expect(
        FlappyCatEngine.calculateEarnedPoints(score: 3, isNewBest: false),
        6,
      );
      expect(
        FlappyCatEngine.calculateEarnedPoints(score: 3, isNewBest: true),
        11,
      );
    });
  });

  group('FlappyCat UI', () {
    const testUser = AuthUser(
      id: 'test-cat-user',
      email: 'cat@example.com',
      displayName: 'Test Cat',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('GamesHubPage renders Flappy Cat and Reyal or Pake?', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: GamesHubPage(user: testUser)),
      );
      await tester.pump();

      expect(find.text('Cat Arcade'), findsOneWidget);
      expect(find.text('Flappy Cat'), findsOneWidget);
      expect(find.text('Reyal or Pake?'), findsOneWidget);
    });

    testWidgets('FlappyCatGamePage renders ready state and starts on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: FlappyCatGamePage(user: testUser)),
      );
      await tester.pump();

      expect(find.text('Flappy Cat'), findsOneWidget);
      expect(find.text('Tap Anywhere to Flap'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Tap Anywhere to Flap'), findsNothing);
    });
  });
}
