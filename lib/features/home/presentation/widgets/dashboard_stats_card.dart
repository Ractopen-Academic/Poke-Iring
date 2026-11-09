import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../../seasons/data/services/season_service_impl.dart';

/// Explorer gamified physical patrol activity metrics and lifetime prestige progress.
class DashboardStatsCard extends StatelessWidget {
  final String userId;

  const DashboardStatsCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Territory Patrol Activity',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
            Text(
              'Daily Walk Sync',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.dynamicTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<ExplorerHealthSnapshot>(
          stream: ExplorerHealthService.instance.stream,
          initialData: ExplorerHealthService.instance.latest,
          builder: (context, snapshot) {
            final health = snapshot.data ?? ExplorerHealthSnapshot.empty();
            final treatsEarned = (health.stepsToday / 500).floor();

            return Row(
              children: [
                Expanded(
                  child: DashboardStatTile(
                    label: 'Patrol Steps',
                    value: '${health.stepsToday}',
                    icon: Icons.directions_walk_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardStatTile(
                    label: 'Patrol Dist.',
                    value: '${health.distanceKm.toStringAsFixed(2)} km',
                    icon: Icons.map_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardStatTile(
                    label: 'Cat Treats',
                    value: '$treatsEarned Treats',
                    icon: Icons.pets_rounded,
                    highlight: true,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<int>(
          stream: SeasonServiceImpl.instance.watchMythicPrestige(userId),
          initialData: 0,
          builder: (context, snapshot) {
            final prestige = snapshot.data ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.dynamicSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFB300).withAlpha(120),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 22,
                    color: Color(0xFFFFA000),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lifetime Mythic Prestige',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CalicoThemeController.instance.isCalicoLight
                                ? const Color(0xFFE65100)
                                : const Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$prestige Points',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Archived rank',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.dynamicTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class DashboardStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;

  const DashboardStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withAlpha(90)
              : AppColors.dynamicBorder,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: highlight
                  ? AppColors.primary
                  : AppColors.dynamicTextSecondary,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.primary
                  : AppColors.dynamicTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
