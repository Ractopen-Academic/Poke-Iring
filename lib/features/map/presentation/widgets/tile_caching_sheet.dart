import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/network_info_impl.dart';
import '../../data/services/tile_precache_service_impl.dart';
import '../../domain/services/tile_precache_service.dart';

class TileCachingSheet extends StatefulWidget {
  final LatLng currentCenter;
  final double currentZoom;
  final TilePrecacheService? precacheService;

  const TileCachingSheet({
    super.key,
    required this.currentCenter,
    required this.currentZoom,
    this.precacheService,
  });

  static Future<void> show(
    BuildContext context, {
    required LatLng currentCenter,
    required double currentZoom,
    TilePrecacheService? precacheService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TileCachingSheet(
        currentCenter: currentCenter,
        currentZoom: currentZoom,
        precacheService: precacheService,
      ),
    );
  }

  @override
  State<TileCachingSheet> createState() => _TileCachingSheetState();
}

class _TileCachingSheetState extends State<TileCachingSheet> {
  late final TilePrecacheService _precacheService;
  final Set<int> _selectedZooms = {15, 16};
  int _radiusTiles = 1;

  bool _isDownloading = false;
  bool _isCancelled = false;
  int _downloadedCount = 0;
  int _totalTiles = 0;
  String? _statusMessage;
  String? _errorMessage;

  static const int _maxSafeTileCap = 250;

  @override
  void initState() {
    super.initState();
    _precacheService = widget.precacheService ?? TilePrecacheServiceImpl();
    _recomputeTotal();
  }

  void _recomputeTotal() {
    // Each zoom level downloads (2*r + 1)^2 tiles
    final tilesPerZoom = (2 * _radiusTiles + 1) * (2 * _radiusTiles + 1);
    setState(() {
      _totalTiles = _selectedZooms.length * tilesPerZoom;
    });
  }

  Future<void> _startPrecaching() async {
    if (_totalTiles > _maxSafeTileCap) {
      setState(() {
        _errorMessage =
            'Safety cap exceeded. Maximum $_maxSafeTileCap tiles permitted to respect OpenStreetMap usage limits.';
      });
      return;
    }

    final isOnline = await NetworkInfoImpl().isConnected;
    if (!isOnline) {
      setState(() {
        _errorMessage = 'Network or server error: Pre-caching requires an active online internet connection.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _isCancelled = false;
      _downloadedCount = 0;
      _errorMessage = null;
      _statusMessage = 'Downloading tile grid...';
    });

    try {
      final sortedZooms = _selectedZooms.toList()..sort();
      var cached = 0;

      for (final zoom in sortedZooms) {
        if (_isCancelled) break;
        final res = await _precacheService.precacheArea(
          center: widget.currentCenter,
          zoomLevels: [zoom],
          radiusTiles: _radiusTiles,
        );
        cached += res;
        if (mounted) {
          setState(() {
            _downloadedCount = cached;
          });
        }
      }

      if (!mounted) return;

      if (_isCancelled) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'Pre-caching cancelled by explorer.';
        });
      } else {
        setState(() {
          _isDownloading = false;
          _statusMessage =
              'Completed. Successfully pre-cached $_downloadedCount tiles for this viewport.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage =
            'Server or network error encountered during map tile caching.';
      });
    }
  }

  void _cancelPrecaching() {
    setState(() {
      _isCancelled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalTiles > 0
        ? (_downloadedCount / _totalTiles).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dynamicBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.download_for_offline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Region Map Tile Caching',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                    Text(
                      'Center: ${widget.currentCenter.latitude.toStringAsFixed(4)}, ${widget.currentCenter.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zoom selection
          Text(
            'Zoom Levels',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.dynamicTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [14, 15, 16, 17].map((z) {
              final isSel = _selectedZooms.contains(z);
              return FilterChip(
                label: Text('Zoom $z'),
                selected: isSel,
                onSelected: _isDownloading
                    ? null
                    : (val) {
                        setState(() {
                          if (val) {
                            _selectedZooms.add(z);
                          } else if (_selectedZooms.length > 1) {
                            _selectedZooms.remove(z);
                          }
                          _recomputeTotal();
                        });
                      },
                selectedColor: AppColors.primary.withAlpha(35),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSel
                      ? AppColors.primary
                      : AppColors.dynamicTextSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Radius selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cache Radius: ${_radiusTiles == 1 ? "1 Ring (9 tiles/zoom)" : "2 Rings (25 tiles/zoom)"}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
              DropdownButton<int>(
                value: _radiusTiles,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Ring (Compact)')),
                  DropdownMenuItem(value: 2, child: Text('2 Rings (Wide)')),
                ],
                onChanged: _isDownloading
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _radiusTiles = val;
                            _recomputeTotal();
                          });
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tile count notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.dynamicFieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Tiles to Cache:',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.dynamicTextSecondary,
                  ),
                ),
                Text(
                  '$_totalTiles tiles (Cap: $_maxSafeTileCap)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _totalTiles > _maxSafeTileCap
                        ? const Color(0xFFEF4444)
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF4444).withAlpha(80),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),

          if (_statusMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
            ),

          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.dynamicProgressTrack,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: $_downloadedCount / $_totalTiles (${(progress * 100).toStringAsFixed(0)}%)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.dynamicTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _cancelPrecaching,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: BorderSide(color: const Color(0xFFEF4444).withAlpha(120)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Caching',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _startPrecaching,
              icon: const Icon(Icons.cloud_download_rounded, size: 18),
              label: Text(
                'Cache Viewport Grid ($_totalTiles Tiles)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
