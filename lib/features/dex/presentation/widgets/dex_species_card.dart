import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../domain/entities/feline_dex_species.dart';
import '../../domain/entities/iring_dex_entry.dart';

class DexSpeciesCard extends StatelessWidget {
  final IringDexEntry entry;
  final VoidCallback onTap;

  const DexSpeciesCard({super.key, required this.entry, required this.onTap});

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
          color: isDiscovered
              ? AppColors.dynamicSurface
              : AppColors.dynamicChromeTrack,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDiscovered
                ? rarityColor.withAlpha(90)
                : AppColors.dynamicBorder,
            width: isDiscovered ? 1.4 : 1.0,
          ),
          boxShadow: isDiscovered
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
                    color: isDiscovered
                        ? AppColors.dynamicTextSecondary
                        : const Color(0xFF8A7D75),
                  ),
                ),
                if (isDiscovered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withAlpha(35),
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
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: Color(0xFF8A7D75),
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
                      borderColor: rarityColor.withAlpha(90),
                      borderWidth: 2,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.dynamicChromeTrack,
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8A7D75),
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
                color: isDiscovered
                    ? AppColors.dynamicTextPrimary
                    : const Color(0xFF8A7D75),
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
                color: isDiscovered
                    ? AppColors.primary
                    : const Color(0xFF8A7D75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
