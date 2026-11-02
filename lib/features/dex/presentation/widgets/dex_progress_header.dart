import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
import '../../domain/entities/iring_dex_entry.dart';

class DexProgressHeader extends StatelessWidget {
  final List<IringDexEntry> entries;

  const DexProgressHeader({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final isGirly = GirlyThemeProvider.isGirly(context);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGirly ? GirlyColors.border : AppColors.border,
        ),
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
                      color: isGirly
                          ? GirlyColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$discovered of $total Species Cataloged ($percentage%)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isGirly
                          ? GirlyColors.textSecondary
                          : AppColors.textSecondary,
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
                  color: (isGirly ? GirlyColors.primary : AppColors.primary)
                      .withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isGirly ? GirlyColors.primary : AppColors.primary)
                        .withAlpha(50),
                  ),
                ),
                child: Text(
                  rankTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        isGirly ? GirlyColors.primaryDark : AppColors.primary,
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
              backgroundColor:
                  isGirly ? GirlyColors.creamSurface : const Color(0xFFEEEEF2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isGirly ? GirlyColors.primaryDark : AppColors.primary,
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
    final isGirly = GirlyThemeProvider.isGirly(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isGirly ? GirlyColors.primaryLight : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGirly ? GirlyColors.border : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isGirly ? GirlyColors.primaryDark : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isGirly
                      ? GirlyColors.textSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color:
                      isGirly ? GirlyColors.textPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
