import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/season_prestige_record.dart';

class SeasonRolloverDialog extends StatelessWidget {
  final SeasonPrestigeRecord record;

  const SeasonRolloverDialog({super.key, required this.record});

  static Future<void> show(BuildContext context, SeasonPrestigeRecord record) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SeasonRolloverDialog(record: record),
    );
  }

  Color get _crestColor {
    switch (record.trophyCrest) {
      case SeasonTrophyCrest.goldMythic:
        return const Color(0xFFFFB300);
      case SeasonTrophyCrest.silverMythic:
        return const Color(0xFF90A4AE);
      case SeasonTrophyCrest.bronzeMythic:
        return const Color(0xFFB08968);
      case SeasonTrophyCrest.participant:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _crestColor.withAlpha(35),
                  shape: BoxShape.circle,
                  border: Border.all(color: _crestColor, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 36,
                    color: _crestColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              '${record.seasonTitle} Concluded',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your seasonal progress has been permanently archived.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            // Stats summary container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Final Standing',
                    value: '${record.finalDivision} (#${record.finalRank})',
                  ),
                  const Divider(height: 16),
                  _SummaryRow(
                    label: 'Lifetime Mythic Prestige',
                    value: '+${record.prestigeEarned} pts',
                    highlightColor: AppColors.primary,
                  ),
                  const Divider(height: 16),
                  _SummaryRow(
                    label: 'Trophy Crest Awarded',
                    value: record.trophyCrest.label,
                    highlightColor: _crestColor,
                  ),
                  const Divider(height: 16),
                  _SummaryRow(
                    label: 'Next Season Starting Floor',
                    value:
                        '${record.startingPlacementDivision} (${record.startingPlacementPoints} pts)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
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
                'Enter Next Season',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlightColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlightColor,
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
              color: highlightColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
