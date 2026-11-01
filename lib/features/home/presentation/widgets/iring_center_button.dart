import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

class IringCenterButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isMapOpen;

  const IringCenterButton({
    super.key,
    required this.onTap,
    this.isMapOpen = false,
  });

  @override
  State<IringCenterButton> createState() => _IringCenterButtonState();
}

class _IringCenterButtonState extends State<IringCenterButton>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _popController;
  late final Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.90,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.90,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.10,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_popController);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _popController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isMapOpen = widget.isMapOpen;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _popController,
        builder: (context, child) {
          return Transform.scale(scale: _popScale.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isMapOpen
                  ? const [AppColors.calicoCharcoal, AppColors.calicoBlack]
                  : const [Color(0xFFFFA033), AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isMapOpen ? AppColors.primary : const Color(0xFFFFF4E8),
              width: 2.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(isMapOpen ? 130 : 105),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.calicoBlack.withAlpha(90),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _orbitController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(62, 62),
                      painter: _CircularTextPainter(
                        text: isMapOpen ? 'CLOSE   MAP    ' : 'IRING   POKE   ',
                        style: TextStyle(
                          color: isMapOpen
                              ? AppColors.gingerBorder
                              : Colors.white,
                          fontSize: 7.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMapOpen ? const Color(0xFFFFF4E8) : Colors.white,
                  border: Border.all(
                    color: AppColors.calicoBlack.withAlpha(35),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CustomPaint(
                      painter: _CalicoCatCenterPainter(isAlert: isMapOpen),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    final radius = (size.width / 2) - 5.5;
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

class _CalicoCatCenterPainter extends CustomPainter {
  final bool isAlert;

  const _CalicoCatCenterPainter({required this.isAlert});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gingerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final obsidianPaint = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.fill;
    final creamPaint = Paint()
      ..color = const Color(0xFFFFFAF4)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Left Ear (Obsidian Calico Patch)
    final leftEar = Path()
      ..moveTo(w * 0.21, h * 0.34)
      ..lineTo(w * 0.14, h * 0.08)
      ..lineTo(w * 0.40, h * 0.18)
      ..close();
    canvas.drawPath(leftEar, obsidianPaint);

    // Right Ear (Marmalade Ginger Patch)
    final rightEar = Path()
      ..moveTo(w * 0.79, h * 0.34)
      ..lineTo(w * 0.86, h * 0.08)
      ..lineTo(w * 0.60, h * 0.18)
      ..close();
    canvas.drawPath(rightEar, gingerPaint);

    // Inner Pink Ears
    final pinkPaint = Paint()
      ..color = AppColors.calicoPink
      ..style = PaintingStyle.fill;

    final leftInner = Path()
      ..moveTo(w * 0.23, h * 0.29)
      ..lineTo(w * 0.19, h * 0.14)
      ..lineTo(w * 0.35, h * 0.21)
      ..close();
    canvas.drawPath(leftInner, pinkPaint);

    final rightInner = Path()
      ..moveTo(w * 0.77, h * 0.29)
      ..lineTo(w * 0.81, h * 0.14)
      ..lineTo(w * 0.65, h * 0.21)
      ..close();
    canvas.drawPath(rightInner, pinkPaint);

    // Warm Cream Calico Head Base + Clipped Tri-Color Forehead Patches
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.54),
      width: w * 0.76,
      height: h * 0.66,
    );
    final headPath = Path()..addOval(headRect);
    canvas.drawPath(headPath, creamPaint);

    canvas.save();
    canvas.clipPath(headPath);
    canvas.drawCircle(Offset(w * 0.27, h * 0.34), w * 0.24, obsidianPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.35), w * 0.25, gingerPaint);
    canvas.restore();

    canvas.drawPath(headPath, outlinePaint);

    // Eyes: Round curious eyes when map is open, happy ^ ^ arcs on tabs
    if (isAlert) {
      final eyeFill = Paint()
        ..color = AppColors.calicoBlack
        ..style = PaintingStyle.fill;
      final glint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.38, h * 0.50), w * 0.055, eyeFill);
      canvas.drawCircle(Offset(w * 0.62, h * 0.50), w * 0.055, eyeFill);
      canvas.drawCircle(Offset(w * 0.365, h * 0.485), w * 0.02, glint);
      canvas.drawCircle(Offset(w * 0.605, h * 0.485), w * 0.02, glint);
    } else {
      final eyePaint = Paint()
        ..color = AppColors.calicoBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      final leftEye = Path()
        ..moveTo(w * 0.33, h * 0.50)
        ..quadraticBezierTo(w * 0.38, h * 0.44, w * 0.43, h * 0.50);
      canvas.drawPath(leftEye, eyePaint);

      final rightEye = Path()
        ..moveTo(w * 0.57, h * 0.50)
        ..quadraticBezierTo(w * 0.62, h * 0.44, w * 0.67, h * 0.50);
      canvas.drawPath(rightEye, eyePaint);
    }

    // Berry Pink Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;
    final nose = Path()
      ..moveTo(w * 0.50, h * 0.60)
      ..lineTo(w * 0.46, h * 0.56)
      ..lineTo(w * 0.54, h * 0.56)
      ..close();
    canvas.drawPath(nose, nosePaint);

    // Cute 'w' Mouth
    final mouthPaint = Paint()
      ..color = AppColors.calicoBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final mouth = Path()
      ..moveTo(w * 0.45, h * 0.63)
      ..quadraticBezierTo(w * 0.475, h * 0.67, w * 0.50, h * 0.63)
      ..quadraticBezierTo(w * 0.525, h * 0.67, w * 0.55, h * 0.63);
    canvas.drawPath(mouth, mouthPaint);

    // Soft Blush
    final blushPaint = Paint()
      ..color = AppColors.calicoPink.withAlpha(150)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.27, h * 0.58), w * 0.05, blushPaint);
    canvas.drawCircle(Offset(w * 0.73, h * 0.58), w * 0.05, blushPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = AppColors.calicoCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(
      Offset(w * 0.24, h * 0.56),
      Offset(w * 0.09, h * 0.53),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.24, h * 0.62),
      Offset(w * 0.10, h * 0.66),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.76, h * 0.56),
      Offset(w * 0.91, h * 0.53),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.76, h * 0.62),
      Offset(w * 0.90, h * 0.66),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalicoCatCenterPainter oldDelegate) {
    return oldDelegate.isAlert != isAlert;
  }
}
