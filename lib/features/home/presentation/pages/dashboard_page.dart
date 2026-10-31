import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../../achievements/data/repositories/achievements_repository_impl.dart';
import '../../../achievements/domain/entities/achievement_tier.dart';
import '../../../achievements/domain/entities/explorer_title.dart';
import '../../../achievements/presentation/pages/achievements_page.dart';
import '../../../achievements/presentation/widgets/equipped_title_badge.dart';
import '../../../achievements/presentation/widgets/title_selection_sheet.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../dex/presentation/pages/iring_dex_page.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../scanner/presentation/pages/cat_scanner_page.dart';
import '../../../scanner/presentation/widgets/ai_vision_settings_sheet.dart';
import '../../../seasons/data/services/season_service_impl.dart';
import '../../../showcase/presentation/widgets/explorer_showcase_sheet.dart';
import '../../../showcase/services/showcase_service.dart';
import '../../../territory/data/services/territory_service_impl.dart';
import '../../../territory/domain/entities/explorer_territory.dart';
import '../../../territory/presentation/widgets/territory_selection_sheet.dart';

class DashboardPage extends StatefulWidget {
  final AuthUser user;
  final AuthRepository authRepository;
  final VoidCallback? onOpenMap;

  const DashboardPage({
    super.key,
    required this.user,
    required this.authRepository,
    this.onOpenMap,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoggingOut = false;
  bool _isPublicShowcase = true;

  @override
  void initState() {
    super.initState();
    ExplorerHealthService.instance.start();
    _isPublicShowcase = ShowcaseService.instance.isPublicShowcaseEnabled;
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.authRepository.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : widget.user.email.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _isLoggingOut ? null : _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    FelineAvatar(
                      photoUrl: widget.user.photoUrl,
                      seed: displayName,
                      radius: 28,
                      showBorder: true,
                      borderColor: AppColors.primary.withAlpha(50),
                      borderWidth: 2,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<ExplorerTitle?>(
                            stream: AchievementsRepositoryImpl.instance
                                .watchEquippedTitle(
                                  widget.user.id.isNotEmpty
                                      ? widget.user.id
                                      : widget.user.email,
                                ),
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
                                onTap: () => TitleSelectionSheet.show(
                                  context,
                                  userId: widget.user.id.isNotEmpty
                                      ? widget.user.id
                                      : widget.user.email,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              StreamBuilder<ExplorerTerritory>(
                stream: TerritoryServiceImpl.instance.watchTerritory(
                  widget.user.id.isNotEmpty
                      ? widget.user.id
                      : widget.user.email,
                ),
                initialData: ExplorerTerritory.defaultTerritory,
                builder: (context, snapshot) {
                  final territory =
                      snapshot.data ?? ExplorerTerritory.defaultTerritory;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Home Territory',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${territory.barangay}, ${territory.city}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${territory.province}, ${territory.country}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            TerritorySelectionSheet.show(
                              context,
                              userId: widget.user.id.isNotEmpty
                                  ? widget.user.id
                                  : widget.user.email,
                              currentTerritory: territory,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Explorer State',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<ExplorerHealthSnapshot>(
                stream: ExplorerHealthService.instance.stream,
                initialData: ExplorerHealthService.instance.latest,
                builder: (context, snapshot) {
                  final health =
                      snapshot.data ?? ExplorerHealthSnapshot.empty();
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Steps',
                          value: '${health.stepsToday}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Distance',
                          value: '${health.distanceKm.toStringAsFixed(2)} km',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Calories',
                          value:
                              '${health.caloriesBurned.toStringAsFixed(0)} kcal',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<int>(
                stream: SeasonServiceImpl.instance.watchMythicPrestige(
                  widget.user.id.isNotEmpty
                      ? widget.user.id
                      : widget.user.email,
                ),
                initialData: 0,
                builder: (context, snapshot) {
                  final prestige = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4).withAlpha(120),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 22,
                          color: Color(0xFFFFA000),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lifetime Mythic Prestige',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$prestige Points',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4E342E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Archived prestige',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.brown.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Navigation Modules',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _ModuleTile(
                icon: Icons.leaderboard_outlined,
                title: 'Leaderboard',
                subtitle: 'Seasonal territory standings and rankings',
                onTap: () async {
                  final territory = await TerritoryServiceImpl.instance
                      .getTerritory(
                        widget.user.id.isNotEmpty
                            ? widget.user.id
                            : widget.user.email,
                      );
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LeaderboardPage(
                        currentUserId: widget.user.id.isNotEmpty
                            ? widget.user.id
                            : widget.user.email,
                        initialBarangay: territory.barangay,
                        initialCity: territory.city,
                        initialRegion: territory.province,
                        initialCountry: territory.country,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModuleTile(
                icon: Icons.favorite_outline_rounded,
                title: 'Explorer Health',
                subtitle: 'Live step count, distance, and active minutes',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Explorer health is live on the home screen and account stats.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModuleTile(
                icon: Icons.map_outlined,
                title: 'Live Sightings Map',
                subtitle: 'Real-time 10-minute cat discoveries nearby',
                onTap:
                    widget.onOpenMap ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use center Iring button to view map'),
                        ),
                      );
                    },
              ),
              const SizedBox(height: 10),
              _ModuleTile(
                icon: Icons.camera_alt_outlined,
                title: 'Cat Scanner',
                subtitle: 'Vision breed classifier & paw points calculator',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CatScannerPage(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModuleTile(
                icon: Icons.collections_bookmark_outlined,
                title: 'Iring-Dex',
                subtitle: 'Catalog of documented feline species',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IringDexPage(user: widget.user),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModuleTile(
                icon: Icons.military_tech_outlined,
                title: 'Achievements & Titles',
                subtitle: '100 tiered bronze, silver & gold milestones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AchievementsPage(
                        userId: widget.user.id.isNotEmpty
                            ? widget.user.id
                            : widget.user.email,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModuleTile(
                icon: Icons.psychology_outlined,
                title: 'AI Vision Settings',
                subtitle: 'Configure Gemini API key for cat recognition',
                onTap: () => AiVisionSettingsSheet.show(context),
              ),
              const SizedBox(height: 24),
              const Text(
                'Explorer Showcase & Privacy',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_motion_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Explorer Showcase',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ShowcaseService.instance.pinnedCount} of 9 slots pinned from Dex',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final profile = await ShowcaseService.instance
                                .getProfileForUser(
                                  userId: widget.user.id.isNotEmpty
                                      ? widget.user.id
                                      : widget.user.email,
                                  displayName: displayName,
                                  avatarUrl: widget.user.photoUrl,
                                );
                            if (context.mounted) {
                              ExplorerShowcaseSheet.show(context, profile);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Public Profile Showcase',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isPublicShowcase
                                    ? 'Visible to other players on leaderboards'
                                    : 'Hidden from other explorers',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isPublicShowcase,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) async {
                            await ShowcaseService.instance
                                .setPublicShowcaseEnabled(val);
                            if (mounted) {
                              setState(() => _isPublicShowcase = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Sign Out',
                isOutlined: true,
                isLoading: _isLoggingOut,
                icon: const Icon(
                  Icons.logout,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                onPressed: _handleSignOut,
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Poke: Iring ${AppVersion.badgeDisplay}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppVersion.buildSubtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
