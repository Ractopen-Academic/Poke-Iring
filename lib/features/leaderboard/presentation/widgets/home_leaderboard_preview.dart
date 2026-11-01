import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../data/datasources/firebase_leaderboard_datasource.dart';
import '../../data/datasources/mock_leaderboard_datasource.dart';
import '../../domain/entities/leaderboard_entry.dart';

class HomeLeaderboardPreview extends StatefulWidget {
  final VoidCallback onTap;

  const HomeLeaderboardPreview({super.key, required this.onTap});

  @override
  State<HomeLeaderboardPreview> createState() => _HomeLeaderboardPreviewState();
}

class _HomeLeaderboardPreviewState extends State<HomeLeaderboardPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  List<LeaderboardEntry> _topThree = [];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    final seeds = const MockLeaderboardDatasource().getSeedEntries();
    final sorted = List<LeaderboardEntry>.from(seeds)
      ..sort((a, b) => b.points.compareTo(a.points));
    _topThree = sorted.take(3).toList();

    FirebaseLeaderboardDataSource.instance.fetchEntries().then((entries) {
      if (mounted && entries.isNotEmpty) {
        final sortedLive = List<LeaderboardEntry>.from(entries)
          ..sort((a, b) => b.points.compareTo(a.points));
        setState(() {
          _topThree = sortedLive.take(3).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_topThree.isEmpty) return const SizedBox.shrink();

    final first = _topThree[0];
    final second = _topThree.length > 1 ? _topThree[1] : null;
    final third = _topThree.length > 2 ? _topThree[2] : null;

    return CalicoSpotCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.calicoBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(90),
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Territory Champions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Top explorers this season',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gingerSoft,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.gingerBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Ranks',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (second != null)
                _MiniPodiumItem(
                  entry: second,
                  rank: 2,
                  pedestalHeight: 46,
                  accentColor: AppColors.calicoCharcoal,
                  bgColor: const Color(0xFFF3ECE7),
                  floatOffset: 0,
                ),
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  final dy = -4.0 * _floatController.value;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: _MiniPodiumItem(
                      entry: first,
                      rank: 1,
                      pedestalHeight: 62,
                      accentColor: AppColors.primary,
                      bgColor: AppColors.gingerSoft,
                      isChampion: true,
                      floatOffset: dy,
                    ),
                  );
                },
              ),
              if (third != null)
                _MiniPodiumItem(
                  entry: third,
                  rank: 3,
                  pedestalHeight: 38,
                  accentColor: const Color(0xFFB86B35),
                  bgColor: AppColors.creamSurface,
                  floatOffset: 0,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double pedestalHeight;
  final Color accentColor;
  final Color bgColor;
  final bool isChampion;
  final double floatOffset;

  const _MiniPodiumItem({
    required this.entry,
    required this.rank,
    required this.pedestalHeight,
    required this.accentColor,
    required this.bgColor,
    this.isChampion = false,
    this.floatOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isChampion ? 50.0 : 42.0;

    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: accentColor,
                    width: isChampion ? 2.5 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FelineAvatar(
                  seed: entry.displayName,
                  radius: (avatarSize / 2) - 4,
                  showBorder: false,
                ),
              ),
              Positioned(
                bottom: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isChampion ? AppColors.calicoBlack : accentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isChampion
                        ? Border.all(color: AppColors.primary, width: 1)
                        : null,
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
              fontSize: isChampion ? 11.5 : 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${entry.points} pts',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: pedestalHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(color: accentColor.withAlpha(65), width: 1.1),
            ),
            child: Center(
              child: Icon(
                isChampion ? Icons.stars_rounded : Icons.military_tech_rounded,
                size: isChampion ? 18 : 15,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
