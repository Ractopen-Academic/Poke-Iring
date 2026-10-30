import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../map/data/datasources/cached_tile_provider.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../../scanner/presentation/widgets/cat_sighting_detail_sheet.dart';

class PersonalSightingHeatmap extends StatefulWidget {
  final List<CatSighting> sightings;
  final AuthUser user;
  final VoidCallback onOpenScanner;

  const PersonalSightingHeatmap({
    super.key,
    required this.sightings,
    required this.user,
    required this.onOpenScanner,
  });

  @override
  State<PersonalSightingHeatmap> createState() =>
      _PersonalSightingHeatmapState();
}

class _PersonalSightingHeatmapState extends State<PersonalSightingHeatmap> {
  final MapController _mapController = MapController();
  late final TileProvider _tileProvider;
  String _selectedTierFilter = 'all';

  static const LatLng _defaultCenter = LatLng(10.3140, 123.9720);

  @override
  void initState() {
    super.initState();
    _tileProvider = CachedTileProvider();
  }

  List<CatSighting> get _filteredSightings {
    if (_selectedTierFilter == 'all') return widget.sightings;
    return widget.sightings
        .where((s) => s.metallicTier.toLowerCase() == _selectedTierFilter)
        .toList();
  }

  LatLng get _initialCenter {
    if (widget.sightings.isEmpty) return _defaultCenter;
    final latSum = widget.sightings.fold<double>(
      0.0,
      (sum, s) => sum + s.latitude,
    );
    final lngSum = widget.sightings.fold<double>(
      0.0,
      (sum, s) => sum + s.longitude,
    );
    return LatLng(
      latSum / widget.sightings.length,
      lngSum / widget.sightings.length,
    );
  }

  void _recenterView() {
    if (widget.sightings.isEmpty) {
      _mapController.move(_defaultCenter, 15.0);
      return;
    }

    if (widget.sightings.length == 1) {
      final s = widget.sightings.first;
      _mapController.move(LatLng(s.latitude, s.longitude), 16.0);
      return;
    }

    double minLat = widget.sightings.first.latitude;
    double maxLat = widget.sightings.first.latitude;
    double minLng = widget.sightings.first.longitude;
    double maxLng = widget.sightings.first.longitude;

    for (final s in widget.sightings) {
      minLat = math.min(minLat, s.latitude);
      maxLat = math.max(maxLat, s.latitude);
      minLng = math.min(minLng, s.longitude);
      maxLng = math.max(maxLng, s.longitude);
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48.0)),
    );
  }

  Color _getMetallicBorderColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFCFD8DC);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSightings = _filteredSightings;
    final hasSightings = widget.sightings.isNotEmpty;

    return Container(
      height: 520,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 15.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ryme.pokeiring',
                tileProvider: _tileProvider,
                maxNativeZoom: 19,
              ),
              CircleLayer(
                circles: [
                  for (final s in activeSightings) ...[
                    // Outer ambient radial heat
                    CircleMarker(
                      point: LatLng(s.latitude, s.longitude),
                      radius: 52,
                      useRadiusInMeter: true,
                      color: const Color(0xFFE65100).withAlpha(35),
                      borderStrokeWidth: 0,
                    ),
                    // Mid-layer heat glow
                    CircleMarker(
                      point: LatLng(s.latitude, s.longitude),
                      radius: 28,
                      useRadiusInMeter: true,
                      color: const Color(0xFFFF9800).withAlpha(70),
                      borderStrokeWidth: 0,
                    ),
                    // High-density core
                    CircleMarker(
                      point: LatLng(s.latitude, s.longitude),
                      radius: 12,
                      useRadiusInMeter: true,
                      color: const Color(0xFFFFD54F).withAlpha(140),
                      borderStrokeWidth: 0,
                    ),
                    // Thermal epicenter
                    CircleMarker(
                      point: LatLng(s.latitude, s.longitude),
                      radius: 4,
                      useRadiusInMeter: true,
                      color: const Color(0xFFFF3D00).withAlpha(200),
                      borderStrokeWidth: 0,
                    ),
                  ],
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final s in activeSightings)
                    Marker(
                      point: LatLng(s.latitude, s.longitude),
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () {
                          CatSightingDetailSheet.show(
                            context: context,
                            sighting: s,
                            currentUserId: widget.user.id,
                            onBoop: () {},
                          );
                        },
                        child: _buildHeatmapPin(s),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Header Overlay with Filters and Stats
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(235),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${activeSightings.length} Heatspots',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withAlpha(235),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _recenterView,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.my_location,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tierFilterChip('All', 'all'),
                      const SizedBox(width: 6),
                      _tierFilterChip(
                        'Gold Tier',
                        'gold',
                        const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 6),
                      _tierFilterChip(
                        'Silver Tier',
                        'silver',
                        const Color(0xFFB0BEC5),
                      ),
                      const SizedBox(width: 6),
                      _tierFilterChip(
                        'Bronze Tier',
                        'bronze',
                        const Color(0xFFCD7F32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Empty State / Guidance Overlay
          if (!hasSightings)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(245),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No Personal Sightings Mapped Yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Photograph roaming cats using the camera to paint your discovery heatmap across the territory.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: widget.onOpenScanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text(
                        'Snap First Cat',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
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

  Widget _tierFilterChip(String label, String tier, [Color? accentColor]) {
    final isSelected = _selectedTierFilter == tier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTierFilter = tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.white.withAlpha(225),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (accentColor ?? Colors.black)
                : const Color(0xFFD1D5DB),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accentColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapPin(CatSighting sighting) {
    final borderColor = _getMetallicBorderColor(sighting.metallicTier);
    final imageUri = sighting.stickerUrl.isNotEmpty
        ? sighting.stickerUrl
        : sighting.photoUrl;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2.8),
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(130),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUri.isNotEmpty
            ? _buildPinImage(imageUri)
            : const Icon(Icons.pets, size: 20, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPinImage(String uri) {
    if (uri.startsWith('data:image')) {
      try {
        final b64 = uri.contains(',') ? uri.split(',').last : uri;
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.pets, size: 20, color: AppColors.primary),
        );
      } catch (_) {}
    } else {
      return CachedNetworkImage(
        imageUrl: uri,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            const Icon(Icons.pets, size: 20, color: AppColors.primary),
      );
    }
    return const Icon(Icons.pets, size: 20, color: AppColors.primary);
  }
}
