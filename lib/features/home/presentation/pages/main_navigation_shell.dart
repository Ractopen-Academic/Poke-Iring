import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../../core/widgets/feline_status_banner.dart';
import '../../../../core/widgets/persistent_version_overlay.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../dex/presentation/pages/iring_dex_page.dart';
import '../../../events/presentation/widgets/event_popup_modal.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../map/domain/repositories/map_repository.dart';
import '../../../map/presentation/pages/live_map_page.dart';
import '../../../scanner/presentation/pages/cat_scanner_page.dart';
import '../../../scanner/presentation/widgets/floating_snap_iring_button.dart';
import '../../../territory/presentation/widgets/territory_setup_dialog.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/iring_center_button.dart';
import 'dashboard_page.dart';
import 'home_feed_page.dart';

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

  @visibleForTesting
  static void resetModalState() {
    _MainNavigationShellState._hasRunStartupModals = false;
  }

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  static int _activeTabIndex = 0;
  static bool _hasRunStartupModals = false;

  late int _currentIndex;
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

  List<Widget> _buildPages() {
    final coatName = CalicoThemeController.instance.effectiveMode.name;
    return [
      HomeFeedPage(
        key: ValueKey('home_tab_$coatName'),
        user: widget.user,
        onOpenLeaderboard: () => _selectTab(2),
      ),
      IringDexPage(key: ValueKey('dex_tab_$coatName'), user: widget.user),
      LeaderboardPage(
        key: ValueKey('leaderboard_tab_$coatName'),
        currentUserId: widget.user.id.isNotEmpty
            ? widget.user.id
            : widget.user.email,
        initialBarangay: 'Bankal',
        initialCity: 'Lapu-Lapu City',
        initialCountry: 'Philippines',
        bottomPadding: 108.0,
        isAdmin: widget.user.isAdminRole,
        promptTerritorySetup: false,
      ),
      DashboardPage(
        key: ValueKey('dashboard_tab_$coatName'),
        user: widget.user,
        authRepository: widget.authRepository,
        onOpenMap: () => _setMapVisible(true),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    AppVersionOverlayController.instance.setBottomNavActive(true);
    _currentIndex = _activeTabIndex;
    CalicoThemeController.instance.addListener(_handleCoatModeChanged);
    _tabEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    _tabFade = CurvedAnimation(
      parent: _tabEnterController,
      curve: Curves.easeOutCubic,
    );
    _tabSlide = Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _tabEnterController,
            curve: Curves.easeOutCubic,
          ),
        );
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
    if (!mounted || _hasRunStartupModals) return;
    _hasRunStartupModals = true;
    final userId = widget.user.id.isNotEmpty
        ? widget.user.id
        : widget.user.email;

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
    AppVersionOverlayController.instance.setBottomNavActive(false);
    CalicoThemeController.instance.removeListener(_handleCoatModeChanged);
    _mapExitTimer?.cancel();
    _tabEnterController.dispose();
    _networkSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _handleCoatModeChanged() {
    if (mounted) setState(() {});
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
    _activeTabIndex = index;
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
    return ListenableBuilder(
      listenable: CalicoThemeController.instance,
      builder: (context, _) {
        final showOffline = !_isOnline && !_dismissedOfflineBanner;
        final showGpsDisabled =
            !_isLocationServiceEnabled && !_dismissedGpsBanner && !showOffline;
        final mapOnStage = _isShowingMap || _keepMapVisibleDuringExit;

        return Scaffold(
          extendBody: true,
          backgroundColor: AppColors.dynamicBackground,
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
                            children: _buildPages(),
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
                      onDismiss: () =>
                          setState(() => _dismissedGpsBanner = true),
                    ),
                  ),
                ),
              if (_isShowingMap)
                FloatingSnapIringButton(
                  onTap: _openQuickSnapCamera,
                  bottomSafeMargin: 246.0,
                ),
            ],
          ),
          floatingActionButton: IringCenterButton(
            onTap: _handleIringCenterTap,
            isMapOpen: _isShowingMap,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _isShowingMap ? -1 : _currentIndex,
            onTabSelected: _selectTab,
          ),
        );
      },
    );
  }
}
