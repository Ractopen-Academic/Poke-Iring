import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CuteCatCameraPainter extends CustomPainter {
  const CuteCatCameraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft base shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(w * 0.50, h * 0.52), w * 0.44, shadowPaint);

    // Circular badge backdrop
    final bgPaint = Paint()
      ..shader =
          const RadialGradient(colors: [Color(0xFFFFF8E7), Color(0xFFFFECB3)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(w * 0.50, h * 0.50),
                  radius: w * 0.48,
                ),
              );
    final bgBorder = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.47, bgPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.47, bgBorder);

    // 2. Cat Head & Ears
    final catOrange = AppColors.primary;
    final catPaint = Paint()
      ..color = catOrange
      ..style = PaintingStyle.fill;
    final catBorder = Paint()
      ..color = const Color(0xFFD66A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left Ear
    final leftEar = Path()
      ..moveTo(w * 0.26, h * 0.26)
      ..lineTo(w * 0.18, h * 0.08)
      ..lineTo(w * 0.38, h * 0.15)
      ..close();
    canvas.drawPath(leftEar, catPaint);
    canvas.drawPath(leftEar, catBorder);

    // Right Ear
    final rightEar = Path()
      ..moveTo(w * 0.74, h * 0.26)
      ..lineTo(w * 0.82, h * 0.08)
      ..lineTo(w * 0.62, h * 0.15)
      ..close();
    canvas.drawPath(rightEar, catPaint);
    canvas.drawPath(rightEar, catBorder);

    // Inner Pink Ears
    final pinkPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
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

    // Head
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.28),
      width: w * 0.52,
      height: h * 0.34,
    );
    canvas.drawOval(headRect, catPaint);
    canvas.drawOval(headRect, catBorder);

    // Happy eyes (^ ^)
    final facePaint = Paint()
      ..color = const Color(0xFF3E1F07)
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

    // Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;
    final nose = Path()
      ..moveTo(w * 0.50, h * 0.29)
      ..lineTo(w * 0.47, h * 0.27)
      ..lineTo(w * 0.53, h * 0.27)
      ..close();
    canvas.drawPath(nose, nosePaint);

    // Blushing cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFFAB91).withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.33, h * 0.27), w * 0.045, blushPaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.27), w * 0.045, blushPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF6D4C41)
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

    // 3. The Camera Body
    final cameraRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.38, w * 0.68, h * 0.46),
      const Radius.circular(10),
    );

    final cameraPaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;
    final cameraBorder = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(cameraRRect, cameraPaint);
    canvas.drawRRect(cameraRRect, cameraBorder);

    // Camera Top Plate
    final topPlate = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.16, h * 0.38, w * 0.68, h * 0.12),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(10),
    );
    final platePaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(topPlate, platePaint);

    // Shutter button on camera
    final shutterPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.12, h * 0.06),
        const Radius.circular(3),
      ),
      shutterPaint,
    );

    // Flash light
    final flashPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.74, h * 0.44), w * 0.035, flashPaint);

    // 4. Camera Lens
    final lensCenter = Offset(w * 0.50, h * 0.62);
    final outerLensPaint = Paint()
      ..color = const Color(0xFF1E272C)
      ..style = PaintingStyle.fill;
    final outerLensBorder = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(lensCenter, w * 0.19, outerLensPaint);
    canvas.drawCircle(lensCenter, w * 0.19, outerLensBorder);

    // Inner Glass
    final glassPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF29B6F6), Color(0xFF0D47A1)],
      ).createShader(Rect.fromCircle(center: lensCenter, radius: w * 0.14));
    canvas.drawCircle(lensCenter, w * 0.14, glassPaint);

    // Lens Reflection Arc
    final reflectionPaint = Paint()
      ..color = Colors.white.withAlpha(200)
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

    // Center Mini Paw on Lens
    final miniPawPaint = Paint()
      ..color = Colors.white.withAlpha(210)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, h * 0.63), w * 0.035, miniPawPaint);
    canvas.drawCircle(Offset(w * 0.46, h * 0.59), w * 0.016, miniPawPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.57), w * 0.018, miniPawPaint);
    canvas.drawCircle(Offset(w * 0.54, h * 0.59), w * 0.016, miniPawPaint);

    // 5. Cat Paws Gripping the Camera
    final pawPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pawBorder = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left Paw gripping top left
    final leftPaw = Rect.fromCenter(
      center: Offset(w * 0.22, h * 0.46),
      width: w * 0.16,
      height: h * 0.13,
    );
    canvas.drawOval(leftPaw, pawPaint);
    canvas.drawOval(leftPaw, pawBorder);

    // Right Paw gripping top right
    final rightPaw = Rect.fromCenter(
      center: Offset(w * 0.78, h * 0.46),
      width: w * 0.16,
      height: h * 0.13,
    );
    canvas.drawOval(rightPaw, pawPaint);
    canvas.drawOval(rightPaw, pawBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
