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
import '../../../health/services/explorer_health_service.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../leaderboard/presentation/widgets/home_leaderboard_preview.dart';
import '../../../map/domain/repositories/map_repository.dart';
import '../../../map/presentation/pages/live_map_page.dart';
import '../../../scanner/presentation/widgets/floating_snap_iring_button.dart';
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
      const _AlbumPlaceholderPage(),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Snap an Iring',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Point camera at a spotted cat to log it',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets, size: 36, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      'Quick Cat Camera Viewfinder',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'AI breed classifier ready',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Close Preview',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                  const SizedBox(height: 20),
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
                    progressText: 'Walking today',
                    progress: 0.2,
                  ),
                  const SizedBox(height: 12),
                  const _QuestCard(
                    title: 'Cartographer Step',
                    description: 'Walk 1.5 km while scanning sightings',
                    progressText: 'Progress active',
                    progress: 0.53,
                  ),
                  const SizedBox(height: 12),
                  const _QuestCard(
                    title: 'Calico Whispers',
                    description: 'Spot a domestic calico or tabby pattern',
                    progressText: 'Active task',
                    progress: 0.2,
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

class _AlbumPlaceholderPage extends StatelessWidget {
  const _AlbumPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cat Album'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withAlpha(25),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cat Portrait Gallery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All cat portraits and sightings captured during your neighborhood explorations appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

