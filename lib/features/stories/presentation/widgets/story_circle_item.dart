import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';

/// Renders a story circle item displaying a slightly blurred preview of the
/// actual MyDay media content with an author badge and viewed status ring.
class StoryCircleItem extends StatelessWidget {
  final String label;
  final String seed;
  final String? storyMediaUrl;
  final String? authorAvatarUrl;
  final String? catBreed;
  final bool isUser;
  final bool hasActiveUserStory;
  final bool isViewed;
  final VoidCallback onTap;
  final VoidCallback? onAddTap;

  const StoryCircleItem({
    super.key,
    required this.label,
    required this.seed,
    this.storyMediaUrl,
    this.authorAvatarUrl,
    this.catBreed,
    this.isUser = false,
    this.hasActiveUserStory = false,
    this.isViewed = false,
    required this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Outer Story Ring
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (isUser && !hasActiveUserStory)
                        ? null
                        : isViewed
                        ? const LinearGradient(
                            colors: [Color(0xFF6B625B), Color(0xFF8A7F77)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFFFF5E36),
                              Color(0xFFFFAE33),
                              Color(0xFFFF2A6D),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                    border: (isUser && !hasActiveUserStory)
                        ? Border.all(
                            color: AppColors.primary.withAlpha(80),
                            width: 1.5,
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(2.2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dynamicSurface,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: _buildStoryCoreContent(),
                      ),
                    ),
                  ),
                ),

                // Author Mini Badge (for stories by other explorers or user's active story)
                if (!isUser || hasActiveUserStory)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: AppColors.dynamicSurface,
                        shape: BoxShape.circle,
                      ),
                      child: isUser && hasActiveUserStory
                          ? GestureDetector(
                              onTap: onAddTap ?? onTap,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : FelineAvatar(
                              photoUrl: authorAvatarUrl,
                              seed: seed,
                              radius: 8.5,
                            ),
                    ),
                  ),

                // Add button for user without active story
                if (isUser && !hasActiveUserStory)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.dynamicSurface,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.15,
                fontWeight: isViewed ? FontWeight.w500 : FontWeight.w700,
                color: isViewed
                    ? AppColors.dynamicTextSecondary
                    : AppColors.dynamicTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the inner core of the story circle.
  /// If story media is available, renders a slightly blurred preview with depth overlay.
  /// Otherwise, renders graceful artistic fallback.
  Widget _buildStoryCoreContent() {
    // If it's the user and they have no active story, show their profile avatar directly
    if (isUser && !hasActiveUserStory) {
      return FelineAvatar(photoUrl: authorAvatarUrl, seed: seed, radius: 24);
    }

    // If story media URL is present and valid
    if (storyMediaUrl != null && storyMediaUrl!.trim().isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildFilteredStoryImage(storyMediaUrl!.trim()),
          // Subtle dark vignette to give depth to the blur
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isViewed
                    ? [Colors.black.withAlpha(70), Colors.black.withAlpha(110)]
                    : [Colors.black.withAlpha(25), Colors.black.withAlpha(65)],
              ),
            ),
          ),
        ],
      );
    }

    // Graceful fallback for stories with empty/missing media
    return _buildStylizedBreedFallback();
  }

  /// Renders image source with hardware-accelerated slight blur.
  Widget _buildFilteredStoryImage(String url) {
    Widget imageWidget;

    if (url.startsWith('data:image')) {
      // Base64 data URI (offline or freshly captured local stories)
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildStylizedBreedFallback(),
        );
      } catch (_) {
        imageWidget = _buildStylizedBreedFallback();
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      // Network URL with caching and thumbnail memory optimization
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 150,
        memCacheHeight: 150,
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildStylizedBreedFallback(),
      );
    } else if (url.startsWith('file://') || url.startsWith('/')) {
      // Local file path
      imageWidget = Image.file(
        File(url.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildStylizedBreedFallback(),
      );
    } else {
      // Fallback
      imageWidget = _buildStylizedBreedFallback();
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
      child: imageWidget,
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      color: const Color(0xFF2C2825),
      child: const Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFFFF8F00),
          ),
        ),
      ),
    );
  }

  Widget _buildStylizedBreedFallback() {
    // Generate harmonious colors based on cat breed / seed
    final hash = (catBreed ?? seed).hashCode.abs();
    final hue1 = (hash % 360).toDouble();
    final color1 = HSLColor.fromAHSL(1.0, hue1, 0.65, 0.35).toColor();
    final color2 = HSLColor.fromAHSL(
      1.0,
      (hue1 + 45) % 360,
      0.7,
      0.22,
    ).toColor();

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 1.8, sigmaY: 1.8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.35,
              child: FelineAvatar(
                photoUrl: authorAvatarUrl,
                seed: seed,
                radius: 20,
              ),
            ),
            Container(color: Colors.black.withAlpha(30)),
          ],
        ),
      ),
    );
  }
}
