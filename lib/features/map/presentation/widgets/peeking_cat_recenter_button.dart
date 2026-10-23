import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class PeekingCatRecenterButton extends StatefulWidget {
  final VoidCallback onTap;

  const PeekingCatRecenterButton({super.key, required this.onTap});

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
      duration: const Duration(milliseconds: 320),
    );

    _peekAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -8.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -8.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_bounceController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: 58,
              height: 64,
              child: CustomPaint(
                painter: _PeekingCatPainter(peekOffset: _peekAnimation.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeekingCatPainter extends CustomPainter {
  final double peekOffset;

  const _PeekingCatPainter({required this.peekOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow under the entire post
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.36 + 3, w * 0.76, h * 0.58),
        const Radius.circular(16),
      ),
      shadowPaint,
    );

    // 1. Cat peeking behind the post (shifted by peekOffset)
    canvas.save();
    canvas.translate(0, peekOffset);

    final catOrange = AppColors.primary;
    final catPaint = Paint()
      ..color = catOrange
      ..style = PaintingStyle.fill;

    // Cat ears
    final leftEar = Path()
      ..moveTo(w * 0.25, h * 0.28)
      ..lineTo(w * 0.20, h * 0.08)
      ..lineTo(w * 0.38, h * 0.18)
      ..close();
    canvas.drawPath(leftEar, catPaint);

    final rightEar = Path()
      ..moveTo(w * 0.75, h * 0.28)
      ..lineTo(w * 0.80, h * 0.08)
      ..lineTo(w * 0.62, h * 0.18)
      ..close();
    canvas.drawPath(rightEar, catPaint);

    // Inner pink ears
    final pinkPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..style = PaintingStyle.fill;

    final innerLeftEar = Path()
      ..moveTo(w * 0.26, h * 0.25)
      ..lineTo(w * 0.23, h * 0.12)
      ..lineTo(w * 0.34, h * 0.19)
      ..close();
    canvas.drawPath(innerLeftEar, pinkPaint);

    final innerRightEar = Path()
      ..moveTo(w * 0.74, h * 0.25)
      ..lineTo(w * 0.77, h * 0.12)
      ..lineTo(w * 0.66, h * 0.19)
      ..close();
    canvas.drawPath(innerRightEar, pinkPaint);

    // Cat head
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.26, catPaint);

    // Cat eyes (happy arcs ^ ^)
    final facePaint = Paint()
      ..color = const Color(0xFF42210B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(w * 0.40, h * 0.28)
      ..quadraticBezierTo(w * 0.43, h * 0.24, w * 0.46, h * 0.28);
    canvas.drawPath(leftEye, facePaint);

    final rightEye = Path()
      ..moveTo(w * 0.54, h * 0.28)
      ..quadraticBezierTo(w * 0.57, h * 0.24, w * 0.60, h * 0.28);
    canvas.drawPath(rightEye, facePaint);

    // Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(w * 0.50, h * 0.31)
      ..lineTo(w * 0.47, h * 0.30)
      ..lineTo(w * 0.53, h * 0.30)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    canvas.restore();

    // 2. The Post / Signboard in front of the cat
    final postRect = Rect.fromLTWH(w * 0.12, h * 0.34, w * 0.76, h * 0.60);
    final postRRect = RRect.fromRectAndRadius(
      postRect,
      const Radius.circular(16),
    );

    // Post body
    final postPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(postRRect, postPaint);

    // Post border
    final postBorderPaint = Paint()
      ..color = const Color(0xFFFFD180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(postRRect, postBorderPaint);

    // Crosshair / location icon on the post
    final targetCenter = Offset(w * 0.50, h * 0.66);
    final targetPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(targetCenter, 9.0, targetPaint);

    final centerDotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetCenter, 3.5, centerDotPaint);

    // Mini crosshair ticks
    canvas.drawLine(
      Offset(targetCenter.dx - 13, targetCenter.dy),
      Offset(targetCenter.dx - 8, targetCenter.dy),
      targetPaint,
    );
    canvas.drawLine(
      Offset(targetCenter.dx + 8, targetCenter.dy),
      Offset(targetCenter.dx + 13, targetCenter.dy),
      targetPaint,
    );
    canvas.drawLine(
      Offset(targetCenter.dx, targetCenter.dy - 13),
      Offset(targetCenter.dx, targetCenter.dy - 8),
      targetPaint,
    );
    canvas.drawLine(
      Offset(targetCenter.dx, targetCenter.dy + 8),
      Offset(targetCenter.dx, targetCenter.dy + 13),
      targetPaint,
    );

    // 3. Cat paws resting over the top edge of the post
    final pawPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pawOutline = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left paw
    final leftPawRect = Rect.fromCenter(
      center: Offset(w * 0.33, h * 0.36 + (peekOffset * 0.4)),
      width: w * 0.18,
      height: h * 0.13,
    );
    canvas.drawOval(leftPawRect, pawPaint);
    canvas.drawOval(leftPawRect, pawOutline);

    // Right paw
    final rightPawRect = Rect.fromCenter(
      center: Offset(w * 0.67, h * 0.36 + (peekOffset * 0.4)),
      width: w * 0.18,
      height: h * 0.13,
    );
    canvas.drawOval(rightPawRect, pawPaint);
    canvas.drawOval(rightPawRect, pawOutline);
  }

  @override
  bool shouldRepaint(covariant _PeekingCatPainter oldDelegate) {
    return oldDelegate.peekOffset != peekOffset;
  }
}
