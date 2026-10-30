import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiConfigService {
  static const String _geminiApiKeyPref = 'gemini_api_key_user_pref';
  static const String _compileTimeKey = String.fromEnvironment('GEMINI_API_KEY');

  static final AiConfigService instance = AiConfigService._internal();
  AiConfigService._internal();

  String? _cachedKey;
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedKey = prefs.getString(_geminiApiKeyPref);
      _isLoaded = true;
    } catch (e) {
      debugPrint('AiConfigService init failed: $e');
    }
  }

  Future<String?> getApiKey() async {
    if (!_isLoaded) {
      await init();
    }

    if (_cachedKey != null && _cachedKey!.trim().isNotEmpty) {
      return _cachedKey!.trim();
    }

    if (_compileTimeKey.trim().isNotEmpty) {
      return _compileTimeKey.trim();
    }

    return null;
  }

  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    _cachedKey = trimmed;
    _isLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (trimmed.isEmpty) {
        await prefs.remove(_geminiApiKeyPref);
      } else {
        await prefs.setString(_geminiApiKeyPref, trimmed);
      }
    } catch (e) {
      debugPrint('Failed to persist Gemini API key: $e');
    }
  }

  Future<void> clearApiKey() async {
    await setApiKey('');
  }

  bool get hasKeySynchronous {
    if (_cachedKey != null && _cachedKey!.trim().isNotEmpty) return true;
    return _compileTimeKey.trim().isNotEmpty;
  }

  String get maskedKey {
    final key = _cachedKey?.trim() ?? _compileTimeKey.trim();
    if (key.isEmpty) return 'Not configured (Mock active)';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }
}
