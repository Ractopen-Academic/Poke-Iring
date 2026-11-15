import 'dart:math';

enum FlappyGameStatus { ready, playing, gameOver }

enum FlappyStepEvent { none, scored, crashed }

class FlappyPipe {
  double x;
  final double gapCenterY;
  final double gapHeight;
  final double width;
  bool passed;

  FlappyPipe({
    required this.x,
    required this.gapCenterY,
    required this.gapHeight,
    required this.width,
    this.passed = false,
  });

  double get topPipeBottom => gapCenterY - (gapHeight / 2);
  double get bottomPipeTop => gapCenterY + (gapHeight / 2);
}

/// Pure-Dart physics and scoring engine for the Flappy Cat mini-game.
///
/// Uses normalized coordinates where vertical `0.0` is the top of the sky
/// and `1.0` is the bottom of the playfield (including [groundHeight]).
class FlappyCatEngine {
  static const double catX = 0.28;
  static const double catRadius = 0.036;
  static const double gravity = 1.65;
  static const double flapVelocity = -0.54;
  static const double maxFallSpeed = 0.95;
  static const double pipeSpeed = 0.34;
  static const double pipeWidth = 0.13;
  static const double pipeGap = 0.27;
  static const double pipeSpacing = 0.56;
  static const double groundHeight = 0.10;
  static const int pointsPerPipe = 2;
  static const int newBestBonusPoints = 5;
  static const int newBestMinScore = 3;

  final Random _random;

  FlappyGameStatus status = FlappyGameStatus.ready;
  double catY = 0.44;
  double catVelocity = 0.0;
  double groundOffset = 0.0;
  double idleTime = 0.0;
  int score = 0;
  final List<FlappyPipe> pipes = [];

  FlappyCatEngine({Random? random}) : _random = random ?? Random();

  double get playfieldBottom => 1.0 - groundHeight;

  /// Resets the engine back to the ready state.
  void reset() {
    status = FlappyGameStatus.ready;
    catY = 0.44;
    catVelocity = 0.0;
    idleTime = 0.0;
    score = 0;
    pipes.clear();
  }

  /// Applies an upward flap impulse; starts the run if currently ready.
  void flap() {
    if (status == FlappyGameStatus.gameOver) return;
    if (status == FlappyGameStatus.ready) {
      status = FlappyGameStatus.playing;
    }
    catVelocity = flapVelocity;
  }

  /// Advances simulation by [rawDt] seconds.
  FlappyStepEvent step(double rawDt, {double? nextGapY}) {
    final dt = rawDt.clamp(0.0, 0.05);
    if (dt <= 0) return FlappyStepEvent.none;

    if (status == FlappyGameStatus.ready) {
      idleTime += dt;
      catY = 0.44 + sin(idleTime * 4.0) * 0.018;
      groundOffset = (groundOffset + pipeSpeed * dt) % 1.0;
      return FlappyStepEvent.none;
    }

    if (status != FlappyGameStatus.playing) {
      return FlappyStepEvent.none;
    }

    // Physics integration
    catVelocity = (catVelocity + gravity * dt).clamp(-1.2, maxFallSpeed);
    catY += catVelocity * dt;
    groundOffset = (groundOffset + pipeSpeed * dt) % 1.0;

    // Gentle ceiling clamp so tapping near the top feels fair
    if (catY - catRadius < 0.0) {
      catY = catRadius;
      if (catVelocity < 0) catVelocity = 0;
    }

    // Spawn pipes at consistent horizontal intervals
    if (pipes.isEmpty || (1.08 - pipes.last.x) >= pipeSpacing) {
      final minCenter = 0.14 + (pipeGap / 2);
      final maxCenter = playfieldBottom - 0.14 - (pipeGap / 2);
      final gapY =
          nextGapY ??
          (minCenter + _random.nextDouble() * (maxCenter - minCenter));
      pipes.add(
        FlappyPipe(
          x: 1.08,
          gapCenterY: gapY.clamp(minCenter, maxCenter),
          gapHeight: pipeGap,
          width: pipeWidth,
        ),
      );
    }

    var scoredThisStep = false;
    for (final pipe in pipes) {
      pipe.x -= pipeSpeed * dt;
      if (!pipe.passed && (pipe.x + pipe.width) < catX) {
        pipe.passed = true;
        score += 1;
        scoredThisStep = true;
      }
    }

    pipes.removeWhere((p) => (p.x + p.width) < -0.15);

    // Ground collision
    if (catY + catRadius >= playfieldBottom) {
      catY = playfieldBottom - catRadius;
      status = FlappyGameStatus.gameOver;
      return FlappyStepEvent.crashed;
    }

    // Pipe collision (slightly forgiving hitbox)
    final hitRadius = catRadius * 0.82;
    for (final pipe in pipes) {
      if (_circleIntersectsRect(
            cx: catX,
            cy: catY,
            r: hitRadius,
            left: pipe.x,
            top: 0.0,
            right: pipe.x + pipe.width,
            bottom: pipe.topPipeBottom,
          ) ||
          _circleIntersectsRect(
            cx: catX,
            cy: catY,
            r: hitRadius,
            left: pipe.x,
            top: pipe.bottomPipeTop,
            right: pipe.x + pipe.width,
            bottom: playfieldBottom,
          )) {
        status = FlappyGameStatus.gameOver;
        return FlappyStepEvent.crashed;
      }
    }

    return scoredThisStep ? FlappyStepEvent.scored : FlappyStepEvent.none;
  }

  /// Calculates Paw Points earned for a completed run.
  static int calculateEarnedPoints({
    required int score,
    required bool isNewBest,
  }) {
    if (score <= 0) return 0;
    final base = score * pointsPerPipe;
    final bonus = (isNewBest && score >= newBestMinScore)
        ? newBestBonusPoints
        : 0;
    return base + bonus;
  }

  static bool _circleIntersectsRect({
    required double cx,
    required double cy,
    required double r,
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final closestX = cx.clamp(left, right);
    final closestY = cy.clamp(top, bottom);
    final dx = cx - closestX;
    final dy = cy - closestY;
    return (dx * dx + dy * dy) < (r * r);
  }
}
