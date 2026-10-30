import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
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
  late final List<LeaderboardEntry> _topThree;

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Padding(
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
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: Color(0xFFFFA000),
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
                    Row(
                      children: const [
                        Text(
                          'View Ranks',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Animated Top 3 Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2nd Place
                    if (second != null)
                      _MiniPodiumItem(
                        entry: second,
                        rank: 2,
                        pedestalHeight: 46,
                        accentColor: const Color(0xFF78909C),
                        bgColor: const Color(0xFFECEFF1),
                        floatOffset: 0,
                      ),

                    // 1st Place (with animated floating effect)
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
                            accentColor: const Color(0xFFFFA000),
                            bgColor: const Color(0xFFFFF8E1),
                            isChampion: true,
                            floatOffset: dy,
                          ),
                        );
                      },
                    ),

                    // 3rd Place
                    if (third != null)
                      _MiniPodiumItem(
                        entry: third,
                        rank: 3,
                        pedestalHeight: 38,
                        accentColor: const Color(0xFF8D6E63),
                        bgColor: const Color(0xFFEFEBE9),
                        floatOffset: 0,
                      ),
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
    final avatarSize = isChampion ? 48.0 : 40.0;

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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: accentColor,
                    width: isChampion ? 2.5 : 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(40),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.pets,
                    size: isChampion ? 24 : 18,
                    color: accentColor,
                  ),
                ),
              ),
              Positioned(
                bottom: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
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
                top: Radius.circular(10),
              ),
              border: Border.all(color: accentColor.withAlpha(50), width: 1.0),
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
