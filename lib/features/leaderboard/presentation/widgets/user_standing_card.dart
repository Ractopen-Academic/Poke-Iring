import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_query.dart';

class UserStandingCard extends StatelessWidget {
  final LeaderboardEntry? standing;
  final LeaderboardScope scope;
  final LeaderboardCategory category;
  final String? territoryLabel;
  final VoidCallback? onChangeTerritory;

  const UserStandingCard({
    super.key,
    required this.standing,
    required this.scope,
    required this.category,
    this.territoryLabel,
    this.onChangeTerritory,
  });

  @override
  Widget build(BuildContext context) {
    if (standing == null) return const SizedBox.shrink();

    final user = standing!;
    final tier = user.tier;
    final nextThreshold = tier.nextThreshold;
    final progress = tier.progress(user.points);
    final ptsToNext = tier.pointsToNextTier(user.points);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          const TextSpan(text: 'You are at '),
                          TextSpan(
                            text: 'Rank #${user.rank}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: ' with '),
                          TextSpan(
                            text: user.formattedScore(category),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            territoryLabel != null
                                ? '$territoryLabel • ${scope.label} (${scope.poolCapacity} explorers)'
                                : '${scope.label} pool of ${scope.poolCapacity} explorers',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (onChangeTerritory != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onChangeTerritory,
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tier.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tier.color.withAlpha(80),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tier.divisionLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: tier.color.withAlpha(180),
                      ),
                    ),
                    Text(
                      tier.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: tier.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(tier.color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tier.divisionLabel} of 6: ${tier.displayName}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: tier.color,
                ),
              ),
              Text(
                nextThreshold != null
                    ? '$ptsToNext pts to next division'
                    : 'Max Tier Achieved',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
