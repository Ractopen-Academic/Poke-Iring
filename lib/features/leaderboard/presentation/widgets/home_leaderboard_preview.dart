import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
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

  Widget _buildHeader(BuildContext context) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isGirly ? GirlyColors.navBarBg : AppColors.calicoBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isGirly ? GirlyColors.primary : AppColors.primary)
                      .withAlpha(90),
                ),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: isGirly ? GirlyColors.highlightPink : AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Territory Champions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isGirly
                        ? GirlyColors.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Top explorers this season',
                  style: TextStyle(
                    fontSize: 11,
                    color: isGirly
                        ? GirlyColors.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isGirly ? GirlyColors.primaryLight : AppColors.gingerSoft,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isGirly ? GirlyColors.primary : AppColors.gingerBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View Ranks',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color:
                      isGirly ? GirlyColors.primaryDark : AppColors.primaryDark,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color:
                    isGirly ? GirlyColors.primaryDark : AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGirly = GirlyThemeProvider.isGirly(context);
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
            _buildHeader(context),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: (isGirly
                        ? GirlyColors.creamSurface
                        : AppColors.creamSurface)
                    .withAlpha(180),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isGirly ? GirlyColors.border : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 22,
                    color:
                        isGirly ? GirlyColors.primaryDark : AppColors.primary,
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
                            color: isGirly
                                ? GirlyColors.textPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Log your first neighborhood cat sighting to claim the #1 explorer spot.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isGirly
                                ? GirlyColors.textSecondary
                                : AppColors.textSecondary,
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
          _buildHeader(context),
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
                  accentColor:
                      isGirly ? GirlyColors.navMuted : AppColors.calicoCharcoal,
                  bgColor: isGirly
                      ? GirlyColors.primaryLight
                      : const Color(0xFFF3ECE7),
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
                      accentColor:
                          isGirly ? GirlyColors.primaryDark : AppColors.primary,
                      bgColor: isGirly
                          ? GirlyColors.creamSurface
                          : AppColors.gingerSoft,
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
                  accentColor: isGirly
                      ? GirlyColors.primaryDark
                      : const Color(0xFFB86B35),
                  bgColor: isGirly
                      ? GirlyColors.primaryLight
                      : AppColors.creamSurface,
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
    final isGirly = GirlyThemeProvider.isGirly(context);
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
                  color: isGirly ? GirlyColors.surface : Colors.white,
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
                    color: isChampion
                        ? (isGirly
                            ? GirlyColors.navBarBg
                            : AppColors.calicoBlack)
                        : accentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isChampion
                        ? Border.all(
                            color: isGirly
                                ? GirlyColors.primary
                                : AppColors.primary,
                            width: 1,
                          )
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
              color: isGirly ? GirlyColors.textPrimary : AppColors.textPrimary,
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
