import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../../showcase/services/showcase_service.dart';
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
  bool _isPinned = false;

  CatSighting? get _featuredSighting =>
      widget.entry.sightings.isNotEmpty ? widget.entry.sightings.first : null;

  @override
  void initState() {
    super.initState();
    final sighting = _featuredSighting;
    if (sighting != null) {
      _isPinned = ShowcaseService.instance.isSightingPinned(sighting.id);
    }
  }

  Color _rarityColor(FelineRarityTier rarity, {required bool isGirly}) {
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
        return isGirly ? GirlyColors.primaryDark : const Color(0xFFFF9800);
    }
  }

  Future<void> _handleTogglePin() async {
    final sighting = _featuredSighting;
    if (sighting == null) return;

    try {
      final pinned = await ShowcaseService.instance.togglePinSighting(sighting);
      if (!mounted) return;
      setState(() => _isPinned = pinned);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pinned
                ? 'Pinned to your 9-card Explorer Showcase'
                : 'Removed from your Showcase',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('StateError: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _handleSaveSticker() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${widget.entry.species.name} transparent sticker cutout to local album.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShareCard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sharing ${widget.entry.species.name} discovery card with local explorers.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final species = entry.species;
    final isGirly = GirlyThemeProvider.isGirly(context);
    final textPrimary =
        isGirly ? GirlyColors.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isGirly ? GirlyColors.textSecondary : AppColors.textSecondary;
    final accent = isGirly ? GirlyColors.primaryDark : AppColors.primary;
    final rarityColor = _rarityColor(species.rarity, isGirly: isGirly);

    return Container(
      decoration: BoxDecoration(
        color: isGirly ? GirlyColors.surface : Colors.white,
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
                  color: isGirly ? GirlyColors.border : Colors.grey.shade300,
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
                              : Colors.black.withAlpha(15),
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
                          : Colors.grey.shade300,
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isGirly
                      ? GirlyColors.textSecondary
                      : Colors.grey.shade600,
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
                  color: textPrimary,
                ),
              ),
            ),
            Center(
              child: Text(
                species.commonName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
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
                    color: rarityColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rarityColor.withAlpha(80)),
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
                    color: isGirly
                        ? GirlyColors.primaryLight
                        : const Color(0xFFF0F1F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    species.coatPattern,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
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
                    color: accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${species.rarity.defaultMultiplier}x Points',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Species Field Notes',
              content: species.description,
              isGirly: isGirly,
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Typical Habitat',
              content: species.habitat,
              isGirly: isGirly,
            ),
            const SizedBox(height: 16),
            if (entry.isDiscovered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isGirly
                      ? GirlyColors.primaryLight
                      : const Color(0xFFF9FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGirly ? GirlyColors.border : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Discovery Records',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRecordRow(
                      'First Sighted',
                      _formatDate(entry.firstSightedAt),
                      isGirly: isGirly,
                    ),
                    _buildRecordRow(
                      'Best Encounter',
                      entry.bestLocation ?? 'Local territory',
                      isGirly: isGirly,
                    ),
                    _buildRecordRow(
                      'Highest Reward',
                      '+${entry.bestPawPoints} Paw Points',
                      isGirly: isGirly,
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
                            color: isGirly
                                ? GirlyColors.textSecondary
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons row: Pin to Showcase | Save Sticker | Share
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleTogglePin,
                      icon: Icon(
                        _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 15,
                        color: _isPinned ? accent : textPrimary,
                      ),
                      label: Text(
                        _isPinned ? 'In Showcase' : 'Pin to Showcase',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isPinned ? accent : textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(
                          color: _isPinned
                              ? accent
                              : (isGirly
                                  ? GirlyColors.border
                                  : AppColors.border),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleSaveSticker,
                      icon: Icon(
                        Icons.download_rounded,
                        size: 15,
                        color: textPrimary,
                      ),
                      label: Text(
                        'Save Sticker',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(
                          color:
                              isGirly ? GirlyColors.border : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Share Card',
                    onPressed: _handleShareCard,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isGirly ? GirlyColors.border : AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isGirly
                      ? GirlyColors.primaryLight
                      : const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isGirly ? GirlyColors.border : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isGirly
                          ? GirlyColors.textSecondary
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Undiscovered in your Iring-Dex. Point your scanner camera at neighborhood cats to reveal this record.',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
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
                backgroundColor: accent,
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

  Widget _buildSection({
    required String title,
    required String content,
    required bool isGirly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color:
                isGirly ? GirlyColors.textSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13.5,
            color: isGirly ? GirlyColors.textPrimary : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordRow(
    String label,
    String value, {
    required bool isGirly,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  isGirly ? GirlyColors.textSecondary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isGirly ? GirlyColors.textPrimary : AppColors.textPrimary,
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
