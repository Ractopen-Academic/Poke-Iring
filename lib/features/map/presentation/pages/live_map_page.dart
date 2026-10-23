import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_status_banner.dart';
import '../../data/datasources/cached_tile_provider.dart';

class LiveMapPage extends StatefulWidget {
  final LatLng initialCenter;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;
  final VoidCallback? onClose;
  final VoidCallback? onTileError;

  const LiveMapPage({
    super.key,
    this.initialCenter = const LatLng(
      10.3140,
      123.9720,
    ), // Bankal, Lapu-Lapu City
    this.onPointerDown,
    this.onPointerUp,
    this.onClose,
    this.onTileError,
  });

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController _mapController = MapController();
  double _currentRotation = 0.0;
  bool _hasTileError = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenter() {
    _mapController.move(widget.initialCenter, 16.0);
  }

  void _resetToNorth() {
    _mapController.rotate(0.0);
    setState(() {
      _currentRotation = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Listener(
            onPointerDown: (_) => widget.onPointerDown?.call(),
            onPointerUp: (_) => widget.onPointerUp?.call(),
            onPointerCancel: (_) => widget.onPointerUp?.call(),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter,
                initialZoom: 16.0,
                minZoom: 12.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPositionChanged: (camera, hasGesture) {
                  if (_currentRotation != camera.rotation) {
                    setState(() {
                      _currentRotation = camera.rotation;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.ryme.pokeiring',
                  tileProvider: CachedTileProvider(),
                  evictErrorTileStrategy: EvictErrorTileStrategy.none,
                  errorTileCallback: (tile, error, stackTrace) {
                    if (!_hasTileError && mounted) {
                      setState(() {
                        _hasTileError = true;
                      });
                      widget.onTileError?.call();
                    }
                  },
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.initialCenter,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withAlpha(50),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade700,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Bankal, Lapu-Lapu City',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _resetToNorth,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Transform.rotate(
                          angle: -_currentRotation * (math.pi / 180),
                          child: const Icon(
                            Icons.navigation,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hasTileError)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: SafeArea(
                child: FelineStatusBanner(
                  message:
                      'Network issue loading tiles. Serving cached feline map.',
                  icon: Icons.pets,
                  onDismiss: () {
                    setState(() {
                      _hasTileError = false;
                    });
                  },
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.small(
              heroTag: 'recenter_bankal',
              onPressed: _recenter,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              tooltip: 'Recenter to Bankal',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
