import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/achievements_repository_impl.dart';
import '../../domain/entities/achievement_tier.dart';
import '../../domain/entities/explorer_title.dart';
import '../../domain/entities/tiered_achievement.dart';
import '../widgets/equipped_title_badge.dart';
import '../widgets/tiered_achievement_card.dart';
import '../widgets/title_selection_sheet.dart';

class AchievementsPage extends StatefulWidget {
  final String userId;

  const AchievementsPage({super.key, required this.userId});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  AchievementCategory _selectedCategory = AchievementCategory.all;
  String _searchQuery = '';
  late final Stream<List<TieredAchievement>> _achievementsStream;
  late final Stream<ExplorerTitle?> _equippedTitleStream;

  @override
  void initState() {
    super.initState();
    _achievementsStream = AchievementsRepositoryImpl.instance.watchAchievements(
      widget.userId,
    );
    _equippedTitleStream = AchievementsRepositoryImpl.instance
        .watchEquippedTitle(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements & Titles'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Equip Titles',
            icon: const Icon(Icons.military_tech_outlined),
            onPressed: () =>
                TitleSelectionSheet.show(context, userId: widget.userId),
          ),
        ],
      ),
      body: StreamBuilder<List<TieredAchievement>>(
        stream: _achievementsStream,
        builder: (context, snapshot) {
          final allTracks = snapshot.data ?? [];

          // Compute overall stats across all 100 milestones
          int totalMilestonesCount = 0;
          int unlockedMilestonesCount = 0;
          int totalPointsEarned = 0;

          for (final track in allTracks) {
            for (final m in track.milestones) {
              totalMilestonesCount++;
              if (m.isUnlocked(track.currentProgress)) {
                unlockedMilestonesCount++;
                if (m.isClaimed) {
                  totalPointsEarned += m.rewardPawPoints;
                }
              }
            }
          }

          final filteredTracks = allTracks.where((track) {
            final matchesCategory =
                _selectedCategory == AchievementCategory.all ||
                track.category == _selectedCategory;
            final matchesSearch =
                _searchQuery.isEmpty ||
                track.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                track.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            return matchesCategory && matchesSearch;
          }).toList();

          return RefreshIndicator(
            onRefresh: () => AchievementsRepositoryImpl.instance
                .syncUserProgress(widget.userId),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Summary Card
                        _HeroProgressCard(
                          userId: widget.userId,
                          totalMilestones: totalMilestonesCount > 0
                              ? totalMilestonesCount
                              : 100,
                          unlockedMilestones: unlockedMilestonesCount,
                          totalPointsEarned: totalPointsEarned,
                          equippedTitleStream: _equippedTitleStream,
                        ),
                        const SizedBox(height: 14),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Search 100 tiered achievements...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: AchievementCategory.values.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat.label),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = cat),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                  selectedColor: AppColors.primary,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Achievement Cards List
                if (filteredTracks.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No achievements found in this category.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final track = filteredTracks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TieredAchievementCard(
                            achievement: track,
                            userId: widget.userId,
                          ),
                        );
                      }, childCount: filteredTracks.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroProgressCard extends StatelessWidget {
  final String userId;
  final int totalMilestones;
  final int unlockedMilestones;
  final int totalPointsEarned;
  final Stream<ExplorerTitle?> equippedTitleStream;

  const _HeroProgressCard({
    required this.userId,
    required this.totalMilestones,
    required this.unlockedMilestones,
    required this.totalPointsEarned,
    required this.equippedTitleStream,
  });

  @override
  Widget build(BuildContext context) {
    final progressFraction = totalMilestones > 0
        ? (unlockedMilestones / totalMilestones).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progressFraction * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trophy Case Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$unlockedMilestones / $totalMilestones Milestones',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              StreamBuilder<ExplorerTitle?>(
                stream: equippedTitleStream,
                builder: (context, snapshot) {
                  final equipped =
                      snapshot.data ??
                      const ExplorerTitle(
                        id: 'title_novice_scout',
                        name: 'Novice Scout',
                        description: 'Default title',
                        rarity: TitleRarity.common,
                        tier: AchievementTier.bronze,
                      );

                  return EquippedTitleBadge(
                    title: equipped,
                    onTap: () =>
                        TitleSelectionSheet.show(context, userId: userId),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 10,
              backgroundColor: AppColors.border.withAlpha(120),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percent% Completed',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '+$totalPointsEarned Paw Points Claimed',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
