import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioHapticService with WidgetsBindingObserver {
  AudioHapticService._();
  static final AudioHapticService instance = AudioHapticService._();

  static const String _keyBgmEnabled = 'pokeiring_audio_bgm_enabled';
  static const String _keySfxEnabled = 'pokeiring_audio_sfx_enabled';
  static const String _keyHapticsEnabled = 'pokeiring_audio_haptics_enabled';

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _sfxPlayer;

  bool _isInitialized = false;
  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  bool _hapticsEnabled = true;
  bool _isAppInForeground = true;

  bool get isBgmEnabled => _bgmEnabled;
  bool get isSfxEnabled => _sfxEnabled;
  bool get isHapticsEnabled => _hapticsEnabled;

  bool get _canPlayAudioHaptics {
    try {
      WidgetsBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Initializes persisted toggles and binds app lifecycle listeners.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _bgmEnabled = prefs.getBool(_keyBgmEnabled) ?? true;
      _sfxEnabled = prefs.getBool(_keySfxEnabled) ?? true;
      _hapticsEnabled = prefs.getBool(_keyHapticsEnabled) ?? true;

      try {
        _bgmPlayer = AudioPlayer();
        _sfxPlayer = AudioPlayer();
        await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer?.setVolume(0.35);
      } catch (_) {
        // Ignored in unit testing environments
      }

      try {
        WidgetsBinding.instance.addObserver(this);
      } catch (_) {}

      if (_bgmEnabled) {
        unawaited(_playAmbientBgm());
      }
    } catch (e) {
      debugPrint('AudioHapticService init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      if (_bgmEnabled) {
        try {
          _bgmPlayer?.resume();
        } catch (_) {}
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isAppInForeground = false;
      try {
        _bgmPlayer?.pause();
      } catch (_) {}
    }
  }

  Future<void> _playAmbientBgm() async {
    try {
      await _bgmPlayer?.play(AssetSource('music/bgm_ambient.wav'));
    } catch (e) {
      debugPrint('BGM playback error: $e');
    }
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _bgmEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBgmEnabled, enabled);
    } catch (_) {}

    if (enabled && _isAppInForeground) {
      await _playAmbientBgm();
    } else {
      try {
        await _bgmPlayer?.stop();
      } catch (_) {}
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySfxEnabled, enabled);
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHapticsEnabled, enabled);
    } catch (_) {}
  }

  /// Triggered when explorer captures a camera photo.
  Future<void> snapShutter() async {
    if (!_canPlayAudioHaptics) return;
    if (_hapticsEnabled) {
      try {
        unawaited(HapticFeedback.mediumImpact());
      } catch (_) {}
    }
    if (_sfxEnabled) {
      try {
        unawaited(SystemSound.play(SystemSoundType.click));
      } catch (_) {}
    }
  }

  /// Triggered when tapping a map marker pin or booping a sighting.
  Future<void> boopPin() async {
    if (!_canPlayAudioHaptics) return;
    if (_hapticsEnabled) {
      try {
        unawaited(HapticFeedback.lightImpact());
      } catch (_) {}
    }
    if (_sfxEnabled) {
      try {
        unawaited(SystemSound.play(SystemSoundType.click));
      } catch (_) {}
    }
  }

  /// Triggered when an explorer claims a quest reward.
  Future<void> claimQuest() async {
    if (!_canPlayAudioHaptics) return;
    if (_hapticsEnabled) {
      try {
        unawaited(HapticFeedback.selectionClick());
      } catch (_) {}
    }
    if (_sfxEnabled) {
      try {
        unawaited(SystemSound.play(SystemSoundType.click));
      } catch (_) {}
    }
  }

  /// Triggered when an achievement milestone / tier-up is unlocked.
  Future<void> tierUp() async {
    if (!_canPlayAudioHaptics) return;
    if (_hapticsEnabled) {
      try {
        unawaited(HapticFeedback.heavyImpact());
      } catch (_) {}
    }
    if (_sfxEnabled) {
      try {
        unawaited(SystemSound.play(SystemSoundType.alert));
      } catch (_) {}
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    try {
      _bgmPlayer?.dispose();
      _sfxPlayer?.dispose();
    } catch (_) {}
  }
}
