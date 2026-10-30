import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../../auth/domain/entities/auth_user.dart';
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
  String _selectedBreed = 'Domestic Shorthair (Puspin)';
  final String _locationTag = 'Bankal, Lapu-Lapu City';

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
      final result = await _compressionService.compressStoryImage(rawBytes);

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
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Story published! Live in neighborhood highlights for 24 hours.',
              style: TextStyle(fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Share Cat Story',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Highlight a cat find to neighborhood explorers for the next 24 hours.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
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
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 16,
                            color: Colors.green.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Optimized: ${(_compressionResult!.originalSizeBytes / 1024).toStringAsFixed(0)} KB -> ${(_compressionResult!.compressedSizeBytes / 1024).toStringAsFixed(0)} KB (${_compressionResult!.compressionRatio.toStringAsFixed(0)}% lighter)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade900,
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5),
                      SizedBox(height: 12),
                      Text(
                        'Compressing image safely...',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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

            // Breed Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedBreed,
              decoration: InputDecoration(
                labelText: 'Cat Breed / Marking',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _commonBreeds
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
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
              decoration: InputDecoration(
                labelText: 'Story Caption',
                hintText: 'e.g. Found this fluffy calico napping on a scooter!',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
