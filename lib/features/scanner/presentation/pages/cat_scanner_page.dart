import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_haptic_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../events/data/repositories/event_repository_impl.dart';
import '../../../events/domain/repositories/event_repository.dart';
import '../../data/repositories/cat_scanner_repository_impl.dart';
import '../../domain/entities/cat_scan_result.dart';
import '../../domain/entities/cat_sighting.dart';
import '../../domain/repositories/cat_scanner_repository.dart';
import '../widgets/ai_vision_settings_sheet.dart';
import '../widgets/camera_viewfinder_reticle.dart';
import '../widgets/paw_points_guide_sheet.dart';

class CatScannerPage extends StatefulWidget {
  final AuthUser user;
  final CatScannerRepository? repository;
  final EventRepository? eventRepository;
  final LocationService? locationService;
  final double currentLatitude;
  final double currentLongitude;
  final String currentBarangay;
  final String currentCity;
  final String currentRegion;
  final bool autoLaunchCamera;

  const CatScannerPage({
    super.key,
    required this.user,
    this.repository,
    this.eventRepository,
    this.locationService,
    this.currentLatitude = 10.3140,
    this.currentLongitude = 123.9720,
    this.currentBarangay = 'Bankal',
    this.currentCity = 'Lapu-Lapu City',
    this.currentRegion = 'Central Visayas',
    this.autoLaunchCamera = false,
  });

  @override
  State<CatScannerPage> createState() => _CatScannerPageState();
}

class _CatScannerPageState extends State<CatScannerPage> {
  late final CatScannerRepository _repository;
  late final EventRepository _eventRepository;
  late final LocationService _locationService;
  final ImagePicker _picker = ImagePicker();

  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isReviewingSnap = false;
  bool _showAsyncNotice = false;
  Timer? _asyncNoticeTimer;
  String _selectedFilter = 'normal';
  String _selectedZoom = '1x';
  double _activeEventMultiplier = 1.0;

  Uint8List? _capturedImageBytes;
  Uint8List? _stickerBytes;
  CatScanResult? _scanResult;
  String? _errorMessage;

  double _lockedLatitude = 10.3140;
  double _lockedLongitude = 123.9720;

  @override
  void initState() {
    super.initState();
    CalicoThemeController.instance.addListener(_handleThemeChanged);
    _repository = widget.repository ?? CatScannerRepositoryImpl();
    _eventRepository = widget.eventRepository ?? EventRepositoryImpl.instance;
    _locationService = widget.locationService ?? LocationServiceImpl();
    _lockedLatitude = widget.currentLatitude;
    _lockedLongitude = widget.currentLongitude;
    _acquireCurrentLocation();
    _refreshEventMultiplier();

    if (widget.autoLaunchCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pickAndAnalyze();
        }
      });
    }
  }

  void _handleThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshEventMultiplier() async {
    try {
      final multiplier = await _eventRepository.getActiveMultiplier();
      if (mounted) {
        setState(() {
          _activeEventMultiplier = multiplier;
        });
      }
    } catch (_) {}
  }

  int _effectivePawPoints(CatScanResult result) {
    return (result.totalPawPoints * _activeEventMultiplier).round();
  }

  String _formatMultiplier(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}x';
    }
    return '${value.toStringAsFixed(1)}x';
  }

  @override
  void dispose() {
    CalicoThemeController.instance.removeListener(_handleThemeChanged);
    _asyncNoticeTimer?.cancel();
    super.dispose();
  }

  Future<void> _acquireCurrentLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null && mounted) {
        setState(() {
          _lockedLatitude = loc.latitude;
          _lockedLongitude = loc.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAndAnalyze() async {
    try {
      AudioHapticService.instance.snapShutter();
      _acquireCurrentLocation();
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _capturedImageBytes = bytes;
        _isReviewingSnap = true;
        _isAnalyzing = false;
        _showAsyncNotice = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not capture encounter: $e';
        });
      }
    }
  }

  Future<void> _runAnalysis(Uint8List bytes) async {
    _asyncNoticeTimer?.cancel();
    _showAsyncNotice = false;

    setState(() {
      _isAnalyzing = true;
      _isReviewingSnap = false;
      _errorMessage = null;
      _capturedImageBytes = bytes;
      _scanResult = null;
      _stickerBytes = null;
    });

    _asyncNoticeTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && _isAnalyzing) {
        setState(() {
          _showAsyncNotice = true;
        });
      }
    });

    try {
      await _refreshEventMultiplier();
      final result = await _repository.scanImage(bytes);
      _asyncNoticeTimer?.cancel();

      if (!result.isCat) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _scanResult = result;
          });
        }
        return;
      }

      final sticker = await _repository.generateStickerCutout(
        imageBytes: bytes,
        scanResult: result,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _scanResult = result;
          _stickerBytes = sticker;
        });
      }
    } catch (e) {
      _asyncNoticeTimer?.cancel();
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Analysis failed: $e';
        });
      }
    }
  }

  Future<void> _saveSighting() async {
    if (_scanResult == null ||
        _capturedImageBytes == null ||
        _stickerBytes == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _acquireCurrentLocation();

      final photoDataUri =
          'data:image/jpeg;base64,${base64Encode(_capturedImageBytes!)}';
      final stickerDataUri =
          'data:image/png;base64,${base64Encode(_stickerBytes!)}';

      final awardedPoints = _effectivePawPoints(_scanResult!);

      final sighting = CatSighting(
        id: 'sighting_${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.user.id.isNotEmpty ? widget.user.id : widget.user.email,
        authorName: widget.user.displayName.isNotEmpty
            ? widget.user.displayName
            : (widget.user.email.split('@').first),
        photoUrl: photoDataUri,
        stickerUrl: stickerDataUri,
        latitude: _lockedLatitude,
        longitude: _lockedLongitude,
        geohash: 'w721x',
        barangay: widget.currentBarangay,
        city: widget.currentCity,
        region: widget.currentRegion,
        country: 'Philippines',
        breed: _scanResult!.breed,
        coatPattern: _scanResult!.coatPattern,
        dominantColor: _scanResult!.dominantColor,
        rarityMultiplier: _scanResult!.rarityMultiplier,
        pawPoints: awardedPoints,
        quirk: _scanResult!.quirk,
        createdAt: DateTime.now(),
      );

      await _repository.saveSighting(
        sighting: sighting,
        originalBytes: _capturedImageBytes!,
        stickerBytes: _stickerBytes!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Spawned on map! +$awardedPoints Paw Points registered.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to persist sighting: $e';
        });
      }
    }
  }

  void _reset() {
    _asyncNoticeTimer?.cancel();
    setState(() {
      _capturedImageBytes = null;
      _stickerBytes = null;
      _scanResult = null;
      _errorMessage = null;
      _isAnalyzing = false;
      _isSaving = false;
      _isReviewingSnap = false;
      _showAsyncNotice = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          'Cat Scanner & Vision',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Points Calculation Guide',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => PawPointsGuideSheet.show(context),
          ),
          if (widget.user.isAdmin)
            IconButton(
              tooltip: 'AI Vision Engine (Admin)',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => AiVisionSettingsSheet.show(context),
            ),
        ],
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildAnalyzingState()
            : _isReviewingSnap && _capturedImageBytes != null
            ? _buildSnapReviewState()
            : _scanResult != null
            ? _buildResultView()
            : _buildCapturePrompt(),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gemini Vision Analyzing Feline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detecting breed markings, coat pattern, and generating map sticker...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.dynamicTextSecondary,
                height: 1.4,
              ),
            ),
            if (_showAsyncNotice) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: Color(0xFFE65100),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Background Cataloging Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your scanned cat is being processed and cataloged into your Album & Iring-Dex. You can keep exploring or wait here for live sticker generation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue Exploring Territory',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSnapReviewState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                  color: AppColors.dynamicSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dynamicBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Encounter Captured',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _zoomChip('1x'),
                  const SizedBox(width: 4),
                  _zoomChip('2x'),
                  const SizedBox(width: 4),
                  _zoomChip('3x'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 380,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _applyFilterToImage(_capturedImageBytes!),
                const CameraViewfinderReticle(),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Filter: ${_selectedFilter.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterButton('Natural', 'normal', Icons.lens_blur),
                const SizedBox(width: 8),
                _filterButton('Warm Sun', 'warm', Icons.wb_sunny_outlined),
                const SizedBox(width: 8),
                _filterButton('Vivid Sun', 'vivid', Icons.filter_hdr_outlined),
                const SizedBox(width: 8),
                _filterButton('Mono Night', 'mono', Icons.nights_stay_outlined),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: _pickAndAnalyze,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dynamicTextPrimary,
                    side: BorderSide(
                      color: AppColors.dynamicBorder,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _runAnalysis(_capturedImageBytes!),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Analyze Cat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zoomChip(String zoom) {
    final isSelected = _selectedZoom == zoom;
    return GestureDetector(
      onTap: () => setState(() => _selectedZoom = zoom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.dynamicSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dynamicBorder,
          ),
        ),
        child: Text(
          zoom,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.dynamicTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String label, String filterKey, IconData icon) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.dynamicSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dynamicBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.dynamicTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.dynamicTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applyFilterToImage(Uint8List bytes) {
    Widget image = Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    switch (_selectedFilter) {
      case 'warm':
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1.1,
            0.0,
            0.0,
            0.0,
            15.0,
            0.0,
            1.0,
            0.0,
            0.0,
            8.0,
            0.0,
            0.0,
            0.9,
            0.0,
            -10.0,
            0.0,
            0.0,
            0.0,
            1.0,
            0.0,
          ]),
          child: image,
        );
      case 'vivid':
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            1.2,
            0.0,
            0.0,
            0.0,
            -10.0,
            0.0,
            1.2,
            0.0,
            0.0,
            -10.0,
            0.0,
            0.0,
            1.2,
            0.0,
            -10.0,
            0.0,
            0.0,
            0.0,
            1.0,
            0.0,
          ]),
          child: image,
        );
      case 'mono':
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0.0,
            0.0,
            0.2126,
            0.7152,
            0.0722,
            0.0,
            0.0,
            0.2126,
            0.7152,
            0.0722,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            1.0,
            0.0,
          ]),
          child: image,
        );
      case 'normal':
      default:
        return image;
    }
  }

  Widget _buildCapturePrompt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Spot a Neighborhood Cat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Point your camera at a cat to verify its species, calculate Paw Points, and crop an interactive map pin sticker.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.dynamicTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _pickAndAnalyze,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Snap Real-Time Cat Encounter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade400.withAlpha(120)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFFCA5A5),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Paw Points Scoring Matrix',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildMatrixRow('Base Discovery', '+50 pts'),
                _buildMatrixRow(
                  'Pattern Marks (Calico, Tuxedo, Tabby)',
                  '+10 to +40 pts',
                ),
                _buildMatrixRow('Breed Rarity Multiplier', '1.0x to 2.0x'),
                _buildMatrixRow(
                  'Community Boop Interaction',
                  '+5 pts per boop',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.dynamicTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.dynamicTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = _scanResult!;

    if (!result.isCat) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No Feline Detected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.rejectionReason ?? 'Our vision model could not identify a cat. Please frame the cat clearly and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.dynamicTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticker Cutout Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Column(
              children: [
                if (_stickerBytes != null)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.dynamicSurface,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(40),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.memory(_stickerBytes!, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  result.breed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Pattern: ${result.coatPattern} • ${result.dominantColor}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"${result.quirk}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.dynamicTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Score Breakdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dynamicSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paw Points Earned',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMatrixRow('Base Discovery', '+${result.basePoints} pts'),
                _buildMatrixRow(
                  'Coat Pattern Bonus',
                  '+${result.patternBonus} pts',
                ),
                _buildMatrixRow(
                  'Rarity Multiplier',
                  '${result.rarityMultiplier}x',
                ),
                if (_activeEventMultiplier > 1.0)
                  _buildMatrixRow(
                    'Active Event Bonus',
                    _formatMultiplier(_activeEventMultiplier),
                  ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Paw Points',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                    Text(
                      '+${_effectivePawPoints(result)} pts',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Location badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.dynamicFieldFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Territory: ${widget.currentBarangay}, ${widget.currentCity}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dynamicTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSighting,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Register to Iring-Dex & Pin on Map',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isSaving ? null : _reset,
            child: const Text('Retake Photo'),
          ),
        ],
      ),
    );
  }
}
