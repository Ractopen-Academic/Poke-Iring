import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central service responsible for wiping test and development artifacts,
/// clearing persistent caches, and putting the app into a clean deployment baseline.
class DataPurgeService {
  static const String _keyPurgeActive = 'sys_deployment_clean_slate_active';
  static const String _keyDisableTestSeeds = 'sys_disable_test_seeds';

  static bool _seedsDisabledInMemory = false;

  /// Whether mock seed items (sightings, stories, vault photos) should be blocked.
  static bool get areSeedsDisabled => _seedsDisabledInMemory || kReleaseMode;

  @visibleForTesting
  static void setSeedsDisabledForTesting(bool disabled) {
    _seedsDisabledInMemory = disabled;
  }

  /// Initialize state from persistent storage.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seedsDisabledInMemory = prefs.getBool(_keyDisableTestSeeds) ?? true;
    } catch (_) {
      _seedsDisabledInMemory = true;
    }
  }

  /// Purge all local persistent caches, test data, and optionally disable mock seeds.
  static Future<DataPurgeReport> purgeAllTestDataAndCache({
    bool disableTestSeeds = true,
  }) async {
    int clearedKeysCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // Collect test and caching keys to delete
      final keysToRemove = <String>[];
      for (final key in allKeys) {
        // Retain critical authentication credentials if any, but clear test caches
        if (key.startsWith('scanner_sightings_') ||
            key.startsWith('stories_') ||
            key.startsWith('raw_photo_vault_') ||
            key.startsWith('events_cache_') ||
            key.startsWith('territories_cache_') ||
            key.startsWith('quest_cache_') ||
            key.startsWith('explorer_health_') ||
            key.startsWith('subscription_status_') ||
            key.startsWith('offline_queue_') ||
            key.startsWith('pokeiring_leaderboard_') ||
            key.startsWith('leaderboard_') ||
            key == 'quick_snap_last_position_v1') {
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        await prefs.remove(key);
        clearedKeysCount++;
      }

      if (disableTestSeeds) {
        await prefs.setBool(_keyDisableTestSeeds, true);
        await prefs.setBool(_keyPurgeActive, true);
        _seedsDisabledInMemory = true;
      }
    } catch (e) {
      debugPrint('Error during data purge: $e');
    }

    return DataPurgeReport(
      clearedKeysCount: clearedKeysCount,
      testSeedsDisabled: _seedsDisabledInMemory,
      purgedAt: DateTime.now(),
    );
  }

  /// Restore mock seeds for development testing.
  static Future<void> restoreTestSeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDisableTestSeeds);
      await prefs.remove(_keyPurgeActive);
      _seedsDisabledInMemory = false;
    } catch (_) {}
  }
}

class DataPurgeReport {
  final int clearedKeysCount;
  final bool testSeedsDisabled;
  final DateTime purgedAt;

  const DataPurgeReport({
    required this.clearedKeysCount,
    required this.testSeedsDisabled,
    required this.purgedAt,
  });
}
