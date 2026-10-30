import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
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
    final isCompleted = quest.isCompleted;
    final isClaimed = quest.isClaimed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted && !isClaimed
              ? AppColors.primary.withAlpha(120)
              : AppColors.border,
          width: isCompleted && !isClaimed ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted && !isClaimed
                ? AppColors.primary.withAlpha(20)
                : Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary.withAlpha(25)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTypeIcon(quest.type),
                  size: 20,
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quest.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFA000),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+${quest.rewardPawPoints}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB78103),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quest.progressFormatted,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                '${(quest.progressFraction * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: quest.progressFraction,
              backgroundColor: const Color(0xFFE5E7EB),
              color: isCompleted ? AppColors.primary : const Color(0xFFFB923C),
              minHeight: 6,
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isClaimed
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Reward Claimed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onClaim,
                      icon: const Icon(Icons.card_giftcard, size: 16),
                      label: Text('Claim +${quest.rewardPawPoints} Paw Points'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
