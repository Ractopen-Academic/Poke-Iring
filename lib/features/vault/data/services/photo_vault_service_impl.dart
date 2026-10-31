import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/vault_photo_entry.dart';
import '../../domain/services/photo_vault_service.dart';

class PhotoVaultServiceImpl implements PhotoVaultService {
  static PhotoVaultServiceImpl? _instance;
  static PhotoVaultServiceImpl get instance =>
      _instance ??= PhotoVaultServiceImpl();

  final FirebaseFirestore? firestore;

  final Map<String, StreamController<List<VaultPhotoEntry>>> _controllers = {};
  final Map<String, List<VaultPhotoEntry>> _cache = {};

  String _prefKey(String userId) => 'feline_club_raw_vault_$userId';

  PhotoVaultServiceImpl({this.firestore});

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  static List<VaultPhotoEntry> defaultSeedPhotos(String userId) {
    final now = DateTime.now();
    return [
      VaultPhotoEntry(
        id: 'vault_seed_1',
        userId: userId,
        sightingId: 'sighting_seed_1',
        breedName: 'Pusapin Ginger Tabby',
        photoUrl: '',
        fileSizeBytes: 5033164, // ~4.8 MB
        resolutionWidth: 4032,
        resolutionHeight: 3024,
        capturedAt: now.subtract(const Duration(hours: 4)),
        isRawMaster: true,
        iso: 80,
        shutterSpeed: '1/400s',
        aperture: 'f/1.8',
        locationLabel: 'Bankal, Lapu-Lapu City',
      ),
      VaultPhotoEntry(
        id: 'vault_seed_2',
        userId: userId,
        sightingId: 'sighting_seed_2',
        breedName: 'Philippine Calico',
        photoUrl: '',
        fileSizeBytes: 5662310, // ~5.4 MB
        resolutionWidth: 3840,
        resolutionHeight: 2880,
        capturedAt: now.subtract(const Duration(days: 1, hours: 2)),
        isRawMaster: true,
        iso: 125,
        shutterSpeed: '1/250s',
        aperture: 'f/1.8',
        locationLabel: 'Basak, Lapu-Lapu City',
      ),
      VaultPhotoEntry(
        id: 'vault_seed_3',
        userId: userId,
        sightingId: 'sighting_seed_3',
        breedName: 'Siamese Cross',
        photoUrl: '',
        fileSizeBytes: 6396313, // ~6.1 MB
        resolutionWidth: 4032,
        resolutionHeight: 3024,
        capturedAt: now.subtract(const Duration(days: 2, hours: 6)),
        isRawMaster: true,
        iso: 100,
        shutterSpeed: '1/320s',
        aperture: 'f/2.0',
        locationLabel: 'Lahug, Cebu City',
      ),
    ];
  }

  @override
  Stream<List<VaultPhotoEntry>> watchVault(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<List<VaultPhotoEntry>>.broadcast(
        onListen: () {
          getVault(userId).then((list) {
            if (_controllers[userId]?.isClosed == false) {
              _controllers[userId]?.add(list);
            }
          });
        },
      );
    }
    return _controllers[userId]!.stream;
  }

  @override
  Future<List<VaultPhotoEntry>> getVault(String userId) async {
    // 1. Online-First: Try fetching latest photos from Cloud Firestore
    if (_isFirebaseAvailable) {
      try {
        final snapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('vault_photos')
            .get()
            .timeout(const Duration(milliseconds: 1500));

        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return VaultPhotoEntry.fromMap(data);
          }).toList();

          _cache[userId] = list;
          unawaited(_persistLocally(userId, list));
          return list;
        }
      } catch (e) {
        debugPrint(
          'Firestore fetch vault photos error ($e). Using local cache.',
        );
      }
    }

    // 2. In-Memory Cache
    if (_cache.containsKey(userId) && _cache[userId]!.isNotEmpty) {
      return _cache[userId]!;
    }

    // 3. Persistent Local Cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final rawList = prefs.getStringList(_prefKey(userId));
      if (rawList != null && rawList.isNotEmpty) {
        final list = rawList.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return VaultPhotoEntry.fromMap(map);
        }).toList();
        _cache[userId] = list;
        return list;
      }
    } catch (_) {}

    // 4. Built-in Seed Fallback (Clean install offline)
    final seed = defaultSeedPhotos(userId);
    _cache[userId] = seed;
    return seed;
  }

  @override
  Future<VaultPhotoEntry> archivePhoto(VaultPhotoEntry photo) async {
    final list = await getVault(photo.userId);
    final updated = [photo, ...list.where((p) => p.id != photo.id)];
    _cache[photo.userId] = updated;

    unawaited(_persistLocally(photo.userId, updated));
    unawaited(_syncPhotoToCloud(photo));

    if (_controllers[photo.userId]?.isClosed == false) {
      _controllers[photo.userId]?.add(updated);
    }

    return photo;
  }

  @override
  Future<void> removePhoto(String userId, String photoId) async {
    final list = await getVault(userId);
    final updated = list.where((p) => p.id != photoId).toList();
    _cache[userId] = updated;

    unawaited(_persistLocally(userId, updated));
    unawaited(_removePhotoFromCloud(userId, photoId));

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(updated);
    }
  }

  @override
  Future<int> getTotalVaultBytes(String userId) async {
    final list = await getVault(userId);
    return list.fold<int>(0, (total, p) => total + p.fileSizeBytes);
  }

  Future<void> _persistLocally(
    String userId,
    List<VaultPhotoEntry> photos,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final rawList = photos.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_prefKey(userId), rawList);
    } catch (_) {}
  }

  Future<void> _syncPhotoToCloud(VaultPhotoEntry photo) async {
    if (!_isFirebaseAvailable) return;

    try {
      await _db
          .collection('users')
          .doc(photo.userId)
          .collection('vault_photos')
          .doc(photo.id)
          .set(photo.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync vault photo error: $e');
    }
  }

  Future<void> _removePhotoFromCloud(String userId, String photoId) async {
    if (!_isFirebaseAvailable) return;

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('vault_photos')
          .doc(photoId)
          .delete();
    } catch (e) {
      debugPrint('Firestore delete vault photo error: $e');
    }
  }

  @visibleForTesting
  void resetCache() {
    _cache.clear();
  }
}
