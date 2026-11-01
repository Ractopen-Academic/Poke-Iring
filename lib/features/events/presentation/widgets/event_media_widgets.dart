import 'package:flutter/material.dart';

class EventBannerSurface extends StatelessWidget {
  final Color bannerColor;
  final String? bannerImageUrl;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final List<BoxShadow>? boxShadow;
  final double darkenFactor;
  final Widget child;

  const EventBannerSurface({
    super.key,
    required this.bannerColor,
    required this.padding,
    required this.child,
    this.bannerImageUrl,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.boxShadow,
    this.darkenFactor = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = bannerImageUrl != null && bannerImageUrl!.isNotEmpty;

    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor,
            Color.lerp(bannerColor, Colors.black, darkenFactor)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
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
                      Colors.black.withAlpha(80),
                      Colors.black.withAlpha(145),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
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
