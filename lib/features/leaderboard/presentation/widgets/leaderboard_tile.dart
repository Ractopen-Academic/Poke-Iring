import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
import '../../../events/presentation/widgets/profile_border_avatar.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_query.dart';

class LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardCategory category;
  final ValueChanged<LeaderboardEntry>? onTap;

  const LeaderboardTile({
    super.key,
    required this.entry,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = entry.isCurrentUser;
    final isGirly = GirlyThemeProvider.isGirly(context);
    final tier = entry.tier;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap?.call(entry),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? (isGirly ? GirlyColors.primary : AppColors.primary)
                      .withAlpha(15)
                  : (isGirly ? GirlyColors.surface : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUser
                    ? (isGirly ? GirlyColors.primary : AppColors.primary)
                    : (isGirly ? GirlyColors.border : AppColors.border),
                width: isUser ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isUser
                          ? (isGirly
                              ? GirlyColors.primaryDark
                              : AppColors.primary)
                          : (isGirly
                              ? GirlyColors.textSecondary
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cute Avatar with Profile Border
                ProfileBorderAvatar(
                  userId: entry.userId,
                  radius: 19,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tier.color.withAlpha(30),
                      border: Border.all(
                        color: tier.color.withAlpha(80),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.pets, size: 18, color: tier.color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and Location / Tier
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isUser ? FontWeight.w800 : FontWeight.w700,
                                color: isGirly
                                    ? GirlyColors.textPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isGirly
                                    ? GirlyColors.primaryDark
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${entry.barangay}, ${entry.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isGirly
                                    ? GirlyColors.textSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isGirly
                                  ? GirlyColors.textSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tier.displayName,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: tier.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Score and Mythic badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entry.formattedScore(category),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isGirly
                            ? GirlyColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (entry.mythicPaws > 0) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isGirly
                                  ? GirlyColors.primary
                                  : const Color(0xFFFFA000))
                              .withAlpha(24),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: isGirly
                                  ? GirlyColors.primaryDark
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${entry.mythicPaws} mythic',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isGirly
                                    ? GirlyColors.primaryDark
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
