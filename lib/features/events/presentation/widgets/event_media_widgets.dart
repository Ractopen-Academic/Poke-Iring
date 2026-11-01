import 'package:flutter/material.dart';

class EventBannerSurface extends StatelessWidget {
  final Color bannerColor;
  final Color? accentColor;
  final String? bannerImageUrl;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double darkenFactor;
  final Widget child;

  const EventBannerSurface({
    super.key,
    required this.bannerColor,
    required this.padding,
    required this.child,
    this.accentColor,
    this.bannerImageUrl,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.border,
    this.boxShadow,
    this.darkenFactor = 0.28,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = bannerImageUrl != null && bannerImageUrl!.isNotEmpty;
    final spotHighlight = accentColor ?? const Color(0xFFFF8C1A);

    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor,
            Color.lerp(bannerColor, const Color(0xFF140F0D), darkenFactor)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (hasBanner) ...[
            Positioned.fill(
              child: Image.network(
                bannerImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1B1614).withAlpha(95),
                      const Color(0xFF1B1614).withAlpha(175),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ] else
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _EventCalicoWatermarkPainter(
                    accentColor: spotHighlight,
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _EventCalicoWatermarkPainter extends CustomPainter {
  final Color accentColor;

  const _EventCalicoWatermarkPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final accentSpot = Paint()
      ..color = accentColor.withAlpha(36)
      ..style = PaintingStyle.fill;
    final creamSpot = Paint()
      ..color = const Color(0xFFFFFAF4).withAlpha(18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width - 22, -10), 46, accentSpot);
    canvas.drawCircle(Offset(size.width + 6, 36), 30, creamSpot);

    final pawPaint = Paint()
      ..color = accentColor.withAlpha(42)
      ..style = PaintingStyle.fill;
    final px = size.width - 34;
    final py = size.height - 26;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px, py), width: 15, height: 11),
      pawPaint,
    );
    canvas.drawCircle(Offset(px - 7.5, py - 8.5), 3.1, pawPaint);
    canvas.drawCircle(Offset(px - 2.0, py - 11.0), 3.4, pawPaint);
    canvas.drawCircle(Offset(px + 4.0, py - 10.5), 3.4, pawPaint);
    canvas.drawCircle(Offset(px + 8.5, py - 7.0), 3.0, pawPaint);
  }

  @override
  bool shouldRepaint(covariant _EventCalicoWatermarkPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}

class EventLogoEmblem extends StatelessWidget {
  final String? logoImageUrl;
  final double size;
  final double borderRadius;
  final Widget fallback;

  const EventLogoEmblem({
    super.key,
    required this.logoImageUrl,
    required this.size,
    required this.fallback,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final url = logoImageUrl;
    if (url == null || url.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
