import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../../../core/theme/girly_theme.dart';
import '../../../../core/widgets/feline_status_banner.dart';
import '../../../../core/widgets/girly_theme_toggle.dart';
import '../../../achievements/data/repositories/achievements_repository_impl.dart';
import '../../../achievements/domain/entities/explorer_title.dart';
import '../../../achievements/presentation/widgets/equipped_title_badge.dart';
import '../../../achievements/presentation/widgets/title_selection_sheet.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../dex/presentation/pages/iring_dex_page.dart';
import '../../../events/presentation/widgets/active_events_carousel.dart';
import '../../../events/presentation/widgets/event_popup_modal.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../leaderboard/presentation/widgets/home_leaderboard_preview.dart';
import '../../../map/domain/repositories/map_repository.dart';
import '../../../map/presentation/pages/live_map_page.dart';
import '../../../quests/presentation/widgets/paw_quests_section.dart';
import '../../../scanner/presentation/pages/cat_scanner_page.dart';
import '../../../scanner/presentation/widgets/floating_snap_iring_button.dart';
import '../../../stories/presentation/widgets/stories_tray.dart';
import '../../../territory/presentation/widgets/territory_setup_dialog.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/iring_center_button.dart';
import 'dashboard_page.dart';

class MainNavigationShell extends StatefulWidget {
  final AuthUser user;
  final AuthRepository authRepository;
  final MapRepository? mapRepository;
  final bool? initialOnline;
  final LocationAccessStatus? initialLocationStatus;
  final NetworkInfo? networkInfo;
  final LocationService? locationService;

  const MainNavigationShell({
    super.key,
    required this.user,
    required this.authRepository,
    this.mapRepository,
    this.initialOnline,
    this.initialLocationStatus,
    this.networkInfo,
    this.locationService,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isShowingMap = false;
  bool _keepMapVisibleDuringExit = false;
  Timer? _mapExitTimer;

  late final AnimationController _tabEnterController;
  late final Animation<double> _tabFade;
  late final Animation<Offset> _tabSlide;

  late final NetworkInfo _networkInfo;
  late final LocationService _locationService;
  StreamSubscription<bool>? _networkSubscription;
  StreamSubscription<bool>? _locationSubscription;

  late bool _isOnline;
  late bool _isLocationServiceEnabled;
  bool _dismissedOfflineBanner = false;
  bool _dismissedGpsBanner = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _tabEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    _tabFade = CurvedAnimation(
      parent: _tabEnterController,
      curve: Curves.easeOutCubic,
    );
    _tabSlide =
        Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _tabEnterController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pages = [
      _HomePage(user: widget.user, onOpenLeaderboard: () => _selectTab(2)),
      IringDexPage(user: widget.user),
      LeaderboardPage(
        currentUserId:
            widget.user.id.isNotEmpty ? widget.user.id : widget.user.email,
        initialBarangay: 'Bankal',
        initialCity: 'Lapu-Lapu City',
        initialCountry: 'Philippines',
        bottomPadding: 108.0,
        isAdmin: widget.user.isAdminRole,
        promptTerritorySetup: false,
      ),
      DashboardPage(
        user: widget.user,
        authRepository: widget.authRepository,
        onOpenMap: () => _setMapVisible(true),
      ),
    ];
    _networkInfo = widget.networkInfo ?? NetworkInfoImpl();
    _locationService = widget.locationService ?? LocationServiceImpl();
    _isOnline = widget.initialOnline ?? true;
    _isLocationServiceEnabled =
        widget.initialLocationStatus != LocationAccessStatus.serviceDisabled;

    _networkSubscription = _networkInfo.onConnectivityChanged.listen((status) {
      if (mounted) {
        setState(() {
          _isOnline = status;
          if (status) _dismissedOfflineBanner = false;
        });
      }
    });

    _locationSubscription = _locationService.onServiceStatusChanged.listen((
      enabled,
    ) {
      if (mounted) {
        setState(() {
          _isLocationServiceEnabled = enabled;
          if (enabled) _dismissedGpsBanner = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupModalsSequentially();
    });
  }

  Future<void> _runStartupModalsSequentially() async {
    if (!mounted) return;
    final userId =
        widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

    await TerritorySetupDialog.checkAndShow(context, userId: userId);
    if (!mounted || _isShowingMap) return;

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || _isShowingMap) return;

    await EventPopupModal.checkAndShow(
      context,
      userId: userId,
      userDisplayName: widget.user.displayName.isNotEmpty
          ? widget.user.displayName
          : widget.user.email.split('@').first,
      userPhotoUrl: widget.user.photoUrl,
    );
  }

  @override
  void dispose() {
    _mapExitTimer?.cancel();
    _tabEnterController.dispose();
    _networkSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _setMapVisible(bool show) {
    if (_isShowingMap == show) return;
    _mapExitTimer?.cancel();
    if (show) {
      setState(() {
        _isShowingMap = true;
        _keepMapVisibleDuringExit = true;
      });
    } else {
      setState(() {
        _isShowingMap = false;
        _keepMapVisibleDuringExit = true;
      });
      _tabEnterController.forward(from: 0.0);
      _mapExitTimer = Timer(const Duration(milliseconds: 240), () {
        if (mounted && !_isShowingMap) {
          setState(() => _keepMapVisibleDuringExit = false);
        }
      });
    }
  }

  void _selectTab(int index) {
    final changed = _currentIndex != index || _isShowingMap;
    if (_isShowingMap) {
      _setMapVisible(false);
    }
    setState(() {
      _currentIndex = index;
    });
    if (changed) {
      _tabEnterController.forward(from: 0.0);
    }
  }

  void _handleIringCenterTap() {
    _setMapVisible(!_isShowingMap);
  }

  void _openQuickSnapCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatScannerPage(
          user: widget.user,
          locationService: _locationService,
          autoLaunchCamera: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showOffline = !_isOnline && !_dismissedOfflineBanner;
    final showGpsDisabled =
        !_isLocationServiceEnabled && !_dismissedGpsBanner && !showOffline;
    final mapOnStage = _isShowingMap || _keepMapVisibleDuringExit;
    final isGirly = GirlyThemeProvider.isGirly(context);
    final bgColor = isGirly ? GirlyColors.background : AppColors.background;

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Offstage(
            offstage: _isShowingMap && !_keepMapVisibleDuringExit,
            child: IgnorePointer(
              ignoring: _isShowingMap,
              child: AnimatedScale(
                scale: _isShowingMap ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _isShowingMap ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: FadeTransition(
                    opacity: _tabFade,
                    child: SlideTransition(
                      position: _tabSlide,
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _pages,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Offstage(
            offstage: !mapOnStage,
            child: IgnorePointer(
              ignoring: !_isShowingMap,
              child: AnimatedSlide(
                offset: _isShowingMap ? Offset.zero : const Offset(0, 0.03),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _isShowingMap ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: TickerMode(
                    enabled: _isShowingMap,
                    child: LiveMapPage(
                      locationService: _locationService,
                      isMapActive: _isShowingMap,
                      currentUserId: widget.user.id.isNotEmpty
                          ? widget.user.id
                          : widget.user.email,
                      onClose: () => _setMapVisible(false),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showOffline)
            Positioned(
              top: _isShowingMap ? 56 : 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: FelineStatusBanner(
                  message:
                      'Offline mode: exploration is limited to cached territories.',
                  icon: Icons.pets,
                  actionLabel: 'Retry',
                  onAction: () async {
                    final online = await _networkInfo.isConnected;
                    if (mounted) {
                      setState(() => _isOnline = online);
                    }
                  },
                  onDismiss: () =>
                      setState(() => _dismissedOfflineBanner = true),
                ),
              ),
            )
          else if (showGpsDisabled)
            Positioned(
              top: _isShowingMap ? 56 : 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: FelineStatusBanner(
                  message:
                      'GPS disabled. Exploration map centered on Bankal default zone.',
                  icon: Icons.location_off,
                  actionLabel: 'Enable',
                  onAction: () => _locationService.openLocationSettings(),
                  onDismiss: () => setState(() => _dismissedGpsBanner = true),
                ),
              ),
            ),
          if (_currentIndex == 0 || _isShowingMap)
            FloatingSnapIringButton(
              onTap: _openQuickSnapCamera,
              bottomSafeMargin: _isShowingMap ? 246.0 : 128.0,
            ),
        ],
      ),
      floatingActionButton: IringCenterButton(
        onTap: _handleIringCenterTap,
        isMapOpen: _isShowingMap,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _isShowingMap ? -1 : _currentIndex,
        onTabSelected: _selectTab,
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  final AuthUser user;
  final VoidCallback? onOpenLeaderboard;

  const _HomePage({required this.user, this.onOpenLeaderboard});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  void initState() {
    super.initState();
    ExplorerHealthService.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : widget.user.email.split('@').first;

    final isGirly = GirlyThemeProvider.isGirly(context);
    final scaffoldBg = isGirly ? GirlyColors.background : AppColors.background;
    final titleColor =
        isGirly ? GirlyColors.textPrimary : AppColors.textPrimary;
    final dot1Color = isGirly ? GirlyColors.primary : AppColors.primary;
    final dot2Color = isGirly ? GirlyColors.accent : AppColors.calicoBlack;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot1Color,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot2Color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: TextStyle(color: titleColor),
            ),
          ],
        ),
        backgroundColor: scaffoldBg,
        foregroundColor: titleColor,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: GirlyThemeToggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<ExplorerHealthSnapshot>(
          stream: ExplorerHealthService.instance.stream,
          initialData: ExplorerHealthService.instance.latest,
          builder: (context, snapshot) {
            final health = snapshot.data ?? ExplorerHealthSnapshot.empty();

            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 12, bottom: 28),
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
                                      color: isGirly
                                          ? GirlyColors.navBarBg
                                          : AppColors.calicoBlack,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.pets_rounded,
                                          size: 11,
                                          color: isGirly
                                              ? GirlyColors.highlightPink
                                              : AppColors.primary,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Welcome back,',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
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
                                      color: isGirly
                                          ? GirlyColors.textPrimary
                                          : AppColors.textPrimary,
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
                            color: isGirly
                                ? GirlyColors.textSecondary
                                : AppColors.textSecondary,
                          ),
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
                                      color: isGirly
                                          ? GirlyColors.navBarBg
                                          : AppColors.calicoBlack,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      Icons.directions_walk_rounded,
                                      color: isGirly
                                          ? GirlyColors.highlightPink
                                          : AppColors.primary,
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
                                            color: isGirly
                                                ? GirlyColors.textPrimary
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Daily paw-patrol telemetry',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isGirly
                                                ? GirlyColors.textSecondary
                                                : AppColors.textSecondary,
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
                                    child: _MiniMetric(
                                      label: 'Steps',
                                      value: '${health.stepsToday}',
                                      icon: Icons.pets_rounded,
                                      accent: isGirly
                                          ? GirlyColors.primaryDark
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Distance',
                                      value:
                                          '${health.distanceKm.toStringAsFixed(2)} km',
                                      icon: Icons.route_rounded,
                                      accent: isGirly
                                          ? GirlyColors.primary
                                          : AppColors.calicoCharcoal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Calories',
                                      value:
                                          '${health.caloriesBurned.toStringAsFixed(0)} kcal',
                                      icon: Icons.local_fire_department_rounded,
                                      accent: isGirly
                                          ? GirlyColors.primaryDark
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Active',
                                      value: '${health.activeMinutes} min',
                                      icon: Icons.bolt_rounded,
                                      accent: isGirly
                                          ? GirlyColors.primary
                                          : AppColors.calicoCharcoal,
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
                        ),
                        const SizedBox(height: 24),
                        PawQuestsSection(
                          userId: widget.user.id.isNotEmpty
                              ? widget.user.id
                              : widget.user.email,
                          isAdmin: widget.user.isAdminRole,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 112),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    final cardBg = isGirly
        ? GirlyColors.creamSurface.withAlpha(200)
        : AppColors.creamSurface.withAlpha(160);
    final cardBorder = isGirly ? GirlyColors.border : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isGirly ? 18 : 14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isGirly
                      ? GirlyColors.textSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color:
                    isGirly ? GirlyColors.textPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
