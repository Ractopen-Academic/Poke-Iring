import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/live_sighting.dart';
import '../../domain/repositories/map_repository.dart';
import '../widgets/cat_marker_avatar.dart';
import '../widgets/sighting_inspection_sheet.dart';

class LiveMapPage extends StatefulWidget {
  final MapRepository mapRepository;
  final LatLng initialCenter;

  const LiveMapPage({
    super.key,
    required this.mapRepository,
    this.initialCenter = const LatLng(
      10.3140,
      123.9720,
    ), // Bankal, Lapu-Lapu City
  });

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController _mapController = MapController();
  late StreamSubscription<List<LiveSighting>> _subscription;
  List<LiveSighting> _activeSightings = [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _subscription = widget.mapRepository.getActiveSightingsStream().listen((
      sightings,
    ) {
      if (mounted) {
        setState(() {
          _activeSightings = sightings;
        });
      }
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _activeSightings = _activeSightings
              .where((s) => !s.isExpired)
              .toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _ticker?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _recenter() {
    _mapController.move(widget.initialCenter, 16.0);
  }

  Future<void> _dropSimulatedSighting() async {
    final now = DateTime.now();
    final randomOffsetLat = (now.second % 10 - 5) * 0.0004;
    final randomOffsetLng = (now.millisecond % 10 - 5) * 0.0004;

    final newSighting = LiveSighting(
      id: 'cat_${now.millisecondsSinceEpoch}',
      latitude: widget.initialCenter.latitude + randomOffsetLat,
      longitude: widget.initialCenter.longitude + randomOffsetLng,
      breed: 'Philippine Forest Puspin',
      rarity: now.second % 2 == 0 ? 'Rare' : 'Common',
      confidence: 0.94,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 10)),
    );

    await widget.mapRepository.dropSighting(newSighting);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcasted new 10-minute cat sighting in Bankal!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Feline Map',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Bankal, Lapu-Lapu City • ${_activeSightings.length} active',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                const Text(
                  '10m TTL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
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
              initialZoom: 16.0,
              minZoom: 12.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ryme.pokeiring',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.initialCenter,
                    width: 32,
                    height: 32,
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
                  ..._activeSightings.map((sighting) {
                    return Marker(
                      point: LatLng(sighting.latitude, sighting.longitude),
                      width: 52,
                      height: 64,
                      child: CatMarkerAvatar(
                        sighting: sighting,
                        onTap: () =>
                            SightingInspectionSheet.show(context, sighting),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  onPressed: _recenter,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  tooltip: 'Recenter to Bankal',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'drop_pin_btn',
                  onPressed: _dropSimulatedSighting,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text(
                    'Drop Pin',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
