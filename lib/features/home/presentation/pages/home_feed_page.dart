import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/app_cache_coordinator.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../../achievements/data/repositories/achievements_repository_impl.dart';
import '../../../achievements/domain/entities/explorer_title.dart';
import '../../../achievements/presentation/widgets/equipped_title_badge.dart';
import '../../../achievements/presentation/widgets/title_selection_sheet.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../events/presentation/widgets/active_events_carousel.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../../leaderboard/presentation/widgets/home_leaderboard_preview.dart';
import '../../../quests/presentation/widgets/paw_quests_section.dart';
import '../../../rewards/presentation/pages/reward_store_page.dart';
import '../../../scanner/presentation/widgets/cat_verification_game_sheet.dart';
import '../../../stories/presentation/widgets/stories_tray.dart';
import '../../../../core/widgets/feline_avatar.dart';

class HomeFeedPage extends StatefulWidget {
  final AuthUser user;
  final VoidCallback? onOpenLeaderboard;
  final VoidCallback? onOpenAccount;

  const HomeFeedPage({
    super.key,
    required this.user,
    this.onOpenLeaderboard,
    this.onOpenAccount,
  });

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  @override
  void initState() {
    super.initState();
    ExplorerHealthService.instance.start();
    CalicoThemeController.instance.addListener(_handleThemeChanged);
  }

  @override
  void dispose() {
    CalicoThemeController.instance.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : widget.user.email.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets_rounded, size: 19, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.dynamicTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Human Verification Game',
            icon: const Icon(
              Icons.how_to_vote_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () => CatVerificationGameSheet.show(
              context,
              user: widget.user,
            ),
          ),
          IconButton(
            tooltip: 'Paw Points Exchange',
            icon: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RewardStorePage(user: widget.user),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Center(
              child: Tooltip(
                message: 'Explorer Profile & Account',
                child: FelineAvatar(
                  photoUrl: widget.user.photoUrl,
                  seed: widget.user.id.isNotEmpty
                      ? widget.user.id
                      : widget.user.email,
                  radius: 17,
                  showBorder: true,
                  borderColor: AppColors.primary,
                  borderWidth: 1.5,
                  onTap: widget.onOpenAccount,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<ExplorerHealthSnapshot>(
          stream: ExplorerHealthService.instance.stream,
          initialData: ExplorerHealthService.instance.latest,
          builder: (context, snapshot) {
            final health = snapshot.data ?? ExplorerHealthSnapshot.empty();

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.dynamicSurface,
              onRefresh: () => AppCacheCoordinator.instance.refreshHomeFeed(
                userId: widget.user.id.isNotEmpty
                    ? widget.user.id
                    : widget.user.email,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 108),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.dynamicChromeTrack,
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(
                                          color: AppColors.primary.withAlpha(
                                            60,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.pets_rounded,
                                            size: 11,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Welcome back,',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  AppColors.dynamicTextPrimary,
                                              letterSpacing: 0.25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.dynamicTextPrimary,
                                        height: 1.15,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StreamBuilder<ExplorerTitle?>(
                                stream: AchievementsRepositoryImpl.instance
                                    .watchEquippedTitle(
                                      widget.user.id.isNotEmpty
                                          ? widget.user.id
                                          : widget.user.email,
                                    ),
                                builder: (context, snapshot) {
                                  final title = snapshot.data;
                                  if (title == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: EquippedTitleBadge(
                                      title: title,
                                      onTap: () => TitleSelectionSheet.show(
                                        context,
                                        userId: widget.user.id.isNotEmpty
                                            ? widget.user.id
                                            : widget.user.email,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Track your daily explorer movement and unlock more feline routes.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.dynamicTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<GlobalAppConfig>(
                            stream: RemoteConfigService.instance.streamConfig(),
                            initialData: RemoteConfigService.instance.config,
                            builder: (context, snap) {
                              final cfg =
                                  snap.data ??
                                  RemoteConfigService.instance.config;
                              if (!cfg.isBroadcastActive ||
                                  cfg.broadcastBanner.trim().isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(24),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primary.withAlpha(90),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.campaign_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        cfg.broadcastBanner,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.dynamicTextPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    StoriesTray(user: widget.user),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CalicoSpotCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.dynamicChromeTrack,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Icon(
                                        Icons.directions_walk_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Explorer Health',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  AppColors.dynamicTextPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Daily paw-patrol telemetry',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors
                                                  .dynamicTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: HomeMiniMetric(
                                        label: 'Steps',
                                        value: '${health.stepsToday}',
                                        icon: Icons.pets_rounded,
                                        accent: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: HomeMiniMetric(
                                        label: 'Distance',
                                        value:
                                            '${health.distanceKm.toStringAsFixed(2)} km',
                                        icon: Icons.route_rounded,
                                        accent: AppColors.calicoAmber,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: HomeMiniMetric(
                                        label: 'Calories',
                                        value:
                                            '${health.caloriesBurned.toStringAsFixed(0)} kcal',
                                        icon:
                                            Icons.local_fire_department_rounded,
                                        accent: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: HomeMiniMetric(
                                        label: 'Active',
                                        value: '${health.activeMinutes} min',
                                        icon: Icons.bolt_rounded,
                                        accent: AppColors.calicoOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          HomeLeaderboardPreview(
                            onTap: widget.onOpenLeaderboard ?? () {},
                          ),
                          const SizedBox(height: 20),
                          ActiveEventsCarousel(
                            userId: widget.user.id.isNotEmpty
                                ? widget.user.id
                                : widget.user.email,
                            userDisplayName: name,
                            userPhotoUrl: widget.user.photoUrl,
                            bottomPadding: 24,
                          ),
                          PawQuestsSection(
                            userId: widget.user.id.isNotEmpty
                                ? widget.user.id
                                : widget.user.email,
                            isAdmin: widget.user.isAdminRole,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomeMiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const HomeMiniMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.dynamicFieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.dynamicTextSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    value,
                    key: ValueKey<String>(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dynamicTextPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
