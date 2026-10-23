import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CutePawCompassPointer extends StatelessWidget {
  final double size;
  final Color padColor;
  final Color baseColor;

  const CutePawCompassPointer({
    super.key,
    this.size = 28.0,
    this.padColor = AppColors.primary,
    this.baseColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CutePawPainter(padColor: padColor, baseColor: baseColor),
      ),
    );
  }
}

class _CutePawPainter extends CustomPainter {
  final Color padColor;
  final Color baseColor;

  const _CutePawPainter({required this.padColor, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft paw silhouette base
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pawShape = Path();
    pawShape.moveTo(w * 0.50, h * 0.04); // North pointer tip
    pawShape.cubicTo(
      w * 0.72,
      h * 0.08,
      w * 0.94,
      h * 0.35,
      w * 0.88,
      h * 0.68,
    );
    pawShape.cubicTo(
      w * 0.82,
      h * 0.94,
      w * 0.58,
      h * 0.98,
      w * 0.50,
      h * 0.98,
    );
    pawShape.cubicTo(
      w * 0.42,
      h * 0.98,
      w * 0.18,
      h * 0.94,
      w * 0.12,
      h * 0.68,
    );
    pawShape.cubicTo(
      w * 0.06,
      h * 0.35,
      w * 0.28,
      h * 0.08,
      w * 0.50,
      h * 0.04,
    );
    pawShape.close();

    canvas.drawPath(pawShape, basePaint);
    canvas.drawPath(pawShape, outlinePaint);

    // 2. Toe Beans (4 toes in upward arc pointing North)
    final beanPaint = Paint()
      ..color = padColor
      ..style = PaintingStyle.fill;

    // Outer-left toe bean
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.24, h * 0.34),
        width: w * 0.16,
        height: h * 0.22,
      ),
      beanPaint,
    );

    // Inner-left toe bean (pointing up-left)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.40, h * 0.22),
        width: w * 0.17,
        height: h * 0.24,
      ),
      beanPaint,
    );

    // Inner-right toe bean (pointing up-right)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.60, h * 0.22),
        width: w * 0.17,
        height: h * 0.24,
      ),
      beanPaint,
    );

    // Outer-right toe bean
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.76, h * 0.34),
        width: w * 0.16,
        height: h * 0.22,
      ),
      beanPaint,
    );

    // 3. Main Palm Pad (metacarpal pad)
    final mainPad = Path();
    mainPad.moveTo(w * 0.50, h * 0.46);
    mainPad.cubicTo(w * 0.34, h * 0.44, w * 0.24, h * 0.62, w * 0.36, h * 0.80);
    mainPad.cubicTo(w * 0.44, h * 0.86, w * 0.56, h * 0.86, w * 0.64, h * 0.80);
    mainPad.cubicTo(w * 0.76, h * 0.62, w * 0.66, h * 0.44, w * 0.50, h * 0.46);
    mainPad.close();

    canvas.drawPath(mainPad, beanPaint);

    // 4. Subtle north direction indicator tick at top
    final tickPaint = Paint()
      ..color = padColor
      ..style = PaintingStyle.fill;
    final tickPath = Path();
    tickPath.moveTo(w * 0.50, h * 0.05);
    tickPath.lineTo(w * 0.46, h * 0.11);
    tickPath.lineTo(w * 0.54, h * 0.11);
    tickPath.close();
    canvas.drawPath(tickPath, tickPaint);
  }

  @override
  bool shouldRepaint(covariant _CutePawPainter oldDelegate) {
    return oldDelegate.padColor != padColor ||
        oldDelegate.baseColor != baseColor;
  }
}
