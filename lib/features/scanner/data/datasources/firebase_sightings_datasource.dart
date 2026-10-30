import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cat_sighting.dart';

class FirebaseSightingsDataSource {
  static final FirebaseSightingsDataSource _instance =
      FirebaseSightingsDataSource._internal();

  final FirebaseFirestore? firestore;
  final FirebaseStorage? storage;

  // Local fallback storage for web/offline/dev runs
  final List<CatSighting> _localSightings = [];
  final StreamController<List<CatSighting>> _localStreamController =
      StreamController<List<CatSighting>>.broadcast();

  static const String _prefSightingsKey = 'pokeiring_user_spawned_sightings';

  factory FirebaseSightingsDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) {
    if (firestore != null || storage != null) {
      return FirebaseSightingsDataSource._internal(
        firestore: firestore,
        storage: storage,
      );
    }
    return _instance;
  }

  FirebaseSightingsDataSource._internal({this.firestore, this.storage}) {
    _initLocalSeedData();
    _loadPersistedSightings();
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _initLocalSeedData() {
    final now = DateTime.now();
    _localSightings.addAll([
      CatSighting(
        id: 'seed-sighting-1',
        userId: 'dev-user-calico',
        authorName: 'CalicoQueen',
        photoUrl: 'https://images.unsplash.com/photo-1548247416-ec66f4900b2e?w=600&auto=format&fit=crop&q=80',
        stickerUrl: '',
        latitude: 10.3155,
        longitude: 123.9730,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Calico (Puspin)',
        coatPattern: 'Calico',
        dominantColor: 'Orange, Black & White',
        rarityMultiplier: 1.4,
        pawPoints: 120,
        quirk: 'Perched high on a wooden sari-sari store awning.',
        boopsCount: 14,
        boopedBy: const ['dev-user-ace'],
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      CatSighting(
        id: 'seed-sighting-2',
        userId: 'dev-user-ace',
        authorName: 'WhiskersAce',
        photoUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600&auto=format&fit=crop&q=80',
        stickerUrl: '',
        latitude: 10.3128,
        longitude: 123.9705,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Domestic Shorthair (Puspin)',
        coatPattern: 'Orange Tabby',
        dominantColor: 'Ginger Tabby',
        rarityMultiplier: 1.2,
        pawPoints: 85,
        quirk: 'Loafing beside a sleeping tricycle puppy.',
        boopsCount: 9,
        boopedBy: const [],
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      CatSighting(
        id: 'seed-sighting-3',
        userId: 'dev-user-prowler',
        authorName: 'ProwlerSam',
        photoUrl: 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=600&auto=format&fit=crop&q=80',
        stickerUrl: '',
        latitude: 10.3170,
        longitude: 123.9750,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Tuxedo Puspin',
        coatPattern: 'Tuxedo',
        dominantColor: 'Black & White',
        rarityMultiplier: 1.3,
        pawPoints: 95,
        quirk: 'Stretching paws in the warm morning sun.',
        boopsCount: 6,
        boopedBy: const [],
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      CatSighting(
        id: 'seed-sighting-4',
        userId: 'dev-user-tabby',
        authorName: 'TabbyTracker',
        photoUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600&auto=format&fit=crop&q=80',
        stickerUrl: '',
        latitude: 10.3142,
        longitude: 123.9718,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Domestic Shorthair (Puspin)',
        coatPattern: 'Tabby',
        dominantColor: 'Classic Brown Tabby',
        rarityMultiplier: 1.1,
        pawPoints: 75,
        quirk:
            'Observing passersby with keen golden eyes from an acacia shade.',
        boopsCount: 11,
        boopedBy: const [],
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      CatSighting(
        id: 'seed-sighting-5',
        userId: 'dev-user-tortie',
        authorName: 'TortieScout',
        photoUrl: 'https://images.unsplash.com/photo-1561948955-570b270e7c36?w=600&auto=format&fit=crop&q=80',
        stickerUrl: '',
        latitude: 10.3160,
        longitude: 123.9762,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Puspin Tortoiseshell',
        coatPattern: 'Tortoiseshell',
        dominantColor: 'Amber & Charcoal',
        rarityMultiplier: 1.3,
        pawPoints: 115,
        quirk: 'Sneaking behind blooming bougainvillea pots.',
        boopsCount: 16,
        boopedBy: const [],
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      CatSighting(
        id: 'seed-sighting-6',
        userId: 'dev-user-siamese',
        authorName: 'SiameseSeeker',
        photoUrl: 'https://images.unsplash.com/photo-1513245543132-31f507417b26?w=600&auto=format&fit=crop&q=80',
        stickerUrl: '',
        latitude: 10.3185,
        longitude: 123.9780,
        geohash: 'w721x',
        barangay: 'Bankal',
        city: 'Lapu-Lapu City',
        region: 'Central Visayas',
        country: 'Philippines',
        breed: 'Siamese',
        coatPattern: 'Colorpoint',
        dominantColor: 'Seal Point',
        rarityMultiplier: 1.6,
        pawPoints: 155,
        quirk: 'Perched serenely on a tiled garden patio fence.',
        boopsCount: 28,
        boopedBy: const [],
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      ),
    ]);
  }

  Future<CatSighting> saveSighting({
    required CatSighting sighting,
    required Uint8List originalBytes,
    required Uint8List stickerBytes,
  }) async {
    if (_isFirebaseAvailable) {
      try {
        final st = storage ?? FirebaseStorage.instance;
        final db = firestore ?? FirebaseFirestore.instance;

        // 1. Upload original photo
        final photoRef = st.ref().child(
          'sightings/${sighting.userId}/${sighting.id}_full.jpg',
        );
        await photoRef.putData(
          originalBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final photoUrl = await photoRef.getDownloadURL();

        // 2. Upload sticker cutout
        final stickerRef = st.ref().child(
          'sightings/${sighting.userId}/${sighting.id}_sticker.png',
        );
        await stickerRef.putData(
          stickerBytes,
          SettableMetadata(contentType: 'image/png'),
        );
        final stickerUrl = await stickerRef.getDownloadURL();

        final persistedSighting = sighting.copyWith(
          photoUrl: photoUrl,
          stickerUrl: stickerUrl,
        );

        // 3. Save sighting document in Firestore
        await db.collection('sightings').doc(sighting.id).set({
          ...persistedSighting.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'location': GeoPoint(sighting.latitude, sighting.longitude),
        });

        // 4. Atomically increment player totals in users collection
        await db.collection('users').doc(sighting.userId).set({
          'totalPawPoints': FieldValue.increment(sighting.pawPoints),
          'totalSnaps': FieldValue.increment(1),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return persistedSighting;
      } catch (e) {
        debugPrint('Firebase saveSighting error ($e). Saving locally.');
      }
    }

    // Local update & live spawn broadcast
    _localSightings.removeWhere((s) => s.id == sighting.id);
    _localSightings.insert(0, sighting);
    unawaited(_persistSightings());
    _localStreamController.add(List.unmodifiable(_localSightings));
    return sighting;
  }

  Future<void> _loadPersistedSightings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_prefSightingsKey);
      if (rawList != null && rawList.isNotEmpty) {
        final loaded = rawList.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return CatSighting.fromMap(map);
        }).toList();

        for (final item in loaded.reversed) {
          if (!_localSightings.any((s) => s.id == item.id)) {
            _localSightings.insert(0, item);
          }
        }
        _localStreamController.add(List.unmodifiable(_localSightings));
      }
    } catch (e) {
      debugPrint('Error loading persisted sightings: $e');
    }
  }

  Future<void> _persistSightings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userSightings = _localSightings
          .where((s) => !s.id.startsWith('seed-'))
          .toList();
      final rawList = userSightings.map((s) => jsonEncode(s.toMap())).toList();
      await prefs.setStringList(_prefSightingsKey, rawList);
    } catch (e) {
      debugPrint('Error persisting user sightings: $e');
    }
  }

  Stream<List<CatSighting>> watchNearbySightings({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async* {
    if (_isFirebaseAvailable) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        yield* db
            .collection('sightings')
            .orderBy('createdAt', descending: true)
            .limit(40)
            .snapshots()
            .map((snapshot) {
              final list = snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                if (data['createdAt'] is Timestamp) {
                  data['createdAt'] = (data['createdAt'] as Timestamp)
                      .toDate()
                      .toIso8601String();
                }
                return CatSighting.fromMap(data);
              }).toList();

              if (list.isNotEmpty) return list;
              return List.unmodifiable(_localSightings);
            });
        return;
      } catch (e) {
        debugPrint(
          'Firebase watchNearbySightings error ($e). Streaming local.',
        );
      }
    }

    yield List.unmodifiable(_localSightings);
    yield* _localStreamController.stream;
  }

  Stream<List<CatSighting>> watchSightingsByUser(String userId) async* {
    if (_isFirebaseAvailable) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        yield* db
            .collection('sightings')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
              final list = snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                if (data['createdAt'] is Timestamp) {
                  data['createdAt'] = (data['createdAt'] as Timestamp)
                      .toDate()
                      .toIso8601String();
                }
                return CatSighting.fromMap(data);
              }).toList();

              if (list.isNotEmpty) return list;
              return _filterLocalByUser(userId);
            });
        return;
      } catch (e) {
        debugPrint(
          'Firebase watchSightingsByUser error ($e). Streaming local.',
        );
      }
    }

    yield _filterLocalByUser(userId);
    yield* _localStreamController.stream.map((_) => _filterLocalByUser(userId));
  }

  List<CatSighting> _filterLocalByUser(String userId) {
    final userSightings = _localSightings
        .where((s) => s.userId == userId)
        .toList();
    if (userSightings.isNotEmpty) {
      return List.unmodifiable(userSightings);
    }
    return List.unmodifiable(_localSightings);
  }

  Future<void> boopSighting({
    required String sightingId,
    required String userId,
  }) async {
    if (_isFirebaseAvailable) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        final docRef = db.collection('sightings').doc(sightingId);
        final doc = await docRef.get();
        if (doc.exists) {
          final authorId = doc.data()?['userId']?.toString();
          await docRef.update({
            'boopsCount': FieldValue.increment(1),
            'boopedBy': FieldValue.arrayUnion([userId]),
          });

          // Award +5 community points to author
          if (authorId != null && authorId.isNotEmpty) {
            await db.collection('users').doc(authorId).set({
              'totalPawPoints': FieldValue.increment(5),
            }, SetOptions(merge: true));
          }
          return;
        }
      } catch (e) {
        debugPrint('Firebase boopSighting error ($e). Applying locally.');
      }
    }

    // Local update
    final index = _localSightings.indexWhere((s) => s.id == sightingId);
    if (index != -1) {
      final s = _localSightings[index];
      if (!s.boopedBy.contains(userId)) {
        final updatedBooped = List<String>.from(s.boopedBy)..add(userId);
        _localSightings[index] = s.copyWith(
          boopsCount: s.boopsCount + 1,
          boopedBy: updatedBooped,
        );
        _localStreamController.add(List.unmodifiable(_localSightings));
      }
    }
  }
}
