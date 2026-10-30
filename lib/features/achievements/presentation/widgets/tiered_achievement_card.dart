import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/achievements_repository_impl.dart';
import '../../domain/entities/achievement_tier.dart';
import '../../domain/entities/tiered_achievement.dart';

class TieredAchievementCard extends StatefulWidget {
  final TieredAchievement achievement;
  final String userId;

  const TieredAchievementCard({
    super.key,
    required this.achievement,
    required this.userId,
  });

  @override
  State<TieredAchievementCard> createState() => _TieredAchievementCardState();
}

class _TieredAchievementCardState extends State<TieredAchievementCard> {
  bool _isClaiming = false;

  Future<void> _handleClaim(AchievementMilestone milestone) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final points = await AchievementsRepositoryImpl.instance
          .claimMilestoneReward(
            userId: widget.userId,
            achievementId: widget.achievement.id,
            tier: milestone.tier,
          );

      if (mounted) {
        final titleText = milestone.rewardTitle != null
            ? ' and unlocked title "${milestone.rewardTitle!.name}"!'
            : '!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Claimed +$points Paw Points for ${milestone.tier.label} tier$titleText',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to claim reward: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final displayTier = achievement.currentDisplayTier;
    final nextMilestone = achievement.nextMilestone;
    final isMax = achievement.isMaxTier;

    // Find first uncollected reward
    AchievementMilestone? claimableMilestone;
    for (final m in achievement.milestones) {
      if (m.isUnlocked(achievement.currentProgress) && !m.isClaimed) {
        claimableMilestone = m;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: claimableMilestone != null
              ? claimableMilestone.tier.borderColor
              : AppColors.border,
          width: claimableMilestone != null ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: displayTier.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: displayTier.borderColor),
                ),
                child: Icon(
                  isMax
                      ? Icons.military_tech_rounded
                      : Icons.workspace_premium_outlined,
                  size: 22,
                  color: displayTier.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            achievement.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TierBadge(tier: displayTier, isMax: isMax),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4-Tier Milestones Pips Row
          Row(
            children: achievement.milestones.map((milestone) {
              final isUnlocked = milestone.isUnlocked(
                achievement.currentProgress,
              );
              final isClaimed = milestone.isClaimed;
              final tier = milestone.tier;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? tier.backgroundColor
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isUnlocked ? tier.borderColor : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tier.label.substring(0, 1),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked
                              ? tier.secondaryColor
                              : AppColors.textSecondary.withAlpha(120),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isClaimed
                              ? tier.primaryColor
                              : (isUnlocked
                                    ? tier.borderColor
                                    : AppColors.border),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Progress Bar and Metric Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMax
                    ? 'All ${achievement.milestones.length} Tiers Mastered'
                    : 'Target: ${nextMilestone.tier.label}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isMax
                      ? displayTier.secondaryColor
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                achievement.progressFormatted,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isMax ? 1.0 : achievement.progressFraction,
              minHeight: 6,
              backgroundColor: AppColors.border.withAlpha(100),
              valueColor: AlwaysStoppedAnimation<Color>(
                isMax ? displayTier.primaryColor : AppColors.primary,
              ),
            ),
          ),

          // Claim button if unlocked milestone reward is ready
          if (claimableMilestone != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isClaiming
                    ? null
                    : () => _handleClaim(claimableMilestone!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: claimableMilestone.tier.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isClaiming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            claimableMilestone.rewardTitle != null
                                ? Icons.military_tech_rounded
                                : Icons.card_giftcard_rounded,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            claimableMilestone.rewardTitle != null
                                ? 'Claim ${claimableMilestone.tier.label} (+${claimableMilestone.rewardPawPoints} pts & Title)'
                                : 'Claim ${claimableMilestone.tier.label} (+${claimableMilestone.rewardPawPoints} Paw Points)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final AchievementTier tier;
  final bool isMax;

  const _TierBadge({required this.tier, required this.isMax});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tier.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tier.borderColor, width: 1),
      ),
      child: Text(
        isMax ? 'MASTERED' : tier.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: tier.secondaryColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
