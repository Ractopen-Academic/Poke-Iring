import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../../core/widgets/feline_status_banner.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../dex/presentation/pages/iring_dex_page.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../leaderboard/presentation/widgets/home_leaderboard_preview.dart';
import '../../../map/domain/repositories/map_repository.dart';
import '../../../map/presentation/pages/live_map_page.dart';
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
  bool _isNavbarVisible = true;
  Timer? _idleTimer;

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
      ),
      DashboardPage(
        user: widget.user,
        authRepository: widget.authRepository,
        onOpenMap: () => setState(() {
          _isShowingMap = true;
          _isNavbarVisible = true;
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
    _idleTimer?.cancel();
    _networkSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _handleIringCenterTap() {
    setState(() {
      _isShowingMap = !_isShowingMap;
      _isNavbarVisible = true;
    });
  }

  void _onMapPointerDown() {
    _idleTimer?.cancel();
    if (_isNavbarVisible) {
      setState(() {
        _isNavbarVisible = false;
      });
    }
  }

  void _onMapPointerUp() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted && !_isNavbarVisible) {
        setState(() {
          _isNavbarVisible = true;
        });
      }
    });
  }

  void _openQuickSnapCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatScannerPage(
          user: widget.user,
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
                onPointerDown: _onMapPointerDown,
                onPointerUp: _onMapPointerUp,
                onClose: () => setState(() {
                  _isShowingMap = false;
                  _isNavbarVisible = true;
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
          if (_isShowingMap || _currentIndex != 2)
            FloatingSnapIringButton(onTap: _openQuickSnapCamera),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        offset: _isNavbarVisible ? Offset.zero : const Offset(0, 2.5),
        child: IringCenterButton(onTap: _handleIringCenterTap),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        offset: _isNavbarVisible ? Offset.zero : const Offset(0, 1.5),
        child: AppBottomNavBar(
          currentIndex: _isShowingMap ? -1 : _currentIndex,
          onTabSelected: (index) {
            setState(() {
              _isShowingMap = false;
              _currentIndex = index;
              _isNavbarVisible = true;
            });
          },
        ),
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  final AuthUser user;
  final VoidCallback? onOpenLeaderboard;

  const _HomePage({
    required this.user,
    this.onOpenLeaderboard,
  });

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome, $name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track your daily explorer movement and unlock more feline routes.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  StoriesTray(user: widget.user),
                  const SizedBox(height: 16),
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
                                value: '${health.distanceKm.toStringAsFixed(2)} km',
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
                                value: '${health.caloriesBurned.toStringAsFixed(0)} kcal',
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
                  const SizedBox(height: 24),
                  const _QuestCard(
                    title: 'Morning Prowler',
                    description: 'Scan 1 cat before noon in your neighborhood',
                    progressText: '0 / 1 Scanned',
                    progress: 0.0,
                  ),
                  const SizedBox(height: 12),
                  const _QuestCard(
                    title: 'Cartographer Step',
                    description: 'Walk 1.5 km while scanning sightings',
                    progressText: '0.8 / 1.5 km',
                    progress: 0.53,
                  ),
                  const SizedBox(height: 12),
                  const _QuestCard(
                    title: 'Calico Whispers',
                    description: 'Spot a domestic calico or tabby pattern',
                    progressText: '1 / 1 Spotted',
                    progress: 1.0,
                  ),
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

class _QuestCard extends StatelessWidget {
  final String title;
  final String description;
  final String progressText;
  final double progress;

  const _QuestCard({
    required this.title,
    required this.description,
    required this.progressText,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

