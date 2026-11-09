import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../subscription/data/services/subscription_service_impl.dart';
import '../../../subscription/presentation/widgets/feline_club_paywall_sheet.dart';
import '../../domain/repositories/stories_repository.dart';

class CreateStoryDialog extends StatefulWidget {
  final AuthUser user;
  final StoriesRepository repository;

  const CreateStoryDialog({
    super.key,
    required this.user,
    required this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    required AuthUser user,
    required StoriesRepository repository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CreateStoryDialog(user: user, repository: repository),
    );
  }

  @override
  State<CreateStoryDialog> createState() => _CreateStoryDialogState();
}

class _CreateStoryDialogState extends State<CreateStoryDialog> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ImageCompressionService _compressionService = ImageCompressionService();

  Uint8List? _compressedBytes;
  ImageCompressionResult? _compressionResult;
  bool _isCompressing = false;
  bool _isPublishing = false;
  bool _isClubMember = false;
  Duration _selectedDuration = const Duration(hours: 24);
  String _selectedBreed = 'Domestic Shorthair (Puspin)';
  final String _locationTag = 'Bankal, Lapu-Lapu City';

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final userId = widget.user.id.isNotEmpty
        ? widget.user.id
        : widget.user.email;
    final status = await SubscriptionServiceImpl.instance.getSubscription(
      userId,
    );
    if (mounted) {
      setState(() {
        _isClubMember = status.isClubMember;
      });
    }
  }

  void _promptClubUpgrade(String featureReason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dynamicSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.dynamicBorder),
        ),
        title: Text(
          'Feline Club Exclusive Perk',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '$featureReason\n\nUpgrade to Feline Club with PayPal to unlock settable durations up to 7 days and uncompressed 4K uploads.',
          style: TextStyle(color: AppColors.dynamicTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: AppColors.dynamicTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final userId = widget.user.id.isNotEmpty
                  ? widget.user.id
                  : widget.user.email;
              FelineClubPaywallSheet.show(
                context,
                userId: userId,
                onSubscribed: () {
                  _checkMembership();
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Membership'),
          ),
        ],
      ),
    );
  }

  String _formatDurationLabel(Duration d) {
    if (d.inDays >= 7) return '7 Days';
    if (d.inDays >= 1) return '${d.inHours} Hours';
    return '${d.inHours}h';
  }

  final List<String> _commonBreeds = const [
    'Domestic Shorthair (Puspin)',
    'Calico Puspin',
    'Orange Tabby',
    'Tuxedo Puspin',
    'Siamese',
    'Persian',
    'Bengal',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) return;

      setState(() => _isCompressing = true);

      final rawBytes = await file.readAsBytes();
      final result = await _compressionService.compressStoryImage(
        rawBytes,
        isClubMember: _isClubMember,
      );

      if (mounted) {
        setState(() {
          _compressionResult = result;
          _compressedBytes = result.compressedBytes;
          _isCompressing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load image: $e')));
      }
    }
  }

  Future<void> _publishStory() async {
    if (_compressedBytes == null) return;

    setState(() => _isPublishing = true);

    try {
      await widget.repository.publishStory(
        user: widget.user,
        compressedImageBytes: _compressedBytes!,
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : 'Feline spotlight in $_locationTag',
        catBreed: _selectedBreed,
        locationTag: _locationTag,
        duration: _selectedDuration,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Story published! Active in highlights for ${_formatDurationLabel(_selectedDuration)}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not publish story: $e')));
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Widget _buildDurationChip({
    required String label,
    required Duration duration,
    required bool isClubOnly,
  }) {
    final isSelected = _selectedDuration == duration;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isClubOnly && !_isClubMember) {
            _promptClubUpgrade('Set your MyDay lifespan to $label.');
            return;
          }
          setState(() => _selectedDuration = duration);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isClubOnly && !_isClubMember)
                ? (AppColors.isCalicoDark
                      ? const Color(0xFF1F1A17)
                      : Colors.grey.shade50)
                : AppColors.dynamicChromeTrack,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isClubOnly && !_isClubMember)
                  ? (AppColors.isCalicoDark
                        ? const Color(0xFF2E241F)
                        : Colors.grey.shade300)
                  : AppColors.dynamicBorder,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isClubOnly && !_isClubMember)
                      ? AppColors.dynamicTextSecondary.withAlpha(160)
                      : AppColors.dynamicTextPrimary,
                ),
              ),
              if (isClubOnly)
                Text(
                  'CLUB',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? Colors.white.withAlpha(220)
                        : (AppColors.isCalicoDark
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFFE65100)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        border: Border(
          top: BorderSide(color: AppColors.dynamicBorder, width: 1.2),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dynamicBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Share Cat Story',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Highlight a cat find to neighborhood explorers for the next 24 hours.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.dynamicTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview or Pick Prompts
            if (_compressedBytes != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.memory(
                          _compressedBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(() {
                                _compressedBytes = null;
                                _compressionResult = null;
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_compressionResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.isCalicoDark
                            ? const Color(0xFF1B3320)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.isCalicoDark
                              ? const Color(0xFF2E5D36)
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 16,
                            color: AppColors.isCalicoDark
                                ? const Color(0xFF81C784)
                                : Colors.green.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Optimized: ${(_compressionResult!.originalSizeBytes / 1024).toStringAsFixed(0)} KB -> ${(_compressionResult!.compressedSizeBytes / 1024).toStringAsFixed(0)} KB (${_compressionResult!.compressionRatio.toStringAsFixed(0)}% lighter)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.isCalicoDark
                                    ? const Color(0xFFA5D6A7)
                                    : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              )
            else if (_isCompressing)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.dynamicChromeTrack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dynamicBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2.5),
                      const SizedBox(height: 12),
                      Text(
                        'Compressing image safely...',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dynamicTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // MyDay Duration Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MyDay Lifespan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
                if (!_isClubMember)
                  GestureDetector(
                    onTap: () => _promptClubUpgrade(
                      'Unlock up to 7 days extended story duration.',
                    ),
                    child: const Text(
                      'Upgrade for 48h - 7d',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDurationChip(
                  label: '24 Hours',
                  duration: const Duration(hours: 24),
                  isClubOnly: false,
                ),
                const SizedBox(width: 6),
                _buildDurationChip(
                  label: '48 Hours',
                  duration: const Duration(hours: 48),
                  isClubOnly: true,
                ),
                const SizedBox(width: 6),
                _buildDurationChip(
                  label: '72 Hours',
                  duration: const Duration(hours: 72),
                  isClubOnly: true,
                ),
                const SizedBox(width: 6),
                _buildDurationChip(
                  label: '7 Days',
                  duration: const Duration(days: 7),
                  isClubOnly: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Resolution status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isClubMember
                    ? (AppColors.isCalicoDark
                          ? const Color(0xFF332617)
                          : const Color(0xFFFFF8E1))
                    : AppColors.dynamicChromeTrack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isClubMember
                      ? (AppColors.isCalicoDark
                            ? const Color(0xFF7A4D1A)
                            : const Color(0xFFFFB300))
                      : AppColors.dynamicBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isClubMember
                        ? Icons.workspace_premium_rounded
                        : Icons.photo_size_select_actual_outlined,
                    size: 15,
                    color: _isClubMember
                        ? (AppColors.isCalicoDark
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFFE65100))
                        : AppColors.dynamicTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isClubMember
                          ? 'Club Ultra HD: 4K 2160p Lossless Master'
                          : 'Standard 1080p Web Compression (Join Club for 4K)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isClubMember
                            ? (AppColors.isCalicoDark
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFE65100))
                            : AppColors.dynamicTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Breed Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedBreed,
              style: TextStyle(
                color: AppColors.dynamicTextPrimary,
                fontSize: 14,
              ),
              dropdownColor: AppColors.dynamicSurface,
              decoration: InputDecoration(
                labelText: 'Cat Breed / Marking',
                labelStyle: TextStyle(color: AppColors.dynamicTextSecondary),
                filled: true,
                fillColor: AppColors.dynamicChromeTrack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.dynamicBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.dynamicBorder),
                ),
              ),
              items: _commonBreeds
                  .map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text(
                        b,
                        style: TextStyle(color: AppColors.dynamicTextPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBreed = val);
              },
            ),

            const SizedBox(height: 12),

            // Caption Field
            TextField(
              controller: _captionController,
              maxLength: 120,
              style: TextStyle(color: AppColors.dynamicTextPrimary),
              decoration: InputDecoration(
                labelText: 'Story Caption',
                labelStyle: TextStyle(color: AppColors.dynamicTextSecondary),
                hintText: 'e.g. Found this fluffy calico napping on a scooter!',
                hintStyle: TextStyle(
                  color: AppColors.dynamicTextSecondary.withAlpha(140),
                ),
                counterStyle: TextStyle(color: AppColors.dynamicTextSecondary),
                filled: true,
                fillColor: AppColors.dynamicChromeTrack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.dynamicBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.dynamicBorder),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Publish Button
            ElevatedButton(
              onPressed: _compressedBytes == null || _isPublishing
                  ? null
                  : _publishStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Share to Neighborhood Stories',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
