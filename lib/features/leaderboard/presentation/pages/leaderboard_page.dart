import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_query.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../widgets/leaderboard_tile.dart';
import '../widgets/podium_card.dart';
import '../widgets/user_standing_card.dart';

class LeaderboardPage extends StatefulWidget {
  final LeaderboardRepository? repository;
  final String currentUserId;
  final String initialBarangay;
  final String initialCity;
  final String initialCountry;

  const LeaderboardPage({
    super.key,
    this.repository,
    this.currentUserId = 'current-user-1',
    this.initialBarangay = 'Bankal',
    this.initialCity = 'Lapu-Lapu City',
    this.initialCountry = 'Philippines',
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late final LeaderboardRepository _repository;
  LeaderboardCategory _category = LeaderboardCategory.overall;
  LeaderboardScope _scope = LeaderboardScope.barangay;
  List<LeaderboardEntry> _entries = [];
  LeaderboardEntry? _userStanding;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? const LeaderboardRepositoryImpl();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    final filter = LeaderboardFilter(
      category: _category,
      scope: _scope,
      barangay: widget.initialBarangay,
      city: widget.initialCity,
      country: widget.initialCountry,
      limit: 100,
    );

    final entries = await _repository.getLeaderboard(
      filter: filter,
      currentUserId: widget.currentUserId,
    );

    final standing = await _repository.getUserStanding(
      userId: widget.currentUserId,
      filter: filter,
    );

    if (!mounted) return;

    setState(() {
      _entries = entries;
      _userStanding = standing;
      _isLoading = false;
    });
  }

  void _onCategoryChanged(LeaderboardCategory newCategory) {
    if (_category == newCategory) return;
    setState(() => _category = newCategory);
    _loadLeaderboard();
  }

  void _onScopeChanged(LeaderboardScope newScope) {
    if (_scope == newScope) return;
    setState(() => _scope = newScope);
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Explorer Leaderboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Season Notice Banner
          _buildSeasonBanner(),

          // Category Tabs (Overall / Snaps / Distance)
          _buildCategoryTabs(),

          // Scope Filter Pills (Barangay / City / National / Global)
          _buildScopeFilterPills(),

          const Divider(height: 1, color: AppColors.border),

          // Main List / Podium
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _entries.isEmpty
                    ? _buildEmptyState()
                    : _buildLeaderboardContent(),
          ),

          // Sticky User Standing Bottom Card
          UserStandingCard(
            standing: _userStanding,
            scope: _scope,
            category: _category,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_repeat_rounded, size: 20, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Season 1: Sunshine Strays',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '12 days remaining • Top ranks earn permanent Mythic Paws',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: LeaderboardCategory.values.map((cat) {
          final isSelected = _category == cat;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onCategoryChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScopeFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: LeaderboardScope.values.map((sc) {
          final isSelected = _scope == sc;
          String label = sc.label;
          if (sc == LeaderboardScope.barangay) {
            label = widget.initialBarangay;
          } else if (sc == LeaderboardScope.city) {
            label = widget.initialCity;
          } else if (sc == LeaderboardScope.national) {
            label = widget.initialCountry;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onSelected: (_) => _onScopeChanged(sc),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    final first = _entries.isNotEmpty ? _entries[0] : null;
    final second = _entries.length > 1 ? _entries[1] : null;
    final third = _entries.length > 2 ? _entries[2] : null;
    final rest = _entries.length > 3 ? _entries.sublist(3) : <LeaderboardEntry>[];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (first != null)
          PodiumView(
            first: first,
            second: second,
            third: third,
            category: _category,
          ),
        if (rest.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Text(
              'Explorer Standings',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...rest.map(
            (entry) => LeaderboardTile(
              entry: entry,
              category: _category,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Territory Unclaimed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No explorers active in this territory yet. Be the first to scan a local cat and claim the #1 spot.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
