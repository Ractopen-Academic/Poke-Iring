import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/cat_scan_result.dart';

class PawPointsGuideSheet extends StatelessWidget {
  const PawPointsGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PawPointsGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'How Paw Points Work',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Paw Points measure your neighborhood feline discoveries and determine your leaderboard standing.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            _buildSection(
              title: 'Points Scoring Formula',
              items: [
                _GuideItem(
                  label: 'Base Sighting',
                  value: '+50 pts',
                  description: 'Awarded for any live feline verified by the vision scanner.',
                ),
                _GuideItem(
                  label: 'Coat Markings Bonus',
                  value: '+10 to +40 pts',
                  description: 'Calico (+35), Tortoiseshell (+35), Tuxedo (+20), Tabby (+15), Solid (+10).',
                ),
                _GuideItem(
                  label: 'Breed Rarity Multiplier',
                  value: '1.0x to 2.0x',
                  description: 'Applies to (Base + Markings). Common Puspin is 1.0x–1.2x; purebreds reach up to 2.0x.',
                ),
                _GuideItem(
                  label: 'Community Boops',
                  value: '+5 pts each',
                  description: 'Earned every time a fellow explorer boops your cat pin on the live map or story.',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: 'Fair-Play Points Caps',
              items: [
                _GuideItem(
                  label: 'Max Per Sighting',
                  value: '${CatScanResult.maxSingleSightingPoints} pts cap',
                  description:
                      'A single feline encounter cannot exceed ${CatScanResult.maxSingleSightingPoints} points, preventing point inflation.',
                ),
                _GuideItem(
                  label: 'Daily Sighting Soft Cap',
                  value: '${CatScanResult.dailyPawPointsSoftCap} pts / day',
                  description: 'Encourages genuine exploration. Beyond 500 points/day, sightings award +10 baseline exploration points.',
                ),
              ],
            ),
            const SizedBox(height: 20),

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
                'Got It',
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
    required List<_GuideItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem {
  final String label;
  final String value;
  final String description;

  const _GuideItem({
    required this.label,
    required this.value,
    required this.description,
  });
}
