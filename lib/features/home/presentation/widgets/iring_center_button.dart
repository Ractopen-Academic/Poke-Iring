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
              child: const Icon(Icons.pets, color: AppColors.primary, size: 20),
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
