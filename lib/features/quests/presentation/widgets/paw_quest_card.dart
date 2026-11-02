import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../domain/entities/paw_quest.dart';

class PawQuestCard extends StatelessWidget {
  final PawQuest quest;
  final VoidCallback onClaim;

  const PawQuestCard({super.key, required this.quest, required this.onClaim});

  IconData _getTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.steps:
        return Icons.directions_walk_rounded;
      case QuestType.distance:
        return Icons.navigation_outlined;
      case QuestType.scanCat:
      case QuestType.scanBreed:
        return Icons.camera_alt_outlined;
      case QuestType.boopSightings:
        return Icons.pets_outlined;
      case QuestType.goldenHour:
        return Icons.wb_twilight_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    final isCompleted = quest.isCompleted;
    final isClaimed = quest.isClaimed;
    final clampedProgress = quest.progressFraction.clamp(0.0, 1.0);

    return CalicoSpotCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      backgroundColor: isCompleted && !isClaimed
          ? (isGirly ? GirlyColors.creamSurface : const Color(0xFFFFFCF8))
          : (isGirly ? GirlyColors.surface : Colors.white),
      borderColor: isCompleted && !isClaimed
          ? (isGirly ? GirlyColors.primary : AppColors.primary).withAlpha(170)
          : (isGirly ? GirlyColors.border : AppColors.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? (isGirly ? GirlyColors.navBarBg : AppColors.calicoBlack)
                      : (isGirly
                          ? GirlyColors.primaryLight
                          : AppColors.creamSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? (isGirly ? GirlyColors.primary : AppColors.primary)
                            .withAlpha(90)
                        : (isGirly
                            ? GirlyColors.primary
                            : AppColors.gingerBorder),
                  ),
                ),
                child: Icon(
                  _getTypeIcon(quest.type),
                  size: 20,
                  color: isCompleted
                      ? (isGirly
                          ? GirlyColors.highlightPink
                          : AppColors.primary)
                      : (isGirly
                          ? GirlyColors.primaryDark
                          : AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isGirly
                            ? GirlyColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quest.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isGirly
                            ? GirlyColors.textSecondary
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isGirly ? GirlyColors.primaryLight : AppColors.gingerSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isGirly ? GirlyColors.primary : AppColors.gingerBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color:
                          isGirly ? GirlyColors.primaryDark : AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+${quest.rewardPawPoints}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isGirly
                            ? GirlyColors.primaryDark
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quest.progressFormatted,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isCompleted
                      ? (isGirly
                          ? GirlyColors.primaryDark
                          : AppColors.primaryDark)
                      : (isGirly
                          ? GirlyColors.textSecondary
                          : AppColors.textSecondary),
                ),
              ),
              Text(
                '${(clampedProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isCompleted
                      ? (isGirly
                          ? GirlyColors.primaryDark
                          : AppColors.primaryDark)
                      : (isGirly
                          ? GirlyColors.textSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: clampedProgress),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isGirly
                      ? GirlyColors.primaryLight
                      : AppColors.creamSurface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isGirly ? GirlyColors.border : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedValue.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? (isGirly
                                ? [GirlyColors.primary, GirlyColors.primaryDark]
                                : [AppColors.primary, AppColors.primaryDark])
                            : (isGirly
                                ? [
                                    GirlyColors.highlightPink,
                                    GirlyColors.primary
                                  ]
                                : [const Color(0xFFFFAD42), AppColors.primary]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (isCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isClaimed
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Reward Claimed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFFA5D6A7)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : CalicoPressable(
                      child: ElevatedButton.icon(
                        onPressed: onClaim,
                        icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                        label: Text(
                          'Claim +${quest.rewardPawPoints} Paw Points',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGirly
                              ? GirlyColors.primaryDark
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
