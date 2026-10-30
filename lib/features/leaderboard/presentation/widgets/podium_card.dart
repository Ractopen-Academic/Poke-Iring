import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_query.dart';

class PodiumView extends StatelessWidget {
  final LeaderboardEntry first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;
  final LeaderboardCategory category;

  const PodiumView({
    super.key,
    required this.first,
    this.second,
    this.third,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          Expanded(
            child: second != null
                ? _PodiumStep(
                    entry: second!,
                    rank: 2,
                    stepHeight: 92,
                    pedestalColor: const Color(0xFFECEFF1),
                    accentColor: const Color(0xFF78909C),
                    category: category,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          // 1st Place
          Expanded(
            child: _PodiumStep(
              entry: first,
              rank: 1,
              stepHeight: 124,
              pedestalColor: const Color(0xFFFFF8E1),
              accentColor: const Color(0xFFFFA000),
              category: category,
            ),
          ),
          const SizedBox(width: 8),
          // 3rd Place
          Expanded(
            child: third != null
                ? _PodiumStep(
                    entry: third!,
                    rank: 3,
                    stepHeight: 76,
                    pedestalColor: const Color(0xFFEFEBE9),
                    accentColor: const Color(0xFF8D6E63),
                    category: category,
                  )
                : const SizedBox.shrink(),
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

  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.stepHeight,
    required this.pedestalColor,
    required this.accentColor,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with cute feline badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: rank == 1 ? 64 : 52,
              height: rank == 1 ? 64 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: accentColor, width: rank == 1 ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.pets,
                  size: rank == 1 ? 30 : 24,
                  color: accentColor,
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Name & Score
        Text(
          entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: rank == 1 ? 13 : 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          entry.formattedScore(category),
          style: TextStyle(
            fontSize: rank == 1 ? 12 : 11,
            fontWeight: FontWeight.w700,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        // Pedestal base
        Container(
          width: double.infinity,
          height: stepHeight,
          decoration: BoxDecoration(
            color: pedestalColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: accentColor.withAlpha(60), width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rank == 1
                    ? Icons.stars_rounded
                    : Icons.military_tech_rounded,
                color: accentColor,
                size: rank == 1 ? 26 : 20,
              ),
              const SizedBox(height: 2),
              Text(
                entry.barangay,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
