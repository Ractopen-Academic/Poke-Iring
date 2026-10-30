import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../domain/entities/feline_dex_species.dart';
import '../../domain/entities/iring_dex_entry.dart';

class DexSpeciesCard extends StatelessWidget {
  final IringDexEntry entry;
  final VoidCallback onTap;

  const DexSpeciesCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  Color _rarityColor(FelineRarityTier rarity) {
    switch (rarity) {
      case FelineRarityTier.common:
        return const Color(0xFF4CAF50);
      case FelineRarityTier.uncommon:
        return const Color(0xFF009688);
      case FelineRarityTier.rare:
        return const Color(0xFF2196F3);
      case FelineRarityTier.veryRare:
        return const Color(0xFF9C27B0);
      case FelineRarityTier.mythic:
        return const Color(0xFFFF9800);
    }
  }

  @override
  Widget build(BuildContext context) {
    final species = entry.species;
    final isDiscovered = entry.isDiscovered;
    final rarityColor = _rarityColor(species.rarity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDiscovered ? Colors.white : const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDiscovered
                ? rarityColor.withAlpha(60)
                : Colors.grey.shade300,
            width: isDiscovered ? 1.5 : 1.0,
          ),
          boxShadow: isDiscovered
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  species.formattedNumber,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDiscovered ? AppColors.textSecondary : Colors.grey.shade500,
                  ),
                ),
                if (isDiscovered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rarityColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      species.rarity.displayName,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: rarityColor,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Center(
              child: isDiscovered
                  ? FelineAvatar(
                      photoUrl: entry.bestPhotoUrl,
                      seed: species.defaultSeed,
                      radius: 32,
                      showBorder: true,
                      borderColor: rarityColor.withAlpha(80),
                      borderWidth: 2,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),

            Text(
              isDiscovered ? species.name : '???',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDiscovered ? AppColors.textPrimary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),

            Text(
              isDiscovered
                  ? 'Sighted ${entry.timesSighted}x • +${entry.bestPawPoints} pts'
                  : 'Undiscovered',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDiscovered ? AppColors.primary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
