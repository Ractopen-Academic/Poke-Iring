import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';

class StoryCircleItem extends StatelessWidget {
  final String label;
  final String seed;
  final String? photoUrl;
  final bool isUser;
  final bool isViewed;
  final VoidCallback onTap;

  const StoryCircleItem({
    super.key,
    required this.label,
    required this.seed,
    this.photoUrl,
    this.isUser = false,
    this.isViewed = false,
    required this.onTap,
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
              alignment: Alignment.center,
              children: [
                // Instagram-style gradient ring
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUser
                        ? null
                        : isViewed
                        ? const LinearGradient(
                            colors: [Color(0xFFBDBDBD), Color(0xFFE0E0E0)],
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
                    color: isUser ? Colors.transparent : null,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: FelineAvatar(
                      photoUrl: photoUrl,
                      seed: seed,
                      radius: 25,
                    ),
                  ),
                ),
                if (isUser)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isViewed ? FontWeight.w500 : FontWeight.w700,
                color: isViewed
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
