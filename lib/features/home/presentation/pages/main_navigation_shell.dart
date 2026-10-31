import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../../core/widgets/feline_status_banner.dart';
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

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isShowingMap = false;

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
    _pages = [
      _HomePage(
        user: widget.user,
        onOpenLeaderboard: () => setState(() => _currentIndex = 2),
      ),
      IringDexPage(user: widget.user),
      LeaderboardPage(
        currentUserId: widget.user.id.isNotEmpty
            ? widget.user.id
            : widget.user.email,
        initialBarangay: 'Bankal',
        initialCity: 'Lapu-Lapu City',
        initialCountry: 'Philippines',
        bottomPadding: 84.0,
        isAdmin: widget.user.isAdminRole,
      ),
      DashboardPage(
        user: widget.user,
        authRepository: widget.authRepository,
        onOpenMap: () => setState(() {
          _isShowingMap = true;
        }),
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
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _handleIringCenterTap() {
    setState(() {
      _isShowingMap = !_isShowingMap;
    });
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

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Offstage(
            offstage: _isShowingMap,
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
          Offstage(
            offstage: !_isShowingMap,
            child: TickerMode(
              enabled: _isShowingMap,
              child: LiveMapPage(
                locationService: _locationService,
                isMapActive: _isShowingMap,
                currentUserId: widget.user.id.isNotEmpty
                    ? widget.user.id
                    : widget.user.email,
                onClose: () => setState(() {
                  _isShowingMap = false;
                }),
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
                  message: 'Offline mode: exploration is limited to cached territories.',
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
                  message: 'GPS disabled. Exploration map centered on Bankal default zone.',
                  icon: Icons.location_off,
                  actionLabel: 'Enable',
                  onAction: () => _locationService.openLocationSettings(),
                  onDismiss: () => setState(() => _dismissedGpsBanner = true),
                ),
              ),
            ),
          if (_currentIndex == 0 && !_isShowingMap)
            FloatingSnapIringButton(onTap: _openQuickSnapCamera),
        ],
      ),
      floatingActionButton: IringCenterButton(onTap: _handleIringCenterTap),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _isShowingMap ? -1 : _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _isShowingMap = false;
            _currentIndex = index;
          });
        },
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        EventPopupModal.checkAndShow(
          context,
          userId: widget.user.id.isNotEmpty
              ? widget.user.id
              : widget.user.email,
          userDisplayName: widget.user.displayName.isNotEmpty
              ? widget.user.displayName
              : widget.user.email.split('@').first,
          userPhotoUrl: widget.user.photoUrl,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : widget.user.email.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<ExplorerHealthSnapshot>(
          stream: ExplorerHealthService.instance.stream,
          initialData: ExplorerHealthService.instance.latest,
          builder: (context, snapshot) {
            final health = snapshot.data ?? ExplorerHealthSnapshot.empty();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
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
                                  const Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      height: 1.15,
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
                        const SizedBox(height: 4),
                        const Text(
                          'Track your daily explorer movement and unlock more feline routes.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.directions_walk_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Explorer Health',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Steps',
                                      value: '${health.stepsToday}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Distance',
                                      value:
                                          '${health.distanceKm.toStringAsFixed(2)} km',
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
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Active',
                                      value: '${health.activeMinutes} min',
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
                  const SizedBox(height: 96),
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

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
