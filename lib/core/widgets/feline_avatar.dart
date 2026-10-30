import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FelineAvatar extends StatelessWidget {
  final String? photoUrl;
  final String seed;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const FelineAvatar({
    super.key,
    this.photoUrl,
    required this.seed,
    this.radius = 24.0,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    Widget avatarContent;

    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final cleanUrl = photoUrl!.trim();
      if (cleanUrl.startsWith('data:image')) {
        final commaIdx = cleanUrl.indexOf(',');
        final b64 = commaIdx != -1
            ? cleanUrl.substring(commaIdx + 1)
            : cleanUrl;
        try {
          avatarContent = Image.memory(
            base64Decode(b64),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDefaultFelineAvatar(size),
          );
        } catch (_) {
          avatarContent = _buildDefaultFelineAvatar(size);
        }
      } else {
        avatarContent = CachedNetworkImage(
          imageUrl: cleanUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildDefaultFelineAvatar(size),
          errorWidget: (context, url, error) => _buildDefaultFelineAvatar(size),
        );
      }
    } else {
      avatarContent = _buildDefaultFelineAvatar(size);
    }

    Widget avatar = ClipOval(child: avatarContent);

    if (showBorder) {
      avatar = Container(
        width: size + (borderWidth * 2),
        height: size + (borderWidth * 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.primary,
            width: borderWidth,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: avatar,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildDefaultFelineAvatar(double size) {
    final hash = seed.hashCode.abs();
    final palettes = [
      [const Color(0xFFFF9E44), const Color(0xFFFF5722)], // Orange Tabby
      [const Color(0xFF67B26F), const Color(0xFF4ca2cd)], // Nature Green
      [const Color(0xFFBA5370), const Color(0xFFF4E2D8)], // Calico Rose
      [const Color(0xFF360033), const Color(0xFF0b8793)], // Deep Mystery
      [const Color(0xFFFFB75E), const Color(0xFFED8F03)], // Warm Sun
    ];

    final palette = palettes[hash % palettes.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _CuteCatFacePainter(),
        ),
      ),
    );
  }
}

class _CuteCatFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintDark = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.fill;

    final paintNose = Paint()
      ..color = const Color(0xFFFF8A80)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Left Cat Ear
    final leftEar = Path()
      ..moveTo(w * 0.15, h * 0.45)
      ..lineTo(w * 0.08, h * 0.08)
      ..lineTo(w * 0.42, h * 0.28)
      ..close();
    canvas.drawPath(leftEar, paintWhite);

    // Right Cat Ear
    final rightEar = Path()
      ..moveTo(w * 0.85, h * 0.45)
      ..lineTo(w * 0.92, h * 0.08)
      ..lineTo(w * 0.58, h * 0.28)
      ..close();
    canvas.drawPath(rightEar, paintWhite);

    // Cat Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.58), w * 0.38, paintWhite);

    // Eyes
    canvas.drawCircle(Offset(w * 0.38, h * 0.52), w * 0.055, paintDark);
    canvas.drawCircle(Offset(w * 0.62, h * 0.52), w * 0.055, paintDark);

    // Cute Eye Highlights
    final paintHighlight = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.365, h * 0.505), w * 0.018, paintHighlight);
    canvas.drawCircle(Offset(w * 0.605, h * 0.505), w * 0.018, paintHighlight);

    // Tiny Triangle Nose
    final nose = Path()
      ..moveTo(w * 0.46, h * 0.62)
      ..lineTo(w * 0.54, h * 0.62)
      ..lineTo(w * 0.50, h * 0.67)
      ..close();
    canvas.drawPath(nose, paintNose);

    // Whiskers
    final paintWhisker = Paint()
      ..color = const Color(0xFF555555)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Left whiskers
    canvas.drawLine(
      Offset(w * 0.22, h * 0.61),
      Offset(w * 0.34, h * 0.62),
      paintWhisker,
    );
    canvas.drawLine(
      Offset(w * 0.20, h * 0.68),
      Offset(w * 0.33, h * 0.66),
      paintWhisker,
    );

    // Right whiskers
    canvas.drawLine(
      Offset(w * 0.66, h * 0.62),
      Offset(w * 0.78, h * 0.61),
      paintWhisker,
    );
    canvas.drawLine(
      Offset(w * 0.67, h * 0.66),
      Offset(w * 0.80, h * 0.68),
      paintWhisker,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
