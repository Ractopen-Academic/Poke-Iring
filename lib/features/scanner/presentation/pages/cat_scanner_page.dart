import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../data/repositories/cat_scanner_repository_impl.dart';
import '../../domain/entities/cat_scan_result.dart';
import '../../domain/entities/cat_sighting.dart';
import '../../domain/repositories/cat_scanner_repository.dart';
import '../widgets/ai_vision_settings_sheet.dart';

class CatScannerPage extends StatefulWidget {
  final AuthUser user;
  final CatScannerRepository? repository;
  final double currentLatitude;
  final double currentLongitude;
  final String currentBarangay;
  final String currentCity;
  final String currentRegion;

  const CatScannerPage({
    super.key,
    required this.user,
    this.repository,
    this.currentLatitude = 10.3140,
    this.currentLongitude = 123.9720,
    this.currentBarangay = 'Bankal',
    this.currentCity = 'Lapu-Lapu City',
    this.currentRegion = 'Central Visayas',
  });

  @override
  State<CatScannerPage> createState() => _CatScannerPageState();
}

class _CatScannerPageState extends State<CatScannerPage> {
  late final CatScannerRepository _repository;
  final ImagePicker _picker = ImagePicker();

  bool _isAnalyzing = false;
  bool _isSaving = false;
  Uint8List? _capturedImageBytes;
  Uint8List? _stickerBytes;
  CatScanResult? _scanResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CatScannerRepositoryImpl();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      await _runAnalysis(bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not read image: $e';
        });
      }
    }
  }

  Future<void> _runAnalysis(Uint8List bytes) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _capturedImageBytes = bytes;
      _scanResult = null;
      _stickerBytes = null;
    });

    try {
      final result = await _repository.scanImage(bytes);
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
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Analysis failed: $e';
        });
      }
    }
  }

  Future<void> _saveSighting() async {
    if (_scanResult == null || _capturedImageBytes == null || _stickerBytes == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sighting = CatSighting(
        id: 'sighting_${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.user.id.isNotEmpty ? widget.user.id : widget.user.email,
        authorName: widget.user.displayName.isNotEmpty
            ? widget.user.displayName
            : (widget.user.email.split('@').first),
        photoUrl: '',
        stickerUrl: '',
        latitude: widget.currentLatitude,
        longitude: widget.currentLongitude,
        geohash: 'w721x',
        barangay: widget.currentBarangay,
        city: widget.currentCity,
        region: widget.currentRegion,
        country: 'Philippines',
        breed: _scanResult!.breed,
        coatPattern: _scanResult!.coatPattern,
        dominantColor: _scanResult!.dominantColor,
        rarityMultiplier: _scanResult!.rarityMultiplier,
        pawPoints: _scanResult!.totalPawPoints,
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
              'Sighting recorded! +${_scanResult!.totalPawPoints} Paw Points registered.',
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
    setState(() {
      _capturedImageBytes = null;
      _stickerBytes = null;
      _scanResult = null;
      _errorMessage = null;
      _isAnalyzing = false;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cat Scanner & Vision',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'AI Vision Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => AiVisionSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildAnalyzingState()
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
            const Text(
              'Gemini Vision Analyzing Feline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detecting breed markings, coat pattern, and generating map sticker...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
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
                const Text(
                  'Spot a Neighborhood Cat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Point your camera at a cat to verify its species, calculate Paw Points, and crop an interactive map pin sticker.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _pickAndAnalyze(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Cat Photo'),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickAndAnalyze(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(50),
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
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(fontSize: 12.5, color: Colors.red.shade800),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Paw Points Scoring Matrix',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildMatrixRow('Base Discovery', '+50 pts'),
                _buildMatrixRow('Pattern Marks (Calico, Tuxedo, Tabby)', '+10 to +40 pts'),
                _buildMatrixRow('Breed Rarity Multiplier', '1.0x to 2.0x'),
                _buildMatrixRow('Community Boop Interaction', '+5 pts per boop'),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
              const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Feline Detected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.rejectionReason ??
                    'Our vision model could not identify a cat. Please frame the cat clearly and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (_stickerBytes != null)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(40),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.memory(
                        _stickerBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  result.breed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    color: Colors.grey.shade700,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paw Points Earned',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMatrixRow('Base Discovery', '+${result.basePoints} pts'),
                _buildMatrixRow('Coat Pattern Bonus', '+${result.patternBonus} pts'),
                _buildMatrixRow('Rarity Multiplier', '${result.rarityMultiplier}x'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Paw Points',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '+${result.totalPawPoints} pts',
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
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Territory: ${widget.currentBarangay}, ${widget.currentCity}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
