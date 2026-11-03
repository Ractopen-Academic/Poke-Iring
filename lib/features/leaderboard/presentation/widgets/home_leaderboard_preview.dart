import 'dart:async';

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
  StreamSubscription<List<LeaderboardEntry>>? _entriesSubscription;
  List<LeaderboardEntry> _topThree = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    final datasource = FirebaseLeaderboardDataSource.instance;
    if (datasource.isCloudConnected) {
      _isLoading = true;
      _entriesSubscription = datasource.watchEntries().listen((entries) {
        if (!mounted) return;
        final sortedLive = List<LeaderboardEntry>.from(entries)
          ..sort((a, b) => b.points.compareTo(a.points));
        setState(() {
          _topThree = sortedLive.take(3).toList();
          _isLoading = false;
        });
      });
    } else {
      final seeds = const MockLeaderboardDatasource().getSeedEntries();
      final sorted = List<LeaderboardEntry>.from(seeds)
        ..sort((a, b) => b.points.compareTo(a.points));
      _topThree = sorted.take(3).toList();
    }
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.calicoBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(90)),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_topThree.isEmpty) {
      if (_isLoading) {
        return const SizedBox.shrink();
      }
      return CalicoSpotCard(
        onTap: widget.onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.creamSurface.withAlpha(180),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Season Podium Open',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Log your first neighborhood cat sighting to claim the #1 explorer spot.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final first = _topThree[0];
    final second = _topThree.length > 1 ? _topThree[1] : null;
    final third = _topThree.length > 2 ? _topThree[2] : null;

    return CalicoSpotCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
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
                  accentColor: const Color(0xFFC0C7D0),
                  bgColor: const Color(0xFF26201D),
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
                      bgColor: AppColors.primary,
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
                  accentColor: const Color(0xFFCD7F32),
                  bgColor: const Color(0xFF221C19),
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
      width: 98,
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
                  color: AppColors.surface,
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
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                entry.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isChampion ? 11 : 10,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
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
              border: Border.all(
                color: accentColor.withAlpha(isChampion ? 180 : 100),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                isChampion ? Icons.stars_rounded : Icons.military_tech_rounded,
                size: isChampion ? 20 : 16,
                color: isChampion ? Colors.white : accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
