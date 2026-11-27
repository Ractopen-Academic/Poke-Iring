import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_permission_service.dart';
import '../../../../core/services/audio_haptic_service.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../events/data/repositories/event_repository_impl.dart';
import '../../../events/domain/repositories/event_repository.dart';
import '../../../territory/data/services/territory_service_impl.dart';
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
  double _activeEventMultiplier = 1.0;

  final TextEditingController _customNoteController = TextEditingController();
  final ImageCompressionService _compressionService = ImageCompressionService();
  String? _userChosenBreed;
  String? _userChosenPattern;
  String? _userChosenColor;

  Uint8List? _capturedImageBytes;
  Uint8List? _stickerBytes;
  CatScanResult? _scanResult;
  String? _errorMessage;

  double _lockedLatitude = 10.3140;
  double _lockedLongitude = 123.9720;
  late String _resolvedBarangay;
  late String _resolvedCity;
  late String _resolvedRegion;
  String _resolvedCountry = 'Philippines';

  @override
  void initState() {
    super.initState();
    CalicoThemeController.instance.addListener(_handleThemeChanged);
    _repository = widget.repository ?? CatScannerRepositoryImpl();
    _eventRepository = widget.eventRepository ?? EventRepositoryImpl.instance;
    _locationService = widget.locationService ?? LocationServiceImpl();
    _lockedLatitude = widget.currentLatitude;
    _lockedLongitude = widget.currentLongitude;
    _resolvedBarangay = widget.currentBarangay;
    _resolvedCity = widget.currentCity;
    _resolvedRegion = widget.currentRegion;
    _acquireCurrentLocation();
    _loadResolvedTerritory();
    _refreshEventMultiplier();
    _checkLostImageRecovery();

    if (widget.autoLaunchCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pickImage(ImageSource.camera);
        }
      });
    }
  }

  Future<void> _loadResolvedTerritory() async {
    final userId = widget.user.id.isNotEmpty
        ? widget.user.id
        : widget.user.email;
    try {
      final territory = await TerritoryServiceImpl.instance
          .getTerritory(userId)
          .timeout(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        if (territory.barangay.isNotEmpty) {
          _resolvedBarangay = territory.barangay;
        }
        if (territory.city.isNotEmpty) {
          _resolvedCity = territory.city;
        }
        if (territory.region.isNotEmpty) {
          _resolvedRegion = territory.region;
        }
        if (territory.country.isNotEmpty) {
          _resolvedCountry = territory.country;
        }
      });
    } catch (_) {}
  }

  Future<void> _checkLostImageRecovery() async {
    if (kIsWeb) return;
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return;
      final bytes = await response.file!.readAsBytes();
      if (mounted) {
        setState(() {
          _capturedImageBytes = bytes;
          _isReviewingSnap = true;
          _isAnalyzing = false;
          _showAsyncNotice = false;
          _errorMessage = null;
        });
      }
    } catch (_) {}
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

  double get _globalMultiplier =>
      RemoteConfigService.instance.config.doublePointsGlobal ? 2.0 : 1.0;

  int _effectivePawPoints(CatScanResult result) {
    return (result.totalPawPoints * _activeEventMultiplier * _globalMultiplier)
        .round();
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
    _customNoteController.dispose();
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

  bool _isCameraPermissionDenied = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera && !kIsWeb) {
        const permService = AppPermissionService();
        final status = await permService.checkCamera();
        if (status == AppPermissionState.denied) {
          final requested = await permService.requestCamera();
          if (requested != AppPermissionState.granted) {
            if (mounted) {
              setState(() {
                _isCameraPermissionDenied = true;
                _errorMessage = 'Camera permission is required to spot and record live feline sightings.';
              });
            }
            return;
          }
        } else if (status == AppPermissionState.permanentlyDenied) {
          if (mounted) {
            setState(() {
              _isCameraPermissionDenied = true;
              _errorMessage = 'Camera access is blocked in system settings. Tap "Open Settings" to enable.';
            });
          }
          return;
        }
      }

      if (source == ImageSource.camera) {
        AudioHapticService.instance.snapShutter();
      }
      _acquireCurrentLocation();
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );

      if (file == null) {
        return;
      }

      final rawBytes = await file.readAsBytes();
      Uint8List bytes = rawBytes;
      try {
        final compressed = await _compressionService.compressScannerImage(
          rawBytes,
        );
        if (compressed.compressedBytes.isNotEmpty) {
          bytes = compressed.compressedBytes;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isCameraPermissionDenied = false;
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
          _userChosenBreed = result.breed;
          _userChosenPattern = result.coatPattern;
          _userChosenColor = result.dominantColor;
          if (_customNoteController.text.isEmpty && result.quirk.isNotEmpty) {
            _customNoteController.text = result.quirk;
          }
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
    if (_isSaving ||
        _scanResult == null ||
        _capturedImageBytes == null ||
        _stickerBytes == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _acquireCurrentLocation();

      final userId = widget.user.id.isNotEmpty
          ? widget.user.id
          : widget.user.email;
      String barangay = _resolvedBarangay;
      String city = _resolvedCity;
      String region = _resolvedRegion;
      String country = _resolvedCountry;
      try {
        final territory = await TerritoryServiceImpl.instance
            .getTerritory(userId)
            .timeout(const Duration(seconds: 2));
        if (territory.barangay.isNotEmpty) barangay = territory.barangay;
        if (territory.city.isNotEmpty) city = territory.city;
        if (territory.region.isNotEmpty) region = territory.region;
        if (territory.country.isNotEmpty) country = territory.country;
      } catch (_) {}

      final photoDataUri =
          'data:image/jpeg;base64,${base64Encode(_capturedImageBytes!)}';
      final stickerDataUri =
          'data:image/png;base64,${base64Encode(_stickerBytes!)}';

      final awardedPoints = _effectivePawPoints(_scanResult!);
      final effectiveBreed = _userChosenBreed?.trim().isNotEmpty == true
          ? _userChosenBreed!
          : _scanResult!.breed;
      final effectivePattern = _userChosenPattern?.trim().isNotEmpty == true
          ? _userChosenPattern!
          : _scanResult!.coatPattern;
      final effectiveColor = _userChosenColor?.trim().isNotEmpty == true
          ? _userChosenColor!
          : _scanResult!.dominantColor;
      final note = _customNoteController.text.trim();
      final effectiveQuirk = note.isNotEmpty ? note : _scanResult!.quirk;

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
        barangay: barangay,
        city: city,
        region: region,
        country: country,
        breed: effectiveBreed,
        coatPattern: effectivePattern,
        dominantColor: effectiveColor,
        rarityMultiplier: _scanResult!.rarityMultiplier,
        pawPoints: awardedPoints,
        quirk: effectiveQuirk,
        createdAt: DateTime.now(),
        aiVerified: _scanResult!.isCat,
        aiConfidence: _scanResult!.confidence,
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
    _customNoteController.clear();
    setState(() {
      _capturedImageBytes = null;
      _stickerBytes = null;
      _scanResult = null;
      _errorMessage = null;
      _isAnalyzing = false;
      _isSaving = false;
      _isReviewingSnap = false;
      _showAsyncNotice = false;
      _userChosenBreed = null;
      _userChosenPattern = null;
      _userChosenColor = null;
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
          IconButton(
            tooltip: 'AI Vision Engine Settings',
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
                  color: AppColors.dynamicSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(110),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Verifying Feline Encounter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gemini Vision is inspecting coat markings and generating your custom Iring sticker. Keep this screen open to review and save.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dynamicTextSecondary,
                        height: 1.4,
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
                      'Encounter Ready for Verification',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text(
                  'Gallery',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 360,
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
                Image.memory(
                  _capturedImageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                const CameraViewfinderReticle(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
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
                  label: const Text('Verify & Identify Cat'),
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
                  'Snap a cat photo or upload one from your gallery to verify its breed, calculate Paw Points, and pin it to the map.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.dynamicTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
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
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 19),
                  label: const Text('Upload from Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dynamicTextPrimary,
                    side: BorderSide(color: AppColors.dynamicBorder),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                color: Colors.red.withAlpha(AppColors.isCalicoLight ? 24 : 40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade400.withAlpha(140)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.isCalicoLight
                          ? Colors.red.shade900
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                  if (_isCameraPermissionDenied && !kIsWeb) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.isCalicoLight
                            ? Colors.red.shade900
                            : const Color(0xFFFCA5A5),
                        backgroundColor: AppColors.dynamicSurface.withAlpha(90),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () => const AppPermissionService()
                          .openAppSettingsIfNeeded(),
                      icon: const Icon(Icons.settings_rounded, size: 16),
                      label: const Text(
                        'Open App Settings to Grant Camera Access',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
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
      final reason =
          result.rejectionReason ??
          'Our vision model could not identify a cat. Please frame the cat clearly and try again.';
      final lowerReason = reason.toLowerCase();
      final isConfigError =
          lowerReason.contains('key') ||
          lowerReason.contains('proxy') ||
          lowerReason.contains('404') ||
          lowerReason.contains('unavailable');
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
                isConfigError ? 'AI Vision Needs Setup' : 'No Feline Detected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.dynamicTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
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
                  if (isConfigError)
                    OutlinedButton.icon(
                      onPressed: () => AiVisionSettingsSheet.show(context),
                      icon: const Icon(Icons.tune_rounded, size: 17),
                      label: const Text('AI Vision Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dynamicTextPrimary,
                        side: BorderSide(color: AppColors.dynamicBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(28),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.green.withAlpha(90)),
                  ),
                  child: Text(
                    'Verified Cat • ${(result.confidence * 100).round()}% Confidence',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Breed: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                    Flexible(
                      child: Builder(
                        builder: (context) {
                          final rawBreed = (_userChosenBreed ?? result.breed)
                              .trim();
                          final breedOptions = <String>[
                            ...CatScanResult.canonicalBreeds,
                          ];
                          if (rawBreed.isNotEmpty &&
                              rawBreed != 'Unknown' &&
                              !breedOptions.contains(rawBreed)) {
                            breedOptions.insert(0, rawBreed);
                          }
                          final safeBreed = breedOptions.contains(rawBreed)
                              ? rawBreed
                              : 'Uncategorized';
                          return DropdownButton<String>(
                            isExpanded: false,
                            value: safeBreed,
                            dropdownColor: AppColors.dynamicSurface,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dynamicTextPrimary,
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _userChosenBreed = val);
                              }
                            },
                            items: breedOptions
                                .map(
                                  (breed) => DropdownMenuItem(
                                    value: breed,
                                    child: Text(
                                      breed,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(
                        AppColors.isCalicoLight ? 24 : 40,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.shade400.withAlpha(140),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.isCalicoLight
                            ? Colors.red.shade900
                            : const Color(0xFFFCA5A5),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Builder(
                    builder: (context) {
                      final rawPattern =
                          (_userChosenPattern ?? result.coatPattern).trim();
                      final patternOptions = <String>[
                        ...CatScanResult.canonicalCoatPatterns,
                      ];
                      if (rawPattern.isNotEmpty &&
                          !patternOptions.contains(rawPattern)) {
                        patternOptions.insert(0, rawPattern);
                      }
                      final safePattern = patternOptions.contains(rawPattern)
                          ? rawPattern
                          : patternOptions.first;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pattern: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          DropdownButton<String>(
                            value: safePattern,
                            isDense: true,
                            dropdownColor: AppColors.dynamicSurface,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _userChosenPattern = val);
                              }
                            },
                            items: patternOptions
                                .map(
                                  (pattern) => DropdownMenuItem(
                                    value: pattern,
                                    child: Text(pattern),
                                  ),
                                )
                                .toList(),
                          ),
                          Flexible(
                            child: Text(
                              ' • ${_userChosenColor ?? result.dominantColor}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customNoteController,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.dynamicTextPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Explorer Note / Nickname',
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.dynamicTextSecondary,
                    ),
                    hintText: 'Record a field note about this cat...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.dynamicTextSecondary.withAlpha(120),
                    ),
                    filled: true,
                    fillColor: AppColors.dynamicFieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.dynamicBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.dynamicBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                if (_globalMultiplier > 1.0)
                  _buildMatrixRow('Global Double Points', '2x'),
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
                    'Territory: $_resolvedBarangay, $_resolvedCity',
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
