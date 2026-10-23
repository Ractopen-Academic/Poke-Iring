import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class IringCenterButton extends StatefulWidget {
  final VoidCallback onTap;

  const IringCenterButton({super.key, required this.onTap});

  @override
  State<IringCenterButton> createState() => _IringCenterButtonState();
}

class _IringCenterButtonState extends State<IringCenterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(90),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(64, 64),
                    painter: _CircularTextPainter(
                      text: 'IRING   POKE   ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(painter: _CuteCatCenterPainter()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;

  _CircularTextPainter({required this.text, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    final totalChars = text.length;
    final angleStep = (2 * math.pi) / totalChars;

    for (int i = 0; i < totalChars; i++) {
      final char = text[i];
      final angle = i * angleStep;

      final textSpan = TextSpan(text: char, style: style);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.rotate(angle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTextPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.style != style;
  }
}

class _CuteCatCenterPainter extends CustomPainter {
  const _CuteCatCenterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final catOrange = AppColors.primary;
    final catPaint = Paint()
      ..color = catOrange
      ..style = PaintingStyle.fill;

    // Left Ear
    final leftEar = Path()
      ..moveTo(w * 0.22, h * 0.32)
      ..lineTo(w * 0.16, h * 0.08)
      ..lineTo(w * 0.40, h * 0.18)
      ..close();
    canvas.drawPath(leftEar, catPaint);

    // Right Ear
    final rightEar = Path()
      ..moveTo(w * 0.78, h * 0.32)
      ..lineTo(w * 0.84, h * 0.08)
      ..lineTo(w * 0.60, h * 0.18)
      ..close();
    canvas.drawPath(rightEar, catPaint);

    // Inner Pink Ears
    final pinkPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..style = PaintingStyle.fill;

    final leftInner = Path()
      ..moveTo(w * 0.23, h * 0.28)
      ..lineTo(w * 0.19, h * 0.13)
      ..lineTo(w * 0.35, h * 0.20)
      ..close();
    canvas.drawPath(leftInner, pinkPaint);

    final rightInner = Path()
      ..moveTo(w * 0.77, h * 0.28)
      ..lineTo(w * 0.81, h * 0.13)
      ..lineTo(w * 0.65, h * 0.20)
      ..close();
    canvas.drawPath(rightInner, pinkPaint);

    // Head
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.52),
      width: w * 0.74,
      height: h * 0.66,
    );
    canvas.drawOval(headRect, catPaint);

    // White Muzzle / Cheeks Patch
    final muzzleRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.64),
      width: w * 0.46,
      height: h * 0.34,
    );
    final muzzlePaint = Paint()
      ..color = Colors.white.withAlpha(230)
      ..style = PaintingStyle.fill;
    canvas.drawOval(muzzleRect, muzzlePaint);

    // Happy Eyes (^ ^)
    final eyePaint = Paint()
      ..color = const Color(0xFF3E1F07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(w * 0.34, h * 0.48)
      ..quadraticBezierTo(w * 0.38, h * 0.43, w * 0.42, h * 0.48);
    canvas.drawPath(leftEye, eyePaint);

    final rightEye = Path()
      ..moveTo(w * 0.58, h * 0.48)
      ..quadraticBezierTo(w * 0.62, h * 0.43, w * 0.66, h * 0.48);
    canvas.drawPath(rightEye, eyePaint);

    // Pink Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;
    final nose = Path()
      ..moveTo(w * 0.50, h * 0.58)
      ..lineTo(w * 0.46, h * 0.54)
      ..lineTo(w * 0.54, h * 0.54)
      ..close();
    canvas.drawPath(nose, nosePaint);

    // Mouth (w)
    final mouthPaint = Paint()
      ..color = const Color(0xFF3E1F07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final mouthLeft = Path()
      ..moveTo(w * 0.46, h * 0.62)
      ..quadraticBezierTo(w * 0.48, h * 0.66, w * 0.50, h * 0.62);
    final mouthRight = Path()
      ..moveTo(w * 0.50, h * 0.62)
      ..quadraticBezierTo(w * 0.52, h * 0.66, w * 0.54, h * 0.62);
    canvas.drawPath(mouthLeft, mouthPaint);
    canvas.drawPath(mouthRight, mouthPaint);

    // Blushing cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A65).withAlpha(150)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.26, h * 0.56), w * 0.05, blushPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.56), w * 0.05, blushPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF3E1F07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(
      Offset(w * 0.25, h * 0.54),
      Offset(w * 0.10, h * 0.51),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.25, h * 0.60),
      Offset(w * 0.11, h * 0.64),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.75, h * 0.54),
      Offset(w * 0.90, h * 0.51),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.75, h * 0.60),
      Offset(w * 0.89, h * 0.64),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
