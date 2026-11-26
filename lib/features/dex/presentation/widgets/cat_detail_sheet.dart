import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../domain/entities/feline_dex_species.dart';
import '../../domain/entities/iring_dex_entry.dart';

class CatDetailSheet extends StatefulWidget {
  final IringDexEntry entry;

  const CatDetailSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, IringDexEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CatDetailSheet(entry: entry),
    );
  }

  @override
  State<CatDetailSheet> createState() => _CatDetailSheetState();
}

class _CatDetailSheetState extends State<CatDetailSheet> {
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

  Future<void> _handleShareCard() async {
    final species = widget.entry.species;
    final location = widget.entry.bestLocation ?? 'Local territory';
    final summary =
        'Poke: Iring Discovery — ${species.formattedNumber} ${species.name} '
        '(${species.commonName}) | ${species.rarity.displayName} | '
        '+${widget.entry.bestPawPoints} Paw Points | Spotted in $location';
    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${species.name} discovery card summary to clipboard.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final species = entry.species;
    final rarityColor = _rarityColor(species.rarity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF554A43),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: entry.isDiscovered
                              ? rarityColor.withAlpha(40)
                              : Colors.black.withAlpha(25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FelineAvatar(
                      photoUrl: entry.bestPhotoUrl,
                      seed: entry.isDiscovered
                          ? species.defaultSeed
                          : 'undiscovered_mystery',
                      radius: 54,
                      showBorder: true,
                      borderColor: entry.isDiscovered
                          ? rarityColor
                          : const Color(0xFF554A43),
                      borderWidth: 3,
                    ),
                  ),
                  if (entry.isDiscovered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x${entry.timesSighted}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                species.formattedNumber,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFC2B5A8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                entry.isDiscovered ? species.name : 'Unknown Feline',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
            ),
            Center(
              child: Text(
                species.commonName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dynamicTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rarityColor.withAlpha(90)),
                  ),
                  child: Text(
                    species.rarity.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rarityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicFieldFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dynamicBorder),
                  ),
                  child: Text(
                    species.coatPattern,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dynamicTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(90)),
                  ),
                  child: Text(
                    '${species.rarity.defaultMultiplier}x Points',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Species Field Notes',
              content: species.description,
            ),
            const SizedBox(height: 12),

            _buildSection(title: 'Typical Habitat', content: species.habitat),
            const SizedBox(height: 16),

            if (entry.isDiscovered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dynamicFieldFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dynamicBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Discovery Records',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRecordRow(
                      'First Sighted',
                      _formatDate(entry.firstSightedAt),
                    ),
                    _buildRecordRow(
                      'Best Encounter',
                      entry.bestLocation ?? 'Local territory',
                    ),
                    _buildRecordRow(
                      'Highest Reward',
                      '+${entry.bestPawPoints} Paw Points',
                    ),
                    if (entry.sightings.isNotEmpty &&
                        entry.sightings.first.quirk.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '"${entry.sightings.first.quirk}"',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Share action button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleShareCard,
                  icon: Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: AppColors.dynamicTextPrimary,
                  ),
                  label: Text(
                    'Share Discovery Card',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dynamicTextPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.dynamicFieldFill,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(color: AppColors.dynamicBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dynamicChromeTrack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dynamicBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Undiscovered in your Iring-Dex. Point your scanner camera at neighborhood cats to reveal this record.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Close Record',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.dynamicTextSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.dynamicTextPrimary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.dynamicTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.dynamicTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
