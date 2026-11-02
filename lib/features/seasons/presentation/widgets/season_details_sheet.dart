import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
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
    final isGirly = GirlyThemeProvider.isGirly(context);
    final accent = isGirly ? GirlyColors.primaryDark : AppColors.primary;
    final textPrimary =
        isGirly ? GirlyColors.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isGirly ? GirlyColors.textSecondary : AppColors.textSecondary;
    final projected = SeasonServiceImpl.instance.calculateRollover(
      userId: userId,
      season: season,
      currentPoints: userPoints,
      currentRank: userRank,
      divisionTitle: divisionTitle,
    );

    return Container(
      decoration: BoxDecoration(
        color: isGirly ? GirlyColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: isGirly ? GirlyColors.border : AppColors.border,
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
                    color: accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_repeat_rounded,
                    color: accent,
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
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        season.remainingFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
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
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            // Projected Rollover Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isGirly ? GirlyColors.primaryLight : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGirly ? GirlyColors.border : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        size: 18,
                        color:
                            isGirly ? GirlyColors.primary : AppColors.secondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Projected Season Rewards',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RewardMetricRow(
                    label: 'Current Standing',
                    value: '$divisionTitle (#$userRank)',
                    isGirly: isGirly,
                  ),
                  const SizedBox(height: 6),
                  _RewardMetricRow(
                    label: 'Lifetime Mythic Prestige',
                    value: '+${projected.prestigeEarned} Points',
                    highlight: true,
                    isGirly: isGirly,
                  ),
                  const SizedBox(height: 6),
                  _RewardMetricRow(
                    label: 'Permanent Trophy Crest',
                    value: projected.trophyCrest.label,
                    isGirly: isGirly,
                  ),
                  const SizedBox(height: 6),
                  _RewardMetricRow(
                    label: 'Next Season Starting Floor',
                    value:
                        '${projected.startingPlacementDivision} (${projected.startingPlacementPoints} pts)',
                    isGirly: isGirly,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Soft Reset Rules Accordion / Cards
            Text(
              'How Seasonal Resets Work',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _RuleStepTile(
              stepNumber: '1',
              title: 'Soft Reset Placement',
              description:
                  'Paw points compress into placement brackets so new explorers can compete while veteran ranks earn higher starting floors.',
              isGirly: isGirly,
            ),
            const SizedBox(height: 8),
            _RuleStepTile(
              stepNumber: '2',
              title: 'Mythic Prestige Minting',
              description:
                  '100% of seasonal points plus top-tier rank bonuses are minted into permanent Mythic Prestige points on your profile.',
              isGirly: isGirly,
            ),
            const SizedBox(height: 8),
            _RuleStepTile(
              stepNumber: '3',
              title: 'Permanent Trophy Crests',
              description:
                  'Gold, Silver, and Bronze Mythic Paws are permanently archived to your Explorer Showcase.',
              isGirly: isGirly,
            ),
            const SizedBox(height: 20),
            // Simulate rollover button
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final record =
                    await SeasonServiceImpl.instance.completeSeasonRollover(
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
                foregroundColor: accent,
                side: BorderSide(color: accent),
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
  final bool isGirly;

  const _RewardMetricRow({
    required this.label,
    required this.value,
    this.highlight = false,
    required this.isGirly,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                isGirly ? GirlyColors.textSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? (isGirly ? GirlyColors.primaryDark : AppColors.primary)
                  : (isGirly ? GirlyColors.textPrimary : AppColors.textPrimary),
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
  final bool isGirly;

  const _RuleStepTile({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.isGirly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGirly ? GirlyColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGirly ? GirlyColors.border : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: (isGirly ? GirlyColors.primaryDark : AppColors.primary)
                  .withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isGirly ? GirlyColors.primaryDark : AppColors.primary,
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
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isGirly
                        ? GirlyColors.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isGirly
                        ? GirlyColors.textSecondary
                        : AppColors.textSecondary,
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
