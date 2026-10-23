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
import '../../../map/domain/repositories/map_repository.dart';
import '../../../map/presentation/pages/live_map_page.dart';
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
      _HomePage(user: widget.user),
      const _AlbumPlaceholderPage(),
      const _ShowcasePlaceholderPage(),
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

class _HomePage extends StatelessWidget {
  final AuthUser user;

  const _HomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isNotEmpty
        ? user.displayName
        : user.email.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                'Complete daily feline quests to unlock rare catalog badges.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const _QuestCard(
                title: 'Morning Prowler',
                description: 'Scan 1 cat before noon in your neighborhood',
                progressText: '0 / 1 complete',
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
                progressText: 'Active task',
                progress: 0.2,
              ),
            ],
          ),
        ),
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

class _ShowcasePlaceholderPage extends StatelessWidget {
  const _ShowcasePlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Showcase'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Feline Spotlight',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Exhibit your finest cat portraits and featured community discoveries.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(25),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Pinned Highlights Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pin your favorite captured shots from your Album to feature them here on your showcase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
