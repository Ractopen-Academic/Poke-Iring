import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../theme/calico_theme_controller.dart';

class CalicoAnimatedBar extends StatelessWidget {
  final bool isActive;
  final double activeWidth;

  const CalicoAnimatedBar({
    super.key,
    required this.isActive,
    this.activeWidth = 22,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 4),
      height: 4,
      width: isActive ? activeWidth : 0,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(99),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(150),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
    );
  }
}

class CalicoPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enableHaptics;

  const CalicoPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.enableHaptics = true,
  });

  @override
  State<CalicoPressable> createState() => _CalicoPressableState();
}

class _CalicoPressableState extends State<CalicoPressable> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
    if (value && widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressedScale : 1.0,
          duration: Duration(milliseconds: _isPressed ? 95 : 220),
          curve: _isPressed ? Curves.easeOutCubic : Curves.elasticOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class CalicoSpotCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showCalicoPatches;
  final VoidCallback? onTap;

  const CalicoSpotCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
    this.backgroundColor,
    this.borderColor,
    this.showCalicoPatches = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CalicoThemeController.instance.palette;
    final effectiveBorder = borderColor ?? palette.border;
    final effectiveBg = backgroundColor ?? palette.surface;
    final isLight = CalicoThemeController.instance.isCalicoLight;

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isLight && borderColor == null
              ? const Color(0xFFE06D22).withAlpha(38)
              : effectiveBorder,
          width: 1.4,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF6B5E55).withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF3E2723).withAlpha(14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: effectiveBorder.withAlpha(170),
                  blurRadius: 0,
                  offset: const Offset(0, 2.5),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (showCalicoPatches)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _CalicoCardSpotsPainter()),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }
    return CalicoPressable(onTap: onTap, child: card);
  }
}

class _CalicoCardSpotsPainter extends CustomPainter {
  final CalicoCoatMode coat = CalicoThemeController.instance.effectiveMode;

  @override
  void paint(Canvas canvas, Size size) {
    final isLight = CalicoThemeController.instance.isCalicoLight;
    final gingerSpot = Paint()
      ..color = AppColors.primary.withAlpha(isLight ? 24 : 18)
      ..style = PaintingStyle.fill;
    final charcoalSpot = Paint()
      ..color = (isLight ? const Color(0xFF6B5E55) : AppColors.calicoCharcoal)
          .withAlpha(isLight ? 14 : 12)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width - 18, -8), 34, gingerSpot);
    canvas.drawCircle(Offset(size.width + 4, 24), 22, charcoalSpot);

    final pawPaint = Paint()
      ..color = AppColors.primary.withAlpha(isLight ? 26 : 22)
      ..style = PaintingStyle.fill;
    final px = size.width - 28;
    final py = size.height - 22;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px, py), width: 12, height: 9),
      pawPaint,
    );
    canvas.drawCircle(Offset(px - 6, py - 7), 2.6, pawPaint);
    canvas.drawCircle(Offset(px - 1.5, py - 9), 2.8, pawPaint);
    canvas.drawCircle(Offset(px + 3.5, py - 8.5), 2.8, pawPaint);
    canvas.drawCircle(Offset(px + 7, py - 5.5), 2.5, pawPaint);
  }

  @override
  bool shouldRepaint(covariant _CalicoCardSpotsPainter oldDelegate) =>
      oldDelegate.coat != coat;
}
