import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../data/services/tile_precache_service_impl.dart';
import '../../domain/services/tile_precache_service.dart';

/// Interactive Google-Maps style crop selector for downloading offline map areas.
class OfflineMapDownloadDialog extends StatefulWidget {
  final LatLng initialCenter;
  final TilePrecacheService? precacheService;

  const OfflineMapDownloadDialog({
    super.key,
    required this.initialCenter,
    this.precacheService,
  });

  static Future<void> show(
    BuildContext context, {
    required LatLng initialCenter,
    TilePrecacheService? precacheService,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => OfflineMapDownloadDialog(
          initialCenter: initialCenter,
          precacheService: precacheService,
        ),
      ),
    );
  }

  @override
  State<OfflineMapDownloadDialog> createState() =>
      _OfflineMapDownloadDialogState();
}

class _OfflineMapDownloadDialogState extends State<OfflineMapDownloadDialog> {
  late final MapController _mapController;
  late final TilePrecacheService _precacheService;

  LatLng _currentCenter = const LatLng(10.3140, 123.9720);
  double _currentZoom = 15.0;

  bool _isDownloading = false;
  int _estimatedTiles = 25;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialCenter;
    _mapController = MapController();
    _precacheService = widget.precacheService ?? TilePrecacheServiceImpl();
    _updateEstimate();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _updateEstimate() {
    // Crop box covers roughly 2x2 to 3x3 tiles per zoom level
    // We cache zooms 14, 15, 16 for high detail offline navigation
    final baseCount = (_currentZoom >= 16) ? 36 : 28;
    setState(() {
      _estimatedTiles = baseCount;
    });
  }

  Future<void> _startDownload() async {
    final isOnline = await NetworkInfoImpl().isConnected;
    if (!isOnline) {
      setState(() {
        _errorMessage =
            'Active internet connection required to download offline map tiles.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _statusMessage = 'Downloading offline map area...';
    });

    try {
      // Calculate cropped rectangle coordinates around map center
      // Crop frame is roughly 3km wide by 2km tall at current zoom
      final latDelta = 0.015;
      final lonDelta = 0.018;

      final northEast = LatLng(
        _currentCenter.latitude + latDelta,
        _currentCenter.longitude + lonDelta,
      );
      final southWest = LatLng(
        _currentCenter.latitude - latDelta,
        _currentCenter.longitude - lonDelta,
      );

      final cached = await _precacheService.precacheBoundingBox(
        northEast: northEast,
        southWest: southWest,
        zoomLevels: const [14, 15, 16],
      );

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _statusMessage =
            'Success! Downloaded $cached map tiles for offline exploration.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded $cached map tiles. Area is now available offline!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Download interrupted: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          'Download Offline Map',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        actions: [
          if (!_isDownloading)
            TextButton(
              onPressed: _startDownload,
              child: const Text(
                'Download',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15.0,
              minZoom: 12.0,
              maxZoom: 17.0,
              onPositionChanged: (camera, hasGesture) {
                _currentCenter = camera.center;
                _currentZoom = camera.zoom;
                _updateEstimate();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.ryme.pokeiring',
              ),
            ],
          ),

          // Google-Maps style crop frame overlay
          IgnorePointer(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.50,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),

          // Instruction and Download banner at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.dynamicSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.crop_free_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pan & Zoom to Select Area',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dynamicTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Position the rectangle over the territory or barangay you want to explore offline without internet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.dynamicTextSecondary,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isDownloading ? null : _startDownload,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isDownloading
                            ? 'Downloading Offline Area...'
                            : 'Download Crop Area (~$_estimatedTiles tiles)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
