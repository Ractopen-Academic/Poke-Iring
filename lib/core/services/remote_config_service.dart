import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigException implements Exception {
  final String message;
  const RemoteConfigException(this.message);

  @override
  String toString() => message;
}

class GlobalAppConfig {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String minAppVersion;
  final String broadcastBanner;
  final bool isBroadcastActive;
  final bool doublePointsGlobal;

  const GlobalAppConfig({
    this.maintenanceMode = false,
    this.maintenanceMessage =
        'Poke: Iring is undergoing scheduled maintenance. Please check back soon.',
    this.minAppVersion = '0.30.0',
    this.broadcastBanner = '',
    this.isBroadcastActive = false,
    this.doublePointsGlobal = false,
  });

  factory GlobalAppConfig.fromMap(Map<String, dynamic> data) {
    return GlobalAppConfig(
      maintenanceMode: data['maintenanceMode'] == true,
      maintenanceMessage:
          (data['maintenanceMessage'] as String?)?.trim().isNotEmpty == true
              ? data['maintenanceMessage'] as String
              : 'Poke: Iring is undergoing scheduled maintenance. Please check back soon.',
      minAppVersion:
          (data['minAppVersion'] as String?)?.trim().isNotEmpty == true
              ? data['minAppVersion'] as String
              : '0.30.0',
      broadcastBanner: (data['broadcastBanner'] as String?) ?? '',
      isBroadcastActive: data['isBroadcastActive'] == true,
      doublePointsGlobal: data['doublePointsGlobal'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'minAppVersion': minAppVersion,
      'broadcastBanner': broadcastBanner,
      'isBroadcastActive': isBroadcastActive,
      'doublePointsGlobal': doublePointsGlobal,
    };
  }
}

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  GlobalAppConfig _config = const GlobalAppConfig();
  bool _hasSuccessfullySynced = false;

  GlobalAppConfig get config => _config;
  bool get hasSuccessfullySynced => _hasSuccessfullySynced;

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Fetches remote configuration online from Firestore.
  /// Strictly online-first: if the network or server fails, throws a
  /// [RemoteConfigException] to indicate a network or server error,
  /// refusing silent mock/offline fallbacks.
  Future<GlobalAppConfig> fetchConfig({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final db = _firestore;
    if (db == null) {
      _config = const GlobalAppConfig();
      _hasSuccessfullySynced = true;
      return _config;
    }

    try {
      final docSnap = await db
          .collection('app_config')
          .doc('global')
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);

      if (!docSnap.exists || docSnap.data() == null) {
        // Document does not exist yet on server; default safe config
        _config = const GlobalAppConfig();
        _hasSuccessfullySynced = true;
        return _config;
      }

      _config = GlobalAppConfig.fromMap(docSnap.data()!);
      _hasSuccessfullySynced = true;
      return _config;
    } catch (e) {
      debugPrint('RemoteConfigService error: $e');
      throw RemoteConfigException(
        'Server or network error: unable to load remote configuration.',
      );
    }
  }

  /// Streams real-time updates from Firestore app_config/global.
  Stream<GlobalAppConfig> streamConfig() {
    final db = _firestore;
    if (db == null) {
      return Stream.value(_config);
    }

    return db
        .collection('app_config')
        .doc('global')
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) {
            return const GlobalAppConfig();
          }
          final newConfig = GlobalAppConfig.fromMap(snap.data()!);
          _config = newConfig;
          return newConfig;
        });
  }

  /// Evaluates whether [currentVersion] meets or exceeds [minVersion].
  /// E.g. "0.33.0" meets "0.30.0" -> true; "0.29.0" meets "0.30.0" -> false.
  static bool isVersionSupported(String currentVersion, String minVersion) {
    try {
      final currentParts = _parseSemVer(currentVersion);
      final minParts = _parseSemVer(minVersion);

      for (var i = 0; i < 3; i++) {
        final cur = currentParts[i];
        final min = minParts[i];
        if (cur > min) return true;
        if (cur < min) return false;
      }
      return true;
    } catch (_) {
      // If unparseable, allow default
      return true;
    }
  }

  static List<int> _parseSemVer(String ver) {
    // Clean any prefix like 'v' or suffixes like '-f41'
    var clean = ver.trim();
    if (clean.startsWith('v')) clean = clean.substring(1);
    final hyphenIndex = clean.indexOf('-');
    if (hyphenIndex != -1) {
      clean = clean.substring(0, hyphenIndex);
    }
    final plusIndex = clean.indexOf('+');
    if (plusIndex != -1) {
      clean = clean.substring(0, plusIndex);
    }

    final parts = clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.take(3).toList();
  }
}
