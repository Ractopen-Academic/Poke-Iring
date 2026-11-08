import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../../seasons/data/services/season_service_impl.dart';

/// Explorer physical activity metrics and lifetime prestige progress.
class DashboardStatsCard extends StatelessWidget {
  final String userId;

  const DashboardStatsCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Explorer Stats',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<ExplorerHealthSnapshot>(
          stream: ExplorerHealthService.instance.stream,
          initialData: ExplorerHealthService.instance.latest,
          builder: (context, snapshot) {
            final health = snapshot.data ?? ExplorerHealthSnapshot.empty();
            return Row(
              children: [
                Expanded(
                  child: DashboardStatTile(
                    label: 'Steps',
                    value: '${health.stepsToday}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatTile(
                    label: 'Distance',
                    value: '${health.distanceKm.toStringAsFixed(2)} km',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardStatTile(
                    label: 'Calories',
                    value: '${health.caloriesBurned.toStringAsFixed(0)} kcal',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    'Archived prestige',
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

  const DashboardStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.dynamicTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.dynamicTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
