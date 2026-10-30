import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../domain/entities/live_sighting.dart';

class CatMarkerAvatar extends StatelessWidget {
  final CatSighting? catSighting;
  final LiveSighting? liveSighting;
  final VoidCallback onTap;

  const CatMarkerAvatar({
    super.key,
    required LiveSighting sighting,
    required this.onTap,
  }) : liveSighting = sighting,
       catSighting = null;

  const CatMarkerAvatar.fromSighting({
    super.key,
    required CatSighting sighting,
    required this.onTap,
  }) : catSighting = sighting,
       liveSighting = null;

  bool get _isSilhouette {
    if (catSighting != null) return catSighting!.isSilhouettePhase;
    if (liveSighting != null) return liveSighting!.isSilhouettePhase;
    return false;
  }

  double get _opacity {
    if (catSighting != null) return catSighting!.spawnOpacity;
    if (liveSighting != null) return liveSighting!.markerOpacity;
    return 1.0;
  }

  String get _metallicTier {
    if (catSighting != null) return catSighting!.metallicTier;
    if (liveSighting != null) return liveSighting!.metallicTier;
    return 'bronze';
  }

  String get _remainingLabel {
    if (catSighting != null) return catSighting!.remainingFormatted;
    if (liveSighting != null) return liveSighting!.remainingFormatted;
    return '10m';
  }

  String get _imageUri {
    if (catSighting != null) {
      return catSighting!.stickerUrl.isNotEmpty
          ? catSighting!.stickerUrl
          : catSighting!.photoUrl;
    }
    if (liveSighting != null) {
      return liveSighting!.thumbnailUrl;
    }
    return '';
  }

  Color _getMetallicBorderColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFCFD8DC);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Color _getMetallicGlowColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700).withAlpha(140);
      case 'silver':
        return const Color(0xFF90A4AE).withAlpha(110);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32).withAlpha(90);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getMetallicBorderColor(_metallicTier);
    final glowColor = _getMetallicGlowColor(_metallicTier);
    final isSilhouette = _isSilhouette;
    final opacity = _opacity;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSilhouette ? const Color(0xFF1E272C) : Colors.white,
                border: Border.all(
                  color: borderColor,
                  width: _metallicTier == 'gold' ? 3.2 : 2.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: _metallicTier == 'gold' ? 10 : 6,
                    spreadRadius: _metallicTier == 'gold' ? 1.5 : 0.5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: isSilhouette
                    ? _buildSilhouetteAvatar()
                    : _buildVibrantAvatar(),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSilhouette
                    ? const Color(0xFF1A1A1A).withAlpha(220)
                    : Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor.withAlpha(isSilhouette ? 180 : 100),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_metallicTier == 'gold') ...[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    isSilhouette ? 'Shadow $_remainingLabel' : _remainingLabel,
                    style: TextStyle(
                      color: isSilhouette
                          ? const Color(0xFFFFD700)
                          : Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrantAvatar() {
    final uri = _imageUri;
    if (uri.isNotEmpty) {
      if (uri.startsWith('data:image')) {
        try {
          final b64 = uri.contains(',') ? uri.split(',').last : uri;
          return Image.memory(
            base64Decode(b64),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _fallbackIcon(Colors.black87),
          );
        } catch (_) {}
      } else {
        return CachedNetworkImage(
          imageUrl: uri,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _fallbackIcon(Colors.black87),
        );
      }
    }
    return _fallbackIcon(AppColors.primary);
  }

  Widget _buildSilhouetteAvatar() {
    final uri = _imageUri;
    if (uri.isNotEmpty) {
      if (uri.startsWith('data:image')) {
        try {
          final b64 = uri.contains(',') ? uri.split(',').last : uri;
          return ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFF101416),
              BlendMode.srcIn,
            ),
            child: Image.memory(
              base64Decode(b64),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _silhouetteIcon(),
            ),
          );
        } catch (_) {}
      } else {
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFF101416),
            BlendMode.srcIn,
          ),
          child: CachedNetworkImage(
            imageUrl: uri,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _silhouetteIcon(),
          ),
        );
      }
    }
    return _silhouetteIcon();
  }

  Widget _silhouetteIcon() {
    return Container(
      color: const Color(0xFF1E272C),
      alignment: Alignment.center,
      child: const Icon(Icons.pets, size: 22, color: Color(0xFF101416)),
    );
  }

  Widget _fallbackIcon(Color color) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(Icons.pets, size: 22, color: color),
    );
  }
}
