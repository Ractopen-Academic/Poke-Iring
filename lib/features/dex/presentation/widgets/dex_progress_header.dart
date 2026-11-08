import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/iring_dex_entry.dart';

class DexProgressHeader extends StatelessWidget {
  final List<IringDexEntry> entries;

  const DexProgressHeader({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final total = entries.length;
    final discovered = entries.where((e) => e.isDiscovered).length;
    final ratio = total > 0 ? (discovered / total) : 0.0;
    final percentage = (ratio * 100).toInt();

    final totalPoints = entries.fold<int>(0, (sum, e) => sum + e.bestPawPoints);

    String rankTitle = 'Novice Tracker';
    if (discovered >= 12) {
      rankTitle = 'Feline Grandmaster';
    } else if (discovered >= 8) {
      rankTitle = 'Master Observer';
    } else if (discovered >= 4) {
      rankTitle = 'Neighborhood Scout';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iring-Dex Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dynamicTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$discovered of $total Species Cataloged ($percentage%)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withAlpha(90)),
                ),
                child: Text(
                  rankTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: const Color(0x1FFFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricPill(
                icon: Icons.check_circle_outline_rounded,
                label: 'Discovered',
                value: '$discovered',
              ),
              _MetricPill(
                icon: Icons.lock_outline_rounded,
                label: 'Remaining',
                value: '${total - discovered}',
              ),
              _MetricPill(
                icon: Icons.pets_rounded,
                label: 'Dex Value',
                value: '+$totalPoints pts',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB3A89D),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
