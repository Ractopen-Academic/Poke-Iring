import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/season_service_impl.dart';
import '../../domain/entities/season_period.dart';
import 'season_rollover_dialog.dart';

class SeasonDetailsSheet extends StatelessWidget {
  final SeasonPeriod season;
  final String userId;
  final int userPoints;
  final int userRank;
  final String divisionTitle;
  final VoidCallback? onRolloverCompleted;

  const SeasonDetailsSheet({
    super.key,
    required this.season,
    required this.userId,
    required this.userPoints,
    required this.userRank,
    required this.divisionTitle,
    this.onRolloverCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required SeasonPeriod season,
    required String userId,
    required int userPoints,
    required int userRank,
    required String divisionTitle,
    VoidCallback? onRolloverCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SeasonDetailsSheet(
        season: season,
        userId: userId,
        userPoints: userPoints,
        userRank: userRank,
        divisionTitle: divisionTitle,
        onRolloverCompleted: onRolloverCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projected = SeasonServiceImpl.instance.calculateRollover(
      userId: userId,
      season: season,
      currentPoints: userPoints,
      currentRank: userRank,
      divisionTitle: divisionTitle,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        season.remainingFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              season.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            // Projected Rollover Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Projected Season Rewards',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RewardMetricRow(
                    label: 'Current Standing',
                    value: '$divisionTitle (#$userRank)',
                  ),
                  const SizedBox(height: 6),
                  _RewardMetricRow(
                    label: 'Lifetime Mythic Prestige',
                    value: '+${projected.prestigeEarned} Points',
                    highlight: true,
                  ),
                  const SizedBox(height: 6),
                  _RewardMetricRow(
                    label: 'Permanent Trophy Crest',
                    value: projected.trophyCrest.label,
                  ),
                  const SizedBox(height: 6),
                  _RewardMetricRow(
                    label: 'Next Season Starting Floor',
                    value:
                        '${projected.startingPlacementDivision} (${projected.startingPlacementPoints} pts)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Soft Reset Rules Accordion / Cards
            const Text(
              'How Seasonal Resets Work',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _RuleStepTile(
              stepNumber: '1',
              title: 'Soft Reset Placement',
              description: 'Paw points compress into placement brackets so new explorers can compete while veteran ranks earn higher starting floors.',
            ),
            const SizedBox(height: 8),
            _RuleStepTile(
              stepNumber: '2',
              title: 'Mythic Prestige Minting',
              description: '100% of seasonal points plus top-tier rank bonuses are minted into permanent Mythic Prestige points on your profile.',
            ),
            const SizedBox(height: 8),
            _RuleStepTile(
              stepNumber: '3',
              title: 'Permanent Trophy Crests',
              description: 'Gold, Silver, and Bronze Mythic Paws are permanently archived to your Explorer Showcase.',
            ),
            const SizedBox(height: 20),
            // Simulate rollover button
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final record = await SeasonServiceImpl.instance
                    .completeSeasonRollover(
                      userId: userId,
                      currentPoints: userPoints,
                      currentRank: userRank,
                      divisionTitle: divisionTitle,
                    );
                if (context.mounted) {
                  SeasonRolloverDialog.show(context, record);
                  onRolloverCompleted?.call();
                }
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text(
                'Simulate Season Rollover Ceremony',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _RewardMetricRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleStepTile extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;

  const _RuleStepTile({
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
