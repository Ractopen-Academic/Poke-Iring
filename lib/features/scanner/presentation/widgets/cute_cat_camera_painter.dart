import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CuteCatCameraPainter extends CustomPainter {
  const CuteCatCameraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadowPaint = Paint()
      ..color = AppColors.calicoBlack.withAlpha(65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(w * 0.50, h * 0.53), w * 0.44, shadowPaint);

    // Warm Cream & Soft Marmalade Badge Backdrop
    final bgPaint = Paint()
      ..shader =
          const RadialGradient(colors: [Color(0xFFFFFBF6), Color(0xFFFFE8CC)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(w * 0.50, h * 0.50),
                  radius: w * 0.48,
                ),
              );
    final bgBorder = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.47, bgPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.47, bgBorder);

    final gingerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final obsidianPaint = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.fill;
    final creamPaint = Paint()
      ..color = const Color(0xFFFFFAF4)
      ..style = PaintingStyle.fill;
    final catBorder = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left Ear (Obsidian Calico)
    final leftEar = Path()
      ..moveTo(w * 0.26, h * 0.26)
      ..lineTo(w * 0.18, h * 0.08)
      ..lineTo(w * 0.38, h * 0.15)
      ..close();
    canvas.drawPath(leftEar, obsidianPaint);
    canvas.drawPath(leftEar, catBorder);

    // Right Ear (Marmalade Ginger)
    final rightEar = Path()
      ..moveTo(w * 0.74, h * 0.26)
      ..lineTo(w * 0.82, h * 0.08)
      ..lineTo(w * 0.62, h * 0.15)
      ..close();
    canvas.drawPath(rightEar, gingerPaint);
    canvas.drawPath(rightEar, catBorder);

    final pinkPaint = Paint()
      ..color = AppColors.calicoPink
      ..style = PaintingStyle.fill;

    final leftInner = Path()
      ..moveTo(w * 0.26, h * 0.23)
      ..lineTo(w * 0.21, h * 0.12)
      ..lineTo(w * 0.34, h * 0.17)
      ..close();
    canvas.drawPath(leftInner, pinkPaint);

    final rightInner = Path()
      ..moveTo(w * 0.74, h * 0.23)
      ..lineTo(w * 0.79, h * 0.12)
      ..lineTo(w * 0.66, h * 0.17)
      ..close();
    canvas.drawPath(rightInner, pinkPaint);

    // Calico Head Base + Clipped Tri-Color Patches
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.28),
      width: w * 0.52,
      height: h * 0.34,
    );
    final headPath = Path()..addOval(headRect);
    canvas.drawPath(headPath, creamPaint);

    canvas.save();
    canvas.clipPath(headPath);
    canvas.drawCircle(Offset(w * 0.34, h * 0.19), w * 0.17, obsidianPaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.20), w * 0.18, gingerPaint);
    canvas.restore();
    canvas.drawPath(headPath, catBorder);

    final facePaint = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(w * 0.39, h * 0.25)
      ..quadraticBezierTo(w * 0.42, h * 0.21, w * 0.45, h * 0.25);
    canvas.drawPath(leftEye, facePaint);

    final rightEye = Path()
      ..moveTo(w * 0.55, h * 0.25)
      ..quadraticBezierTo(w * 0.58, h * 0.21, w * 0.61, h * 0.25);
    canvas.drawPath(rightEye, facePaint);

    final nosePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;
    final nose = Path()
      ..moveTo(w * 0.50, h * 0.29)
      ..lineTo(w * 0.47, h * 0.27)
      ..lineTo(w * 0.53, h * 0.27)
      ..close();
    canvas.drawPath(nose, nosePaint);

    final blushPaint = Paint()
      ..color = AppColors.calicoPink.withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.33, h * 0.27), w * 0.045, blushPaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.27), w * 0.045, blushPaint);

    final whiskerPaint = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(w * 0.31, h * 0.26),
      Offset(w * 0.19, h * 0.24),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.31, h * 0.29),
      Offset(w * 0.20, h * 0.31),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.69, h * 0.26),
      Offset(w * 0.81, h * 0.24),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.69, h * 0.29),
      Offset(w * 0.80, h * 0.31),
      whiskerPaint,
    );

    // Obsidian Calico Camera Body
    final cameraRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.38, w * 0.68, h * 0.46),
      const Radius.circular(10),
    );

    canvas.drawRRect(cameraRRect, obsidianPaint);
    canvas.drawRRect(
      cameraRRect,
      Paint()
        ..color = AppColors.primary.withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final topPlate = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.16, h * 0.38, w * 0.68, h * 0.12),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
    );
    canvas.drawRRect(
      topPlate,
      Paint()
        ..color = AppColors.calicoCharcoal
        ..style = PaintingStyle.fill,
    );

    // Marmalade Shutter Button
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.12, h * 0.06),
        const Radius.circular(3),
      ),
      gingerPaint,
    );

    // Warm Amber Flash
    canvas.drawCircle(
      Offset(w * 0.74, h * 0.44),
      w * 0.035,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.fill,
    );

    // Lens
    final lensCenter = Offset(w * 0.50, h * 0.62);
    canvas.drawCircle(
      lensCenter,
      w * 0.19,
      Paint()
        ..color = const Color(0xFF120E0D)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      lensCenter,
      w * 0.19,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final glassPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFAB40), Color(0xFF4E2600)],
      ).createShader(Rect.fromCircle(center: lensCenter, radius: w * 0.14));
    canvas.drawCircle(lensCenter, w * 0.14, glassPaint);

    final reflectionPaint = Paint()
      ..color = Colors.white.withAlpha(210)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: lensCenter, radius: w * 0.10),
      -1.2,
      1.2,
      false,
      reflectionPaint,
    );

    final miniPawPaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, h * 0.63), w * 0.035, miniPawPaint);
    canvas.drawCircle(Offset(w * 0.46, h * 0.59), w * 0.016, miniPawPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.57), w * 0.018, miniPawPaint);
    canvas.drawCircle(Offset(w * 0.54, h * 0.59), w * 0.016, miniPawPaint);

    // Cream Paws Gripping Camera
    final pawBorder = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leftPaw = Rect.fromCenter(
      center: Offset(w * 0.22, h * 0.46),
      width: w * 0.16,
      height: h * 0.13,
    );
    canvas.drawOval(leftPaw, creamPaint);
    canvas.drawOval(leftPaw, pawBorder);

    final rightPaw = Rect.fromCenter(
      center: Offset(w * 0.78, h * 0.46),
      width: w * 0.16,
      height: h * 0.13,
    );
    canvas.drawOval(rightPaw, creamPaint);
    canvas.drawOval(rightPaw, pawBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
