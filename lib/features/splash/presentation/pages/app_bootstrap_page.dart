import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../auth/presentation/widgets/calico_login_mascot.dart';
import '../../../map/data/services/tile_precache_service_impl.dart';
import '../../../map/domain/services/tile_precache_service.dart';

class BootstrapResult {
  final bool isOnline;
  final LocationAccessStatus locationStatus;
  final int cachedTiles;

  const BootstrapResult({
    required this.isOnline,
    required this.locationStatus,
    this.cachedTiles = 0,
  });
}

class AppBootstrapPage extends StatefulWidget {
  final Widget Function(BuildContext context, BootstrapResult result) onReady;
  final NetworkInfo? networkInfo;
  final LocationService? locationService;
  final TilePrecacheService? tilePrecacheService;

  const AppBootstrapPage({
    super.key,
    required this.onReady,
    this.networkInfo,
    this.locationService,
    this.tilePrecacheService,
  });

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage>
    with SingleTickerProviderStateMixin {
  late final NetworkInfo _networkInfo;
  late final LocationService _locationService;
  late final TilePrecacheService _tilePrecacheService;
  late final AnimationController _breathingController;
  late final Animation<double> _breathingScale;
  late final Animation<double> _subtleBob;

  String _statusText = 'Initializing services...';
  double _progress = 0.15;
  BootstrapResult? _result;

  @override
  void initState() {
    super.initState();
    _networkInfo = widget.networkInfo ?? NetworkInfoImpl();
    _locationService = widget.locationService ?? LocationServiceImpl();
    _tilePrecacheService =
        widget.tilePrecacheService ?? TilePrecacheServiceImpl();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _breathingScale = Tween<double>(begin: 0.975, end: 1.025).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _subtleBob = Tween<double>(begin: 2.0, end: -3.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _runBootstrap();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> _runBootstrap() async {
    bool isOnline = false;
    LocationAccessStatus locationStatus = LocationAccessStatus.serviceDisabled;
    var cachedTiles = 0;

    try {
      setState(() {
        _statusText = 'Checking connectivity...';
        _progress = 0.35;
      });
      isOnline = await _networkInfo.isConnected;

      setState(() {
        _statusText = 'Verifying GPS permissions...';
        _progress = 0.60;
      });
      locationStatus = await _locationService.checkStatus();

      if (isOnline) {
        setState(() {
          _statusText = 'Pre-caching exploration map...';
          _progress = 0.85;
        });

        // Precache Bankal, Lapu-Lapu City base grid with safety timeout
        cachedTiles = await _tilePrecacheService
            .precacheArea(
              center: const LatLng(10.3140, 123.9720),
              zoomLevels: const [16],
              radiusTiles: 1,
            )
            .timeout(const Duration(milliseconds: 2500), onTimeout: () => 0);
      }
    } catch (_) {
      // Degrade gracefully without crashing
    }

    if (!mounted) return;

    setState(() {
      _statusText = 'Ready';
      _progress = 1.0;
      _result = BootstrapResult(
        isOnline: isOnline,
        locationStatus: locationStatus,
        cachedTiles: cachedTiles,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return widget.onReady(context, _result!);
    }

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      body: CalicoAmbientBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.dynamicPrimary.withAlpha(26),
                                  AppColors.dynamicPrimary.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _breathingController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _subtleBob.value),
                                child: Transform.scale(
                                  scale: _breathingScale.value,
                                  child: child,
                                ),
                              );
                            },
                            child: const SizedBox(
                              width: 140,
                              height: 110,
                              child: CalicoLoginMascot(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dynamicTextSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: SizedBox(
                          width: 170,
                          height: 6,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: _progress),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            builder: (context, progressVal, _) {
                              return LinearProgressIndicator(
                                value: progressVal,
                                backgroundColor: AppColors.dynamicProgressTrack,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.dynamicPrimary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 12,
                child: Text(
                  AppVersion.releaseTag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicTextSecondary.withAlpha(140),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
