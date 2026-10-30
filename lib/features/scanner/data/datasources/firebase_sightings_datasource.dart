import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/cat_sighting.dart';

class FirebaseSightingsDataSource {
  final FirebaseFirestore? firestore;
  final FirebaseStorage? storage;

  // Local fallback storage for web/offline/dev runs
  final List<CatSighting> _localSightings = [];
  final StreamController<List<CatSighting>> _localStreamController =
      StreamController<List<CatSighting>>.broadcast();

  FirebaseSightingsDataSource({
    this.firestore,
    this.storage,
  }) {
    _initLocalSeedData();
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _initLocalSeedData() {
    _localSightings.addAll([
      CatSighting(
        id: 'seed-sighting-1',
        userId: 'dev-user-calico',
        authorName: 'CalicoQueen',
        photoUrl: '',
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
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      CatSighting(
        id: 'seed-sighting-2',
        userId: 'dev-user-ace',
        authorName: 'WhiskersAce',
        photoUrl: '',
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
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      CatSighting(
        id: 'seed-sighting-3',
        userId: 'dev-user-prowler',
        authorName: 'ProwlerSam',
        photoUrl: '',
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
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
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

    // Local fallback
    _localSightings.insert(0, sighting);
    _localStreamController.add(List.unmodifiable(_localSightings));
    return sighting;
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
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            return CatSighting.fromMap(data);
          }).toList();

          if (list.isNotEmpty) return list;
          return List.unmodifiable(_localSightings);
        });
        return;
      } catch (e) {
        debugPrint('Firebase watchNearbySightings error ($e). Streaming local.');
      }
    }

    yield List.unmodifiable(_localSightings);
    yield* _localStreamController.stream;
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
