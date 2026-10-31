import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/vault_photo_entry.dart';
import '../../domain/services/photo_vault_service.dart';

class PhotoVaultServiceImpl implements PhotoVaultService {
  static PhotoVaultServiceImpl? _instance;
  static PhotoVaultServiceImpl get instance =>
      _instance ??= PhotoVaultServiceImpl();

  final Map<String, StreamController<List<VaultPhotoEntry>>> _controllers = {};
  final Map<String, List<VaultPhotoEntry>> _cache = {};

  String _prefKey(String userId) => 'feline_club_raw_vault_$userId';

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
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_prefKey(userId));
      if (rawList != null) {
        final list = rawList.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return VaultPhotoEntry.fromMap(map);
        }).toList();
        _cache.putIfAbsent(userId, () => list);
        return _cache[userId]!;
      }
    } catch (_) {}

    final seed = defaultSeedPhotos(userId);
    _cache.putIfAbsent(userId, () => seed);
    return _cache[userId]!;
  }

  @override
  Future<VaultPhotoEntry> archivePhoto(VaultPhotoEntry photo) async {
    final list = await getVault(photo.userId);
    final updated = [photo, ...list.where((p) => p.id != photo.id)];
    _cache[photo.userId] = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = updated.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_prefKey(photo.userId), rawList);
    } catch (_) {}

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

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = updated.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_prefKey(userId), rawList);
    } catch (_) {}

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(updated);
    }
  }

  @override
  Future<int> getTotalVaultBytes(String userId) async {
    final list = await getVault(userId);
    return list.fold<int>(0, (sum, p) => sum + p.fileSizeBytes);
  }
}
