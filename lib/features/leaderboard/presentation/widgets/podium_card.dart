import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../events/presentation/widgets/profile_border_avatar.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_query.dart';

class PodiumView extends StatelessWidget {
  final LeaderboardEntry first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;
  final LeaderboardCategory category;
  final ValueChanged<LeaderboardEntry>? onEntryTap;

  const PodiumView({
    super.key,
    required this.first,
    this.second,
    this.third,
    required this.category,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dynamicBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Territory Podium',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dynamicTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              Expanded(
                child: second != null
                    ? _PodiumStep(
                        entry: second!,
                        rank: 2,
                        stepHeight: 52,
                        pedestalColor: AppColors.isCalicoLight
                            ? const Color(0xFFF4ECE1)
                            : const Color(0xFF26201D),
                        accentColor: const Color(0xFFC0C7D0),
                        category: category,
                        onTap: () => onEntryTap?.call(second!),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              // 1st Place
              Expanded(
                child: _PodiumStep(
                  entry: first,
                  rank: 1,
                  stepHeight: 74,
                  pedestalColor: AppColors.primary,
                  accentColor: AppColors.primary,
                  category: category,
                  onTap: () => onEntryTap?.call(first),
                ),
              ),
              const SizedBox(width: 8),
              // 3rd Place
              Expanded(
                child: third != null
                    ? _PodiumStep(
                        entry: third!,
                        rank: 3,
                        stepHeight: 42,
                        pedestalColor: AppColors.isCalicoLight
                            ? const Color(0xFFEFE6DC)
                            : const Color(0xFF221C19),
                        accentColor: const Color(0xFFCD7F32),
                        category: category,
                        onTap: () => onEntryTap?.call(third!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double stepHeight;
  final Color pedestalColor;
  final Color accentColor;
  final LeaderboardCategory category;
  final VoidCallback? onTap;

  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.stepHeight,
    required this.pedestalColor,
    required this.accentColor,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = rank == 1 ? 46.0 : 38.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ProfileBorderAvatar(
                userId: entry.userId,
                radius: avatarSize / 2,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dynamicSurface,
                    border: Border.all(
                      color: accentColor,
                      width: rank == 1 ? 2.5 : 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(55),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.pets,
                      size: rank == 1 ? 22 : 18,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.dynamicSurface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rank == 1 ? 12 : 11,
              fontWeight: FontWeight.w800,
              color: AppColors.dynamicTextPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            entry.formattedScore(category),
            style: TextStyle(
              fontSize: rank == 1 ? 11 : 10,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: stepHeight,
            decoration: BoxDecoration(
              color: pedestalColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(
                color: rank == 1
                    ? AppColors.primary
                    : accentColor.withAlpha(90),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  rank == 1 ? Icons.stars_rounded : Icons.military_tech_rounded,
                  color: rank == 1 ? Colors.white : accentColor,
                  size: rank == 1 ? 20 : 16,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.barangay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: rank == 1 ? Colors.white : accentColor,
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
