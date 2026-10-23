import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
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

class _AppBootstrapPageState extends State<AppBootstrapPage> {
  late final NetworkInfo _networkInfo;
  late final LocationService _locationService;
  late final TilePrecacheService _tilePrecacheService;

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

    _runBootstrap();
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
              zoomLevels: const [15, 16],
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Poke: Iring',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 140,
                    height: 4,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
