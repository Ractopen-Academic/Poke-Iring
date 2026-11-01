import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

class PeekingCatRecenterButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isOffCenter;

  const PeekingCatRecenterButton({
    super.key,
    required this.onTap,
    this.isOffCenter = false,
  });

  @override
  State<PeekingCatRecenterButton> createState() =>
      _PeekingCatRecenterButtonState();
}

class _PeekingCatRecenterButtonState extends State<PeekingCatRecenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _peekAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    _peekAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -9.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -9.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_bounceController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.13,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.13,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant PeekingCatRecenterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOffCenter != oldWidget.isOffCenter) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: widget.isOffCenter ? -4.5 : 0.0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        builder: (context, restingLift, _) {
          return AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: SizedBox(
                  width: 58,
                  height: 66,
                  child: CustomPaint(
                    painter: _PeekingCalicoCatPainter(
                      peekOffset: restingLift + _peekAnimation.value,
                      isAlert: widget.isOffCenter,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PeekingCalicoCatPainter extends CustomPainter {
  final double peekOffset;
  final bool isAlert;

  const _PeekingCalicoCatPainter({
    required this.peekOffset,
    required this.isAlert,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadowPaint = Paint()
      ..color = AppColors.calicoBlack.withAlpha(65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.37 + 3, w * 0.76, h * 0.56),
        const Radius.circular(16),
      ),
      shadowPaint,
    );

    canvas.save();
    canvas.translate(0, peekOffset);

    final gingerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final obsidianPaint = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.fill;
    final creamPaint = Paint()
      ..color = const Color(0xFFFFFAF4)
      ..style = PaintingStyle.fill;
    final headOutline = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final creamHaloOutline = Paint()
      ..color = const Color(0xFFFFFAF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;

    // Left Ear (Obsidian Calico)
    final leftEar = Path()
      ..moveTo(w * 0.25, h * 0.29)
      ..lineTo(w * 0.19, h * 0.09)
      ..lineTo(w * 0.38, h * 0.19)
      ..close();
    canvas.drawPath(leftEar, creamHaloOutline);
    canvas.drawPath(leftEar, obsidianPaint);

    // Right Ear (Marmalade Ginger)
    final rightEar = Path()
      ..moveTo(w * 0.75, h * 0.29)
      ..lineTo(w * 0.81, h * 0.09)
      ..lineTo(w * 0.62, h * 0.19)
      ..close();
    canvas.drawPath(rightEar, creamHaloOutline);
    canvas.drawPath(rightEar, gingerPaint);

    final pinkPaint = Paint()
      ..color = AppColors.calicoPink
      ..style = PaintingStyle.fill;

    final innerLeftEar = Path()
      ..moveTo(w * 0.26, h * 0.26)
      ..lineTo(w * 0.22, h * 0.13)
      ..lineTo(w * 0.34, h * 0.20)
      ..close();
    canvas.drawPath(innerLeftEar, pinkPaint);

    final innerRightEar = Path()
      ..moveTo(w * 0.74, h * 0.26)
      ..lineTo(w * 0.78, h * 0.13)
      ..lineTo(w * 0.66, h * 0.20)
      ..close();
    canvas.drawPath(innerRightEar, pinkPaint);

    // Calico Head Base + Tri-Color Spots
    final headCircle = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.50, h * 0.31), radius: w * 0.26),
      );
    canvas.drawPath(headCircle, creamPaint);

    canvas.save();
    canvas.clipPath(headCircle);
    canvas.drawCircle(Offset(w * 0.32, h * 0.22), w * 0.18, obsidianPaint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.23), w * 0.19, gingerPaint);
    canvas.restore();
    canvas.drawPath(headCircle, headOutline);

    if (isAlert) {
      final glint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.42, h * 0.28), 2.3, obsidianPaint);
      canvas.drawCircle(Offset(w * 0.58, h * 0.28), 2.3, obsidianPaint);
      canvas.drawCircle(Offset(w * 0.41, h * 0.27), 0.9, glint);
      canvas.drawCircle(Offset(w * 0.57, h * 0.27), 0.9, glint);
    } else {
      final facePaint = Paint()
        ..color = AppColors.calicoBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      final leftEye = Path()
        ..moveTo(w * 0.39, h * 0.29)
        ..quadraticBezierTo(w * 0.425, h * 0.25, w * 0.46, h * 0.29);
      canvas.drawPath(leftEye, facePaint);

      final rightEye = Path()
        ..moveTo(w * 0.54, h * 0.29)
        ..quadraticBezierTo(w * 0.575, h * 0.25, w * 0.61, h * 0.29);
      canvas.drawPath(rightEye, facePaint);
    }

    final nosePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(w * 0.50, h * 0.32)
      ..lineTo(w * 0.47, h * 0.305)
      ..lineTo(w * 0.53, h * 0.305)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    canvas.restore();

    // Obsidian Calico Signboard Post
    final postRect = Rect.fromLTWH(w * 0.12, h * 0.36, w * 0.76, h * 0.57);
    final postRRect = RRect.fromRectAndRadius(
      postRect,
      const Radius.circular(16),
    );

    final postPaint = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.fill;
    canvas.drawRRect(postRRect, postPaint);

    final postBorderPaint = Paint()
      ..color = isAlert ? AppColors.primary : AppColors.primary.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(postRRect, postBorderPaint);

    final targetCenter = Offset(w * 0.50, h * 0.66);
    final targetPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(targetCenter, 8.5, targetPaint);

    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 3.2, centerDotPaint);

    canvas.drawLine(
      Offset(targetCenter.dx - 12.5, targetCenter.dy),
      Offset(targetCenter.dx - 8, targetCenter.dy),
      targetPaint,
    );
    canvas.drawLine(
      Offset(targetCenter.dx + 8, targetCenter.dy),
      Offset(targetCenter.dx + 12.5, targetCenter.dy),
      targetPaint,
    );
    canvas.drawLine(
      Offset(targetCenter.dx, targetCenter.dy - 12.5),
      Offset(targetCenter.dx, targetCenter.dy - 8),
      targetPaint,
    );
    canvas.drawLine(
      Offset(targetCenter.dx, targetCenter.dy + 8),
      Offset(targetCenter.dx, targetCenter.dy + 12.5),
      targetPaint,
    );

    // Cream & Ginger Paws Resting Over Post
    final pawPaint = Paint()
      ..color = const Color(0xFFFFFAF4)
      ..style = PaintingStyle.fill;
    final pawOutline = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leftPawRect = Rect.fromCenter(
      center: Offset(w * 0.33, h * 0.37 + (peekOffset * 0.4)),
      width: w * 0.18,
      height: h * 0.125,
    );
    canvas.drawOval(leftPawRect, pawPaint);
    canvas.drawOval(leftPawRect, pawOutline);

    final rightPawRect = Rect.fromCenter(
      center: Offset(w * 0.67, h * 0.37 + (peekOffset * 0.4)),
      width: w * 0.18,
      height: h * 0.125,
    );
    canvas.drawOval(rightPawRect, pawPaint);
    canvas.drawOval(rightPawRect, pawOutline);
  }

  @override
  bool shouldRepaint(covariant _PeekingCalicoCatPainter oldDelegate) {
    return oldDelegate.peekOffset != peekOffset ||
        oldDelegate.isAlert != isAlert;
  }
}
