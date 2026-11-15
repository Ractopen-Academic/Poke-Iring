import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_haptic_service.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../rewards/services/rewards_service.dart';
import '../../domain/flappy_cat_engine.dart';

class FlappyCatGamePage extends StatefulWidget {
  final AuthUser user;

  const FlappyCatGamePage({super.key, required this.user});

  static Future<void> navigate(BuildContext context, {required AuthUser user}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FlappyCatGamePage(user: user)),
    );
  }

  @override
  State<FlappyCatGamePage> createState() => _FlappyCatGamePageState();
}

class _FlappyCatGamePageState extends State<FlappyCatGamePage>
    with SingleTickerProviderStateMixin {
  final FlappyCatEngine _engine = FlappyCatEngine();
  final FocusNode _focusNode = FocusNode();

  late final Ticker _ticker;
  Duration? _lastElapsed;

  int _bestScore = 0;
  int _lastEarnedPoints = 0;
  int _sessionEarnedPoints = 0;
  bool _isNewBest = false;

  String get _userId =>
      widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

  String get _bestScoreKey => 'flappy_cat_best_score_$_userId';

  @override
  void initState() {
    super.initState();
    RewardsService.instance.syncUserPoints(_userId);
    unawaited(_loadBestScore());
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_bestScoreKey) ?? 0;
      if (mounted) {
        setState(() => _bestScore = saved);
      }
    } catch (_) {}
  }

  Future<void> _saveBestScore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestScoreKey, score);
    } catch (_) {}
  }

  void _onTick(Duration elapsed) {
    final prev = _lastElapsed;
    _lastElapsed = elapsed;
    if (prev == null) return;

    final dt = (elapsed - prev).inMicroseconds / 1000000.0;
    final event = _engine.step(dt);

    if (event == FlappyStepEvent.scored) {
      unawaited(AudioHapticService.instance.boopPin());
    } else if (event == FlappyStepEvent.crashed) {
      _handleGameOver();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleFlap() {
    if (_engine.status == FlappyGameStatus.gameOver) return;
    _engine.flap();
    unawaited(AudioHapticService.instance.boopPin());
    if (mounted) {
      setState(() {});
    }
  }

  void _handleGameOver() {
    unawaited(AudioHapticService.instance.tierUp());

    final runScore = _engine.score;
    final beatBest = runScore > _bestScore;
    final earned = FlappyCatEngine.calculateEarnedPoints(
      score: runScore,
      isNewBest: beatBest,
    );

    if (beatBest) {
      _bestScore = runScore;
      unawaited(_saveBestScore(runScore));
    }

    _isNewBest = beatBest && runScore >= FlappyCatEngine.newBestMinScore;
    _lastEarnedPoints = earned;
    _sessionEarnedPoints += earned;

    if (earned > 0) {
      unawaited(
        RewardsService.instance.addPoints(
          _userId,
          earned,
          'Flappy Cat Mini-Game (Score: $runScore)',
        ),
      );
    }
  }

  void _restartGame() {
    _lastEarnedPoints = 0;
    _isNewBest = false;
    _engine.reset();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isCalicoDark;

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        title: const Text(
          'Flappy Cat',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: RewardsService.instance.pointsNotifier,
                builder: (context, totalPoints, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$totalPoints pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.arrowUp)) {
              if (_engine.status == FlappyGameStatus.gameOver) {
                _restartGame();
              } else {
                _handleFlap();
              }
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _handleFlap(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _FlappyCatPainter(engine: _engine, isDark: isDark),
                ),

                // Top HUD: Best Score + Session Earned
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HudPill(
                          icon: Icons.emoji_events_rounded,
                          label: 'Best: $_bestScore',
                          isDark: isDark,
                        ),
                        if (_sessionEarnedPoints > 0)
                          _HudPill(
                            icon: Icons.add_circle_outline_rounded,
                            label: '+$_sessionEarnedPoints session pts',
                            isDark: isDark,
                            accent: true,
                          ),
                      ],
                    ),
                  ),
                ),

                // Live Score Display
                if (_engine.status == FlappyGameStatus.playing)
                  Positioned(
                    top: 54,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Text(
                          '${_engine.score}',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFFF7EFE8)
                                : const Color(0xFF26201D),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                offset: const Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Ready Overlay
                if (_engine.status == FlappyGameStatus.ready)
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: 110,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dynamicSurface.withValues(
                            alpha: 0.92,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.dynamicBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Tap Anywhere to Flap',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Glide past scratching posts to earn +${FlappyCatEngine.pointsPerPipe} Paw Points each.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.dynamicTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Game Over Overlay
                if (_engine.status == FlappyGameStatus.gameOver)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.32),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.pets_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cat Nap Time!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dynamicTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (_isNewBest) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEW PERSONAL BEST (+5 BONUS)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatColumn(
                                label: 'Score',
                                value: '${_engine.score}',
                              ),
                              Container(
                                width: 1,
                                height: 34,
                                color: AppColors.dynamicBorder,
                              ),
                              _StatColumn(label: 'Best', value: '$_bestScore'),
                              Container(
                                width: 1,
                                height: 34,
                                color: AppColors.dynamicBorder,
                              ),
                              _StatColumn(
                                label: 'Earned',
                                value: '+$_lastEarnedPoints',
                                highlight: _lastEarnedPoints > 0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _restartGame,
                              icon: const Icon(Icons.replay_rounded),
                              label: const Text(
                                'Play Again',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Back to Games',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dynamicTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool accent;

  const _HudPill({
    required this.icon,
    required this.label,
    required this.isDark,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.dynamicBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: accent ? AppColors.primary : AppColors.dynamicTextSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent ? AppColors.primary : AppColors.dynamicTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatColumn({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: highlight ? AppColors.primary : AppColors.dynamicTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _FlappyCatPainter extends CustomPainter {
  final FlappyCatEngine engine;
  final bool isDark;

  _FlappyCatPainter({required this.engine, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawPipes(canvas, size);
    _drawGround(canvas, size);
    _drawCat(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final skyColors = isDark
        ? const [Color(0xFF181513), Color(0xFF2B211C)]
        : const [Color(0xFFFFF4E6), Color(0xFFFFDFC2)];

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Subtle drifting clouds / moonlit puffs
    final cloudPaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primary).withValues(
        alpha: isDark ? 0.05 : 0.10,
      );
    final drift = (engine.groundOffset * 0.25) % 1.0;
    for (var i = 0; i < 4; i++) {
      final cx = (((i * 0.34) - drift) % 1.3 - 0.15) * size.width;
      final cy = (0.14 + (i % 2) * 0.11) * size.height;
      canvas.drawCircle(Offset(cx, cy), 26, cloudPaint);
      canvas.drawCircle(Offset(cx + 22, cy + 4), 20, cloudPaint);
      canvas.drawCircle(Offset(cx - 20, cy + 6), 18, cloudPaint);
    }
  }

  void _drawPipes(Canvas canvas, Size size) {
    final playBottomPx = engine.playfieldBottom * size.height;

    final postFill = Paint()
      ..color = isDark ? const Color(0xFF8C5A32) : const Color(0xFFC68B59);
    final postStripe = Paint()
      ..color = isDark ? const Color(0xFF704523) : const Color(0xFFA97142)
      ..strokeWidth = 2.0;
    final capFill = Paint()
      ..color = isDark ? const Color(0xFFE06D22) : const Color(0xFFD4621A);
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF181513) : const Color(0xFF4A2E16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final pipe in engine.pipes) {
      final left = pipe.x * size.width;
      final width = pipe.width * size.width;
      final topBottom = pipe.topPipeBottom * size.height;
      final bottomTop = pipe.bottomPipeTop * size.height;

      // Top scratching post
      if (topBottom > 0) {
        final topRect = Rect.fromLTWH(left, 0, width, topBottom);
        canvas.drawRect(topRect, postFill);
        _drawRopeStripes(canvas, topRect, postStripe);
        canvas.drawRect(topRect, borderPaint);

        final capHeight = math.min(20.0, topBottom);
        final topCap = RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 4, topBottom - capHeight, width + 8, capHeight),
          const Radius.circular(6),
        );
        canvas.drawRRect(topCap, capFill);
        canvas.drawRRect(topCap, borderPaint);
      }

      // Bottom scratching post
      if (bottomTop < playBottomPx) {
        final bottomHeight = playBottomPx - bottomTop;
        final bottomRect = Rect.fromLTWH(left, bottomTop, width, bottomHeight);
        canvas.drawRect(bottomRect, postFill);
        _drawRopeStripes(canvas, bottomRect, postStripe);
        canvas.drawRect(bottomRect, borderPaint);

        final capHeight = math.min(20.0, bottomHeight);
        final bottomCap = RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 4, bottomTop, width + 8, capHeight),
          const Radius.circular(6),
        );
        canvas.drawRRect(bottomCap, capFill);
        canvas.drawRRect(bottomCap, borderPaint);
      }
    }
  }

  void _drawRopeStripes(Canvas canvas, Rect rect, Paint paint) {
    for (var y = rect.top + 10; y < rect.bottom - 10; y += 12) {
      canvas.drawLine(Offset(rect.left + 2, y), Offset(rect.right - 2, y), paint);
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    final top = engine.playfieldBottom * size.height;
    final groundHeight = size.height - top;

    final turfPaint = Paint()
      ..color = isDark ? const Color(0xFF352B25) : const Color(0xFFE06D22);
    final earthPaint = Paint()
      ..color = isDark ? const Color(0xFF241E1A) : const Color(0xFF8C5A32);

    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, groundHeight),
      earthPaint,
    );
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, 14), turfPaint);

    // Scrolling tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.25)
      ..strokeWidth = 3;
    const spacing = 36.0;
    final offsetPx = (engine.groundOffset * size.width) % spacing;
    for (var x = -offsetPx; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, top + 3), Offset(x + 12, top + 11), tickPaint);
    }
  }

  void _drawCat(Canvas canvas, Size size) {
    final cx = FlappyCatEngine.catX * size.width;
    final cy = engine.catY * size.height;
    final r = FlappyCatEngine.catRadius * size.height;

    // Velocity-based pitch angle
    final angle = (engine.catVelocity * 0.75).clamp(-0.45, 0.75);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final furPaint = Paint()..color = const Color(0xFFF7EFE8);
    final orangePatch = Paint()..color = const Color(0xFFE06D22);
    final darkPatch = Paint()..color = const Color(0xFF26201D);
    final outlinePaint = Paint()
      ..color = const Color(0xFF26201D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Little tail wagging behind
    final tailPath = Path()
      ..moveTo(-r * 0.85, r * 0.1)
      ..quadraticBezierTo(-r * 1.45, -r * 0.35, -r * 1.25, -r * 0.75);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = const Color(0xFFE06D22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.28
        ..strokeCap = StrokeCap.round,
    );

    // Ears
    final leftEar = Path()
      ..moveTo(-r * 0.68, -r * 0.42)
      ..lineTo(-r * 0.82, -r * 1.15)
      ..lineTo(-r * 0.18, -r * 0.78)
      ..close();
    final rightEar = Path()
      ..moveTo(r * 0.18, -r * 0.78)
      ..lineTo(r * 0.72, -r * 1.15)
      ..lineTo(r * 0.68, -r * 0.42)
      ..close();

    canvas.drawPath(leftEar, orangePatch);
    canvas.drawPath(leftEar, outlinePaint);
    canvas.drawPath(rightEar, darkPatch);
    canvas.drawPath(rightEar, outlinePaint);

    // Head / body circle
    canvas.drawCircle(Offset.zero, r, furPaint);

    // Calico patch on forehead
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.drawCircle(Offset(-r * 0.45, -r * 0.55), r * 0.55, orangePatch);
    canvas.drawCircle(Offset(r * 0.55, -r * 0.45), r * 0.45, darkPatch);
    canvas.restore();

    canvas.drawCircle(Offset.zero, r, outlinePaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF181513);
    if (engine.status == FlappyGameStatus.gameOver) {
      // Dizzy X eyes
      final xPaint = Paint()
        ..color = const Color(0xFF181513)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      for (final ex in [-r * 0.22, r * 0.34]) {
        canvas.drawLine(
          Offset(ex - 3, -r * 0.18),
          Offset(ex + 3, -r * 0.02),
          xPaint,
        );
        canvas.drawLine(
          Offset(ex + 3, -r * 0.18),
          Offset(ex - 3, -r * 0.02),
          xPaint,
        );
      }
    } else {
      canvas.drawCircle(Offset(-r * 0.22, -r * 0.1), r * 0.13, eyePaint);
      canvas.drawCircle(Offset(r * 0.34, -r * 0.1), r * 0.13, eyePaint);
      final shine = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(-r * 0.25, -r * 0.14), r * 0.045, shine);
      canvas.drawCircle(Offset(r * 0.31, -r * 0.14), r * 0.045, shine);
    }

    // Pink nose
    canvas.drawCircle(
      Offset(r * 0.08, r * 0.14),
      r * 0.10,
      Paint()..color = const Color(0xFFFFB4BE),
    );

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF26201D)
      ..strokeWidth = 1.3;
    canvas.drawLine(
      Offset(-r * 0.52, r * 0.12),
      Offset(-r * 0.98, r * 0.04),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(-r * 0.52, r * 0.24),
      Offset(-r * 0.96, r * 0.28),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(r * 0.56, r * 0.12),
      Offset(r * 1.02, r * 0.04),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(r * 0.56, r * 0.24),
      Offset(r * 1.00, r * 0.28),
      whiskerPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlappyCatPainter oldDelegate) => true;
}
