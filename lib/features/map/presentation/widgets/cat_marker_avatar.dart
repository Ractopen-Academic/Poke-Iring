import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../domain/entities/live_sighting.dart';

class CatMarkerAvatar extends StatefulWidget {
  final CatSighting? catSighting;
  final LiveSighting? liveSighting;
  final VoidCallback onTap;
  final VoidCallback? onBoop;

  const CatMarkerAvatar({
    super.key,
    required LiveSighting sighting,
    required this.onTap,
    this.onBoop,
  }) : liveSighting = sighting,
       catSighting = null;

  const CatMarkerAvatar.fromSighting({
    super.key,
    required CatSighting sighting,
    required this.onTap,
    this.onBoop,
  }) : catSighting = sighting,
       liveSighting = null;

  @override
  State<CatMarkerAvatar> createState() => _CatMarkerAvatarState();
}

class _CatMarkerAvatarState extends State<CatMarkerAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  int _localBoops = 0;
  bool _showBoopPlus = false;

  @override
  void initState() {
    super.initState();
    _localBoops = widget.catSighting?.boopsCount ?? 0;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant CatMarkerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentBoops = widget.catSighting?.boopsCount ?? 0;
    final oldBoops = oldWidget.catSighting?.boopsCount ?? 0;
    if (currentBoops > oldBoops) {
      _localBoops = currentBoops;
      _triggerBoopAnimation();
    }
  }

  Timer? _hideBoopTimer;

  @override
  void dispose() {
    _hideBoopTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  void _triggerBoopAnimation() {
    if (!mounted) return;
    setState(() {
      _showBoopPlus = true;
    });
    _bounceController.forward(from: 0.0);
    _hideBoopTimer?.cancel();
    _hideBoopTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showBoopPlus = false;
        });
      }
    });
  }

  void _handleDirectBoop() {
    if (widget.onBoop == null) {
      widget.onTap();
      return;
    }
    setState(() {
      _localBoops++;
    });
    _triggerBoopAnimation();
    widget.onBoop!();
  }

  bool get _isSilhouette {
    if (widget.catSighting != null) {
      return widget.catSighting!.isSilhouettePhase;
    }
    if (widget.liveSighting != null) {
      return widget.liveSighting!.isSilhouettePhase;
    }
    return false;
  }

  double get _opacity {
    if (widget.catSighting != null) return widget.catSighting!.spawnOpacity;
    if (widget.liveSighting != null) {
      return widget.liveSighting!.markerOpacity;
    }
    return 1.0;
  }

  String get _metallicTier {
    if (widget.catSighting != null) return widget.catSighting!.metallicTier;
    if (widget.liveSighting != null) return widget.liveSighting!.metallicTier;
    return 'bronze';
  }

  double get _rarityMultiplier {
    if (widget.catSighting != null) {
      return widget.catSighting!.rarityMultiplier;
    }
    if (widget.liveSighting != null) {
      switch (widget.liveSighting!.metallicTier.toLowerCase()) {
        case 'gold':
          return 2.0;
        case 'silver':
          return 1.5;
        default:
          return 1.0;
      }
    }
    return 1.0;
  }

  String get _remainingLabel {
    if (widget.catSighting != null) {
      return widget.catSighting!.remainingFormatted;
    }
    if (widget.liveSighting != null) {
      return widget.liveSighting!.remainingFormatted;
    }
    return '10m';
  }

  String get _imageUri {
    if (widget.catSighting != null) {
      return widget.catSighting!.stickerUrl.isNotEmpty
          ? widget.catSighting!.stickerUrl
          : widget.catSighting!.photoUrl;
    }
    if (widget.liveSighting != null) {
      return widget.liveSighting!.thumbnailUrl;
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
    final multiplierText = '${_rarityMultiplier.toStringAsFixed(1)}x';

    return GestureDetector(
      onTap: widget.onTap,
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: 68,
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Top Rarity Multiplier Tag
              Positioned(
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSilhouette
                        ? const Color(0xFF1E272C)
                        : Colors.black.withAlpha(210),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: borderColor,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        multiplierText,
                        style: TextStyle(
                          color: borderColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Center Die-Cut Sticker Frame
              Positioned(
                top: 17,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSilhouette
                            ? const Color(0xFF14191C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSilhouette
                              ? const Color(0xFF263238)
                              : Colors.white,
                          width: 2.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                              isSilhouette ? 70 : 50,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: glowColor,
                            blurRadius: _metallicTier == 'gold' ? 8 : 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: isSilhouette
                            ? _buildSilhouetteAvatar()
                            : _buildVibrantAvatar(),
                      ),
                    ),

                    // Pointer Tip Triangle
                    CustomPaint(
                      size: const Size(8, 4),
                      painter: _TrianglePointerPainter(
                        color: isSilhouette
                            ? const Color(0xFF263238)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Community Boop Counter Badge
              Positioned(
                top: 44,
                right: 0,
                child: GestureDetector(
                  onTap: _handleDirectBoop,
                  behavior: HitTestBehavior.opaque,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5252).withAlpha(120),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 8,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_localBoops',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating "+5" Boop Reward Indicator
              if (_showBoopPlus)
                Positioned(
                  top: 28,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Text(
                      '+5',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

              // Bottom Remaining Countdown Label
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSilhouette
                        ? const Color(0xFF1A1A1A).withAlpha(230)
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
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        isSilhouette
                            ? 'Shadow $_remainingLabel'
                            : _remainingLabel,
                        style: TextStyle(
                          color: isSilhouette
                              ? const Color(0xFFFFD700)
                              : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      child: const Icon(Icons.pets, size: 20, color: Color(0xFF101416)),
    );
  }

  Widget _fallbackIcon(Color color) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(Icons.pets, size: 20, color: color),
    );
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;

  const _TrianglePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
