import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CameraViewfinderReticle extends StatelessWidget {
  final Widget? child;

  const CameraViewfinderReticle({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ReticlePainter(), child: child);
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokePaint = Paint()
      ..color = Colors.white.withAlpha(210)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final primaryPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const padding = 20.0;

    // Top-Left corner with cute cat ear peak
    final tl = Path()
      ..moveTo(padding, padding + cornerLength)
      ..lineTo(padding, padding + 12)
      ..lineTo(padding + 6, padding) // left ear peak
      ..lineTo(padding + 12, padding + 6)
      ..lineTo(padding + cornerLength, padding + 6);
    canvas.drawPath(tl, strokePaint);

    // Top-Right corner with cute cat ear peak
    final tr = Path()
      ..moveTo(w - padding - cornerLength, padding + 6)
      ..lineTo(w - padding - 12, padding + 6)
      ..lineTo(w - padding - 6, padding) // right ear peak
      ..lineTo(w - padding, padding + 12)
      ..lineTo(w - padding, padding + cornerLength);
    canvas.drawPath(tr, strokePaint);

    // Bottom-Left corner
    final bl = Path()
      ..moveTo(padding, h - padding - cornerLength)
      ..lineTo(padding, h - padding)
      ..lineTo(padding + cornerLength, h - padding);
    canvas.drawPath(bl, strokePaint);

    // Bottom-Right corner
    final br = Path()
      ..moveTo(w - padding - cornerLength, h - padding)
      ..lineTo(w - padding, h - padding)
      ..lineTo(w - padding, h - padding - cornerLength);
    canvas.drawPath(br, strokePaint);

    // Center focal crosshair dots
    final centerDotPaint = Paint()
      ..color = AppColors.primary.withAlpha(200)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), 3.0, centerDotPaint);

    // Small subtle center brackets
    canvas.drawLine(
      Offset(w / 2 - 14, h / 2),
      Offset(w / 2 - 6, h / 2),
      primaryPaint,
    );
    canvas.drawLine(
      Offset(w / 2 + 6, h / 2),
      Offset(w / 2 + 14, h / 2),
      primaryPaint,
    );
    canvas.drawLine(
      Offset(w / 2, h / 2 - 14),
      Offset(w / 2, h / 2 - 6),
      primaryPaint,
    );
    canvas.drawLine(
      Offset(w / 2, h / 2 + 6),
      Offset(w / 2, h / 2 + 14),
      primaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
