import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/ai_config_service.dart';

class AiVisionSettingsSheet extends StatefulWidget {
  const AiVisionSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiVisionSettingsSheet(),
    );
  }

  @override
  State<AiVisionSettingsSheet> createState() => _AiVisionSettingsSheetState();
}

class _AiVisionSettingsSheetState extends State<AiVisionSettingsSheet> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final key = await AiConfigService.instance.getApiKey();
    if (mounted) {
      setState(() {
        if (key != null && key.isNotEmpty) {
          _keyController.text = key;
          _currentStatus = 'Configured (${AiConfigService.instance.maskedKey})';
        } else {
          _currentStatus = 'No key set (Smart mock active)';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    setState(() => _isSaving = true);
    await AiConfigService.instance.setApiKey(key);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _currentStatus = key.isNotEmpty
          ? 'Configured (${AiConfigService.instance.maskedKey})'
          : 'No key set (Smart mock active)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          key.isNotEmpty
              ? 'Gemini API key saved to device.'
              : 'Key removed. Smart mock vision activated.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _clearKey() async {
    setState(() {
      _keyController.clear();
      _isSaving = true;
    });
    await AiConfigService.instance.clearApiKey();
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _currentStatus = 'No key set (Smart mock active)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cleared API key. Switched to smart mock vision.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                Icon(Icons.psychology_outlined, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text(
                  'AI Vision Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your personal Gemini API key for cat recognition and silhouette cutout. The key remains stored only on this device.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Status: $_currentStatus',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              TextField(
                controller: _keyController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _clearKey,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Use Mock Mode'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Key',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Get your key at aistudio.google.com/app/apikey',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
