import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

class CalicoAmbientBackdrop extends StatelessWidget {
  final Widget child;

  const CalicoAmbientBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.92, end: 1.0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  painter: _CalicoBackdropPainter(progress: progress),
                );
              },
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CalicoBackdropPainter extends CustomPainter {
  final double progress;

  const _CalicoBackdropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final topGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.75, -0.82),
        radius: 0.95 * progress,
        colors: [
          AppColors.primary.withAlpha(42),
          AppColors.gingerSoft.withAlpha(95),
          AppColors.dynamicBackground.withAlpha(0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topGlow);

    final bottomGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.82, 0.85),
        radius: 0.85 * progress,
        colors: [
          AppColors.dynamicCalicoCharcoal.withAlpha(22),
          AppColors.dynamicCreamSurface.withAlpha(90),
          AppColors.dynamicBackground.withAlpha(0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bottomGlow);

    final marmaladePatch = Paint()
      ..color = AppColors.primary.withAlpha(24)
      ..style = PaintingStyle.fill;
    final obsidianPatch = Paint()
      ..color = AppColors.calicoBlack.withAlpha(16)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.08),
      84 * progress,
      marmaladePatch,
    );
    canvas.drawCircle(
      Offset(size.width * 0.97, size.height * 0.16),
      52 * progress,
      obsidianPatch,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.88),
      72 * progress,
      marmaladePatch,
    );
    canvas.drawCircle(
      Offset(size.width * 0.02, size.height * 0.79),
      44 * progress,
      obsidianPatch,
    );

    _drawSubtlePaw(
      canvas,
      center: Offset(size.width * 0.15, size.height * 0.15),
      scale: 1.0,
      angle: -0.35,
      color: AppColors.primary.withAlpha(26),
    );
    _drawSubtlePaw(
      canvas,
      center: Offset(size.width * 0.86, size.height * 0.82),
      scale: 1.15,
      angle: 0.28,
      color: AppColors.calicoCharcoal.withAlpha(18),
    );
  }

  void _drawSubtlePaw(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required double angle,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 13),
      paint,
    );
    canvas.drawCircle(const Offset(-9, -10), 4.0, paint);
    canvas.drawCircle(const Offset(-2.5, -13), 4.3, paint);
    canvas.drawCircle(const Offset(4.5, -12.5), 4.3, paint);
    canvas.drawCircle(const Offset(10, -8.5), 3.8, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CalicoBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class CalicoLoginMascot extends StatefulWidget {
  final bool isEmailFocused;
  final bool isPasswordFocused;
  final bool isPasswordVisible;
  final double gazeAlignment;
  final bool hasError;

  const CalicoLoginMascot({
    super.key,
    this.isEmailFocused = false,
    this.isPasswordFocused = false,
    this.isPasswordVisible = false,
    this.gazeAlignment = 0.0,
    this.hasError = false,
  });

  @override
  State<CalicoLoginMascot> createState() => _CalicoLoginMascotState();
}

class _CalicoLoginMascotState extends State<CalicoLoginMascot>
    with TickerProviderStateMixin {
  late final AnimationController _boopController;
  late final Animation<double> _boopBounce;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _boopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _boopBounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -7.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -7.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_boopController);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -6.5)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -6.5, end: 6.5)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 6.5, end: -4.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -4.0, end: 2.5)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 2.5, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 15,
      ),
    ]).animate(_shakeController);

    if (widget.hasError) {
      _triggerErrorShake();
    }
  }

  @override
  void didUpdateWidget(CalicoLoginMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _triggerErrorShake();
    }
  }

  void _triggerErrorShake() {
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _boopController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerBoop() {
    HapticFeedback.lightImpact();
    _boopController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final targetCoverLeft = widget.isPasswordFocused ? 1.0 : 0.0;
    final targetCoverRight = widget.isPasswordFocused
        ? (widget.isPasswordVisible ? 0.32 : 1.0)
        : 0.0;
    final targetGazeX = widget.isEmailFocused
        ? widget.gazeAlignment.clamp(-1.0, 1.0)
        : 0.0;
    final targetGazeY = widget.isEmailFocused ? 0.55 : 0.0;

    return GestureDetector(
      onTap: _triggerBoop,
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: targetCoverLeft),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, leftCover, _) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: targetCoverRight),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, rightCover, _) {
              return TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(end: Offset(targetGazeX, targetGazeY)),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, gaze, _) {
                  return AnimatedBuilder(
                    animation: Listenable.merge([_boopController, _shakeController]),
                    builder: (context, _) {
                      return SizedBox(
                        width: 138,
                        height: 98,
                        child: CustomPaint(
                          painter: _CalicoLoginMascotPainter(
                            leftPawCover: leftCover,
                            rightPawCover: rightCover,
                            gaze: gaze,
                            bounceOffset: _boopBounce.value,
                            shakeOffset: _shakeAnimation.value,
                            hasError: widget.hasError,
                            isHappyBoop: _boopController.isAnimating,
                            isShaking: _shakeController.isAnimating,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CalicoLoginMascotPainter extends CustomPainter {
  final double leftPawCover;
  final double rightPawCover;
  final Offset gaze;
  final double bounceOffset;
  final double shakeOffset;
  final bool hasError;
  final bool isHappyBoop;
  final bool isShaking;

  const _CalicoLoginMascotPainter({
    required this.leftPawCover,
    required this.rightPawCover,
    required this.gaze,
    required this.bounceOffset,
    required this.shakeOffset,
    required this.hasError,
    required this.isHappyBoop,
    required this.isShaking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gingerPaint = Paint()
      ..color = AppColors.mascotWarmPatch
      ..style = PaintingStyle.fill;
    final obsidianPaint = Paint()
      ..color = AppColors.mascotDarkPatch
      ..style = PaintingStyle.fill;
    final creamPaint = Paint()
      ..color = AppColors.mascotBaseFur
      ..style = PaintingStyle.fill;
    final pinkPaint = Paint()
      ..color = AppColors.calicoPink
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(shakeOffset, bounceOffset);

    // Subtle soft shadow behind head
    final headShadow = Paint()
      ..color = AppColors.calicoBlack.withAlpha(28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.58 + 3),
        width: w * 0.64,
        height: h * 0.66,
      ),
      headShadow,
    );

    // Left Ear (Obsidian Calico)
    final earTilt = isHappyBoop
        ? -2.5
        : (isShaking ? 3.0 : (hasError ? 1.5 : 0.0));
    final leftEar = Path()
      ..moveTo(w * 0.23, h * 0.44)
      ..lineTo(w * 0.16, h * 0.10 + earTilt)
      ..lineTo(w * 0.41, h * 0.25)
      ..close();
    canvas.drawPath(leftEar, obsidianPaint);
    canvas.drawPath(leftEar, outlinePaint);

    final leftInnerEar = Path()
      ..moveTo(w * 0.25, h * 0.39)
      ..lineTo(w * 0.20, h * 0.17 + earTilt)
      ..lineTo(w * 0.36, h * 0.27)
      ..close();
    canvas.drawPath(leftInnerEar, pinkPaint);

    // Right Ear (Marmalade Ginger)
    final rightEar = Path()
      ..moveTo(w * 0.77, h * 0.44)
      ..lineTo(w * 0.84, h * 0.10 + earTilt)
      ..lineTo(w * 0.59, h * 0.25)
      ..close();
    canvas.drawPath(rightEar, gingerPaint);
    canvas.drawPath(rightEar, outlinePaint);

    final rightInnerEar = Path()
      ..moveTo(w * 0.75, h * 0.39)
      ..lineTo(w * 0.80, h * 0.17 + earTilt)
      ..lineTo(w * 0.64, h * 0.27)
      ..close();
    canvas.drawPath(rightInnerEar, pinkPaint);

    // Head Base + Tri-color Calico Fur Patches
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.58),
      width: w * 0.66,
      height: h * 0.68,
    );
    final headPath = Path()..addOval(headRect);
    canvas.drawPath(headPath, creamPaint);

    canvas.save();
    canvas.clipPath(headPath);
    canvas.drawCircle(Offset(w * 0.27, h * 0.38), w * 0.21, obsidianPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.40), w * 0.22, gingerPaint);
    canvas.drawCircle(
      Offset(w * 0.68, h * 0.27),
      w * 0.11,
      Paint()..color = AppColors.primaryDark.withAlpha(150),
    );
    canvas.restore();

    canvas.drawPath(headPath, outlinePaint);

    // Warm Rosy Cheeks
    final blushPaint = Paint()
      ..color = AppColors.calicoPink.withAlpha(110)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.31, h * 0.65), width: 13, height: 7),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.69, h * 0.65), width: 13, height: 7),
      blushPaint,
    );

    // Expressive Eyes (track email cursor or squint happily on boop)
    final leftEyeCenter = Offset(w * 0.39, h * 0.55);
    final rightEyeCenter = Offset(w * 0.61, h * 0.55);

    if (isHappyBoop) {
      final squintPaint = Paint()
        ..color = AppColors.calicoBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final leftArc = Path()
        ..moveTo(leftEyeCenter.dx - 6, leftEyeCenter.dy + 1)
        ..quadraticBezierTo(
          leftEyeCenter.dx,
          leftEyeCenter.dy - 6,
          leftEyeCenter.dx + 6,
          leftEyeCenter.dy + 1,
        );
      final rightArc = Path()
        ..moveTo(rightEyeCenter.dx - 6, rightEyeCenter.dy + 1)
        ..quadraticBezierTo(
          rightEyeCenter.dx,
          rightEyeCenter.dy - 6,
          rightEyeCenter.dx + 6,
          rightEyeCenter.dy + 1,
        );
      canvas.drawPath(leftArc, squintPaint);
      canvas.drawPath(rightArc, squintPaint);
    } else {
      _drawExpressiveEye(
        canvas,
        leftEyeCenter,
        gaze,
        isTroubled: hasError || isShaking,
      );
      _drawExpressiveEye(
        canvas,
        rightEyeCenter,
        gaze,
        isTroubled: hasError || isShaking,
      );
    }

    // Pink Nose & Cat Mouth
    final nosePath = Path()
      ..moveTo(w * 0.50, h * 0.65)
      ..lineTo(w * 0.465, h * 0.61)
      ..lineTo(w * 0.535, h * 0.61)
      ..close();
    canvas.drawPath(
      nosePath,
      Paint()
        ..color = const Color(0xFFE57373)
        ..style = PaintingStyle.fill,
    );

    final mouthPaint = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    if (hasError || isShaking) {
      final frown = Path()
        ..moveTo(w * 0.45, h * 0.70)
        ..quadraticBezierTo(w * 0.50, h * 0.67, w * 0.55, h * 0.70);
      canvas.drawPath(frown, mouthPaint);

      // Flustered sweat drop on temple
      final sweatPaint = Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.fill;
      final sweatOutline = Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      final sweatPath = Path()
        ..moveTo(w * 0.77, h * 0.44)
        ..quadraticBezierTo(w * 0.79, h * 0.47, w * 0.77, h * 0.50)
        ..arcToPoint(
          Offset(w * 0.75, h * 0.50),
          radius: const Radius.circular(1.5),
        )
        ..quadraticBezierTo(w * 0.75, h * 0.47, w * 0.77, h * 0.44);
      canvas.drawPath(sweatPath, sweatPaint);
      canvas.drawPath(sweatPath, sweatOutline);
    } else {
      final smile = Path()
        ..moveTo(w * 0.435, h * 0.675)
        ..quadraticBezierTo(w * 0.47, h * 0.715, w * 0.50, h * 0.665)
        ..quadraticBezierTo(w * 0.53, h * 0.715, w * 0.565, h * 0.675);
      canvas.drawPath(smile, mouthPaint);
    }

    // Whiskers
    final whiskerDroop = (hasError || isShaking) ? 2.0 : 0.0;
    final whiskerPaint = Paint()
      ..color = AppColors.calicoCharcoal.withAlpha(170)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.14, h * 0.59 + whiskerDroop),
      Offset(w * 0.27, h * 0.61),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.15, h * 0.66 + whiskerDroop),
      Offset(w * 0.27, h * 0.65),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.86, h * 0.59 + whiskerDroop),
      Offset(w * 0.73, h * 0.61),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.85, h * 0.66 + whiskerDroop),
      Offset(w * 0.73, h * 0.65),
      whiskerPaint,
    );

    canvas.restore();

    // Paws: rest along card rim at bottom, or lift to cover eyes on password!
    _drawInteractivePaw(
      canvas,
      size: size,
      restCenter: Offset(w * 0.30, h * 0.91),
      coverCenter: Offset(w * 0.39 + shakeOffset, h * 0.55 + bounceOffset),
      progress: leftPawCover,
      patchColor: AppColors.calicoBlack,
      isLeft: true,
    );
    _drawInteractivePaw(
      canvas,
      size: size,
      restCenter: Offset(w * 0.70, h * 0.91),
      coverCenter: Offset(w * 0.61 + shakeOffset, h * 0.55 + bounceOffset),
      progress: rightPawCover,
      patchColor: AppColors.primary,
      isLeft: false,
    );
  }

  void _drawExpressiveEye(
    Canvas canvas,
    Offset center,
    Offset gazeOffset, {
    bool isTroubled = false,
  }) {
    final scleraPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final irisPaint = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.fill;
    final amberRing = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 7.2, scleraPaint);
    canvas.drawCircle(
      center,
      7.2,
      Paint()
        ..color = AppColors.calicoCharcoal.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (isTroubled) {
      // Worried brow angled outward
      final browPaint = Paint()
        ..color = AppColors.calicoCharcoal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      final isLeft = center.dx < 70;
      if (isLeft) {
        canvas.drawLine(
          Offset(center.dx - 5, center.dy - 9.5),
          Offset(center.dx + 4, center.dy - 11.0),
          browPaint,
        );
      } else {
        canvas.drawLine(
          Offset(center.dx - 4, center.dy - 11.0),
          Offset(center.dx + 5, center.dy - 9.5),
          browPaint,
        );
      }
    }

    final pupilRadius = isTroubled ? 3.4 : 4.4;
    final pupilCenter = Offset(
      center.dx + (gazeOffset.dx * 2.4),
      center.dy + (gazeOffset.dy * 1.8),
    );
    canvas.drawCircle(pupilCenter, pupilRadius, irisPaint);
    canvas.drawCircle(pupilCenter, pupilRadius, amberRing);
    canvas.drawCircle(
      Offset(pupilCenter.dx - 1.2, pupilCenter.dy - 1.2),
      isTroubled ? 1.1 : 1.5,
      glintPaint,
    );
  }

  void _drawInteractivePaw(
    Canvas canvas, {
    required Size size,
    required Offset restCenter,
    required Offset coverCenter,
    required double progress,
    required Color patchColor,
    required bool isLeft,
  }) {
    final current = Offset.lerp(restCenter, coverCenter, progress)!;
    final width = 26.0 + (4.0 * progress);
    final height = 18.0 + (10.0 * progress);
    final angle = (isLeft ? 0.34 : -0.34) * progress * math.pi * 0.45;

    final creamPaint = Paint()
      ..color = AppColors.mascotBaseFur
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final beanPaint = Paint()
      ..color = AppColors.calicoPink
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(current.dx, current.dy);
    canvas.rotate(angle);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width * 0.48));
    canvas.drawRRect(rrect, creamPaint);

    // Calico patch on outer edge of paw
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawCircle(
      Offset(isLeft ? -width * 0.28 : width * 0.28, -height * 0.15),
      width * 0.36,
      Paint()..color = patchColor,
    );
    canvas.restore();

    canvas.drawRRect(rrect, outlinePaint);

    // Show cute pink toe beans when lifting paw to cover eyes
    if (progress > 0.18) {
      final beanAlpha = ((progress - 0.18) / 0.82 * 235).clamp(0, 235).round();
      final activeBean = Paint()..color = beanPaint.color.withAlpha(beanAlpha);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 3), width: 8, height: 5.5),
        activeBean,
      );
      canvas.drawCircle(const Offset(-5.5, -3.5), 2.1, activeBean);
      canvas.drawCircle(const Offset(0, -5.0), 2.2, activeBean);
      canvas.drawCircle(const Offset(5.5, -3.5), 2.1, activeBean);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CalicoLoginMascotPainter oldDelegate) {
    return oldDelegate.leftPawCover != leftPawCover ||
        oldDelegate.rightPawCover != rightPawCover ||
        oldDelegate.gaze != gaze ||
        oldDelegate.bounceOffset != bounceOffset ||
        oldDelegate.shakeOffset != shakeOffset ||
        oldDelegate.hasError != hasError ||
        oldDelegate.isHappyBoop != isHappyBoop ||
        oldDelegate.isShaking != isShaking;
  }
}
