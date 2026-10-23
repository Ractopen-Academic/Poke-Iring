import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CatArmCompassPointer extends StatelessWidget {
  final double size;
  final Color armColor;
  final Color padColor;

  const CatArmCompassPointer({
    super.key,
    this.size = 28.0,
    this.armColor = AppColors.primary,
    this.padColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CatArmPainter(armColor: armColor, padColor: padColor),
      ),
    );
  }
}

class _CatArmPainter extends CustomPainter {
  final Color armColor;
  final Color padColor;

  const _CatArmPainter({required this.armColor, required this.padColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final armPath = Path();
    armPath.moveTo(w * 0.32, h * 0.98);
    armPath.cubicTo(w * 0.33, h * 0.65, w * 0.22, h * 0.42, w * 0.24, h * 0.28);
    armPath.cubicTo(w * 0.25, h * 0.17, w * 0.37, h * 0.14, w * 0.42, h * 0.20);
    armPath.cubicTo(w * 0.44, h * 0.04, w * 0.56, h * 0.04, w * 0.58, h * 0.20);
    armPath.cubicTo(w * 0.63, h * 0.14, w * 0.75, h * 0.17, w * 0.76, h * 0.28);
    armPath.cubicTo(w * 0.78, h * 0.42, w * 0.67, h * 0.65, w * 0.68, h * 0.98);
    armPath.close();

    final armPaint = Paint()
      ..color = armColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(armPath, armPaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFFD66A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(armPath, outlinePaint);

    final padPaint = Paint()
      ..color = padColor
      ..style = PaintingStyle.fill;

    final mainPadPath = Path();
    mainPadPath.moveTo(w * 0.50, h * 0.36);
    mainPadPath.cubicTo(
      w * 0.38,
      h * 0.36,
      w * 0.35,
      h * 0.50,
      w * 0.50,
      h * 0.55,
    );
    mainPadPath.cubicTo(
      w * 0.65,
      h * 0.50,
      w * 0.62,
      h * 0.36,
      w * 0.50,
      h * 0.36,
    );
    canvas.drawPath(mainPadPath, padPaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.34, h * 0.24),
        width: w * 0.13,
        height: h * 0.17,
      ),
      padPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.16),
        width: w * 0.14,
        height: h * 0.19,
      ),
      padPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.66, h * 0.24),
        width: w * 0.13,
        height: h * 0.17,
      ),
      padPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatArmPainter oldDelegate) {
    return oldDelegate.armColor != armColor || oldDelegate.padColor != padColor;
  }
}
