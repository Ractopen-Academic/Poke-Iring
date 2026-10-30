import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../../core/widgets/feline_status_banner.dart';
import '../../../scanner/data/repositories/cat_scanner_repository_impl.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../../scanner/domain/repositories/cat_scanner_repository.dart';
import '../../../scanner/presentation/widgets/cat_sighting_detail_sheet.dart';
import '../../data/datasources/cached_tile_provider.dart';
import '../../domain/entities/user_location.dart';
import '../widgets/cute_paw_compass_pointer.dart';
import '../widgets/peeking_cat_recenter_button.dart';

class LiveMapPage extends StatefulWidget {
  final LatLng initialCenter;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;
  final VoidCallback? onClose;
  final VoidCallback? onTileError;
  final LocationService? locationService;
  final CatScannerRepository? scannerRepository;
  final String currentUserId;
  final bool isMapActive;

  const LiveMapPage({
    super.key,
    this.initialCenter = const LatLng(10.3140, 123.9720),
    this.onPointerDown,
    this.onPointerUp,
    this.onClose,
    this.onTileError,
    this.locationService,
    this.scannerRepository,
    this.currentUserId = 'default-explorer',
    this.isMapActive = true,
  });

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _rotationController;
  late final AnimationController _moveController;
  late final TileProvider _tileProvider;
  late final LocationService _locationService;
  late final CatScannerRepository _scannerRepository;
  StreamSubscription<UserLocation>? _locationSubscription;
  StreamSubscription<List<CatSighting>>? _sightingsSubscription;
  List<CatSighting> _nearbySightings = const [];
  UserLocation? _currentUserLocation;
  bool _hasCenteredOnUser = false;

  final ValueNotifier<double> _rotationNotifier = ValueNotifier<double>(0.0);
  bool _hasTileError = false;
  bool _isControlsVisible = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _tileProvider = CachedTileProvider();
    _locationService = widget.locationService ?? LocationServiceImpl();
    _scannerRepository = widget.scannerRepository ?? CatScannerRepositoryImpl();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    if (widget.isMapActive) {
      _initLocation();
      _initSightings();
    }
  }

  void _initSightings() {
    _sightingsSubscription?.cancel();
    _sightingsSubscription = _scannerRepository
        .watchNearbySightings(
          latitude: widget.initialCenter.latitude,
          longitude: widget.initialCenter.longitude,
        )
        .listen((sightings) {
          if (mounted) {
            setState(() {
              _nearbySightings = sightings;
            });
          }
        });
  }

  @override
  void didUpdateWidget(covariant LiveMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMapActive != oldWidget.isMapActive) {
      if (widget.isMapActive) {
        _initLocation();
        _initSightings();
      } else {
        _pauseLocation();
        _sightingsSubscription?.cancel();
      }
    }
  }

  Future<void> _initLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (location != null) {
      setState(() {
        _currentUserLocation = location;
      });
      if (!_hasCenteredOnUser) {
        _hasCenteredOnUser = true;
        _mapController.move(
          LatLng(location.latitude, location.longitude),
          _mapController.camera.zoom,
        );
      }
    }

    _subscribeToLocation();
  }

  void _subscribeToLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.onLocationChanged.listen((loc) {
      if (!mounted) return;
      final wasNull = _currentUserLocation == null;
      setState(() {
        _currentUserLocation = loc;
      });
      if (wasNull && !_hasCenteredOnUser) {
        _hasCenteredOnUser = true;
        _mapController.move(
          LatLng(loc.latitude, loc.longitude),
          _mapController.camera.zoom,
        );
      }
    });
  }

  void _pauseLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  void dispose() {
    _pauseLocation();
    _sightingsSubscription?.cancel();
    _controlsTimer?.cancel();
    _rotationNotifier.dispose();
    _rotationController.dispose();
    _moveController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onPointerDown() {
    _controlsTimer?.cancel();
    if (_isControlsVisible) {
      setState(() {
        _isControlsVisible = false;
      });
    }
    widget.onPointerDown?.call();
  }

  void _onPointerUp() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted && !_isControlsVisible) {
        setState(() {
          _isControlsVisible = true;
        });
      }
    });
    widget.onPointerUp?.call();
  }

  void _recenter() {
    if (_moveController.isAnimating) return;

    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final targetCenter = _currentUserLocation != null
        ? LatLng(
            _currentUserLocation!.latitude,
            _currentUserLocation!.longitude,
          )
        : widget.initialCenter;
    const targetZoom = 16.0;

    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: targetCenter.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: targetCenter.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: targetZoom);

    final anim = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutCubic,
    );

    void listener() {
      _mapController.move(
        LatLng(latTween.evaluate(anim), lngTween.evaluate(anim)),
        zoomTween.evaluate(anim),
      );
    }

    anim.addListener(listener);
    _moveController.forward(from: 0.0).then((_) {
      anim.removeListener(listener);
    });

    if (_currentUserLocation == null) {
      _initLocation();
    }
  }

  void _resetToNorth() {
    if (_rotationController.isAnimating) return;

    var start = _rotationNotifier.value % 360;
    if (start > 180) start -= 360;
    if (start < -180) start += 360;

    if (start.abs() < 0.5) return;

    final anim = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOutCubic),
    );

    void listener() {
      _mapController.rotate(anim.value);
      _rotationNotifier.value = anim.value;
    }

    anim.addListener(listener);
    _rotationController.forward(from: 0.0).then((_) {
      anim.removeListener(listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = _currentUserLocation != null
        ? LatLng(
            _currentUserLocation!.latitude,
            _currentUserLocation!.longitude,
          )
        : widget.initialCenter;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Listener(
            onPointerDown: (_) => _onPointerDown(),
            onPointerUp: (_) => _onPointerUp(),
            onPointerCancel: (_) => _onPointerUp(),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: activeLocation,
                initialZoom: 16.0,
                minZoom: 12.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPositionChanged: (camera, hasGesture) {
                  if (_rotationNotifier.value != camera.rotation) {
                    _rotationNotifier.value = camera.rotation;
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.ryme.pokeiring',
                  tileProvider: _tileProvider,
                  panBuffer: 1,
                  keepBuffer: 2,
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
                    ..._nearbySightings.map((sighting) {
                      return Marker(
                        point: LatLng(sighting.latitude, sighting.longitude),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () {
                            CatSightingDetailSheet.show(
                              context: context,
                              sighting: sighting,
                              currentUserId: widget.currentUserId,
                              onBoop: () => _scannerRepository.boopSighting(
                                sightingId: sighting.id,
                                userId: widget.currentUserId,
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(child: _buildMarkerIcon(sighting)),
                          ),
                        ),
                      );
                    }),
                    Marker(
                      point: activeLocation,
                      width: 44,
                      height: 44,
                      child: _UserLocationMarker(
                        heading: _currentUserLocation?.heading,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentUserLocation != null
                              ? '${_currentUserLocation!.latitude.toStringAsFixed(4)}, ${_currentUserLocation!.longitude.toStringAsFixed(4)}'
                              : 'Bankal, Lapu-Lapu City',
                          style: const TextStyle(
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
                        padding: const EdgeInsets.all(8),
                        child: ValueListenableBuilder<double>(
                          valueListenable: _rotationNotifier,
                          builder: (context, rotation, child) {
                            return Transform.rotate(
                              angle: -rotation * (math.pi / 180),
                              child: child,
                            );
                          },
                          child: const RepaintBoundary(
                            child: CutePawCompassPointer(size: 28),
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
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              offset: _isControlsVisible ? Offset.zero : const Offset(2.0, 0),
              child: PeekingCatRecenterButton(onTap: _recenter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerIcon(CatSighting sighting) {
    final imageUri = sighting.stickerUrl.isNotEmpty
        ? sighting.stickerUrl
        : sighting.photoUrl;

    if (imageUri.isNotEmpty) {
      if (imageUri.startsWith('data:image')) {
        try {
          final b64 = imageUri.contains(',')
              ? imageUri.split(',').last
              : imageUri;
          return Image.memory(
            base64Decode(b64),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.pets, size: 20, color: AppColors.primary),
          );
        } catch (_) {}
      } else {
        return CachedNetworkImage(
          imageUrl: imageUri,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
              const Icon(Icons.pets, size: 20, color: AppColors.primary),
        );
      }
    }

    return const Icon(Icons.pets, size: 20, color: AppColors.primary);
  }
}

class _UserLocationMarker extends StatefulWidget {
  final double? heading;

  const _UserLocationMarker({this.heading});

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasHeading = widget.heading != null && widget.heading! >= 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 22 + (18 * _pulseController.value),
              height: 22 + (18 * _pulseController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(
                  ((1.0 - _pulseController.value) * 65).round(),
                ),
              ),
            );
          },
        ),
        if (hasHeading)
          Transform.rotate(
            angle: widget.heading! * (math.pi / 180),
            child: SizedBox(
              width: 44,
              height: 44,
              child: CustomPaint(painter: _HeadingBeamPainter()),
            ),
          ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(45),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 13,
              height: 13,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeadingBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 - (math.pi / 6),
        math.pi / 3,
        false,
      )
      ..close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withAlpha(110),
          AppColors.primary.withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
