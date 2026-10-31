import 'package:flutter/material.dart';

import '../../data/datasources/local_event_catalog.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/profile_border.dart';

class ProfileBorderAvatar extends StatelessWidget {
  final Widget child;
  final ProfileBorder? border;
  final String? borderId;
  final String? userId;
  final double radius;
  final VoidCallback? onTap;

  const ProfileBorderAvatar({
    super.key,
    required this.child,
    this.border,
    this.borderId,
    this.userId,
    this.radius = 28.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (border != null) {
      return _buildWithBorder(border!);
    }

    if (borderId != null) {
      final found = LocalEventCatalog.findBorder(borderId!);
      if (found != null) {
        return _buildWithBorder(found);
      }
    }

    if (userId != null) {
      return StreamBuilder<String?>(
        stream: EventRepositoryImpl.instance.watchEquippedBorderId(userId!),
        builder: (context, snapshot) {
          final equippedId = snapshot.data;
          if (equippedId != null) {
            final found = LocalEventCatalog.findBorder(equippedId);
            if (found != null) {
              return _buildWithBorder(found);
            }
          }
          return _buildPlainAvatar();
        },
      );
    }

    return _buildPlainAvatar();
  }

  Widget _buildPlainAvatar() {
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  Widget _buildWithBorder(ProfileBorder profileBorder) {
    final outerSize = (radius * 2) + (profileBorder.strokeWidth * 2) + 6;

    final content = SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          if (profileBorder.glowColor != null)
            Container(
              width: outerSize - 2,
              height: outerSize - 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: profileBorder.glowColor!,
                    blurRadius: profileBorder.glowBlurRadius,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
            ),

          // Gradient Ring
          CustomPaint(
            size: Size(outerSize, outerSize),
            painter: _GradientBorderPainter(
              colors: profileBorder.colors,
              strokeWidth: profileBorder.strokeWidth,
            ),
          ),

          // Inner Avatar Child
          Center(child: child),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}

class _GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;

  _GradientBorderPainter({required this.colors, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final sweepColors = colors.length >= 2
        ? [...colors, colors.first]
        : [colors.first, colors.first];

    final paint = Paint()
      ..shader = SweepGradient(
        colors: sweepColors,
        startAngle: 0.0,
        endAngle: 3.141592653589793 * 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.colors != colors;
  }
}
