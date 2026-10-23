import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/live_sighting.dart';

class CatMarkerAvatar extends StatelessWidget {
  final LiveSighting sighting;
  final VoidCallback onTap;

  const CatMarkerAvatar({
    super.key,
    required this.sighting,
    required this.onTap,
  });

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'mythic':
        return const Color(0xFF7B1FA2);
      case 'rare':
        return const Color(0xFF0288D1);
      case 'common':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(sighting.rarity);
    final remainingMinutes = sighting.remainingTime.inMinutes;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: rarityColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.pets, size: 22, color: rarityColor),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${remainingMinutes}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
