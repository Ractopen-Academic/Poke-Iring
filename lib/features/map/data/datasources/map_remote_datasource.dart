import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/live_sighting.dart';

abstract class MapRemoteDatasource {
  Stream<List<LiveSighting>> getActiveSightingsStream();
  Future<void> dropSighting(LiveSighting sighting);
}

class FirestoreMapDatasource implements MapRemoteDatasource {
  final FirebaseFirestore _firestore;

  FirestoreMapDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<LiveSighting>> getActiveSightingsStream() {
    return _firestore
        .collection('live_sightings')
        .where(
          'expiresAt',
          isGreaterThanOrEqualTo: Timestamp.now().toDate().toIso8601String(),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LiveSighting.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> dropSighting(LiveSighting sighting) async {
    await _firestore
        .collection('live_sightings')
        .doc(sighting.id)
        .set(sighting.toMap());
  }
}

class DevMapDatasource implements MapRemoteDatasource {
  static const double bankalLat = 10.3140;
  static const double bankalLng = 123.9720;

  final List<LiveSighting> _sightings = [];
  final StreamController<List<LiveSighting>> _controller =
      StreamController<List<LiveSighting>>.broadcast();

  DevMapDatasource() {
    _seedBankalSightings();
  }

  void _seedBankalSightings() {
    final now = DateTime.now();
    _sightings.addAll([
      LiveSighting(
        id: 'cat_bankal_01',
        latitude: bankalLat + 0.0015,
        longitude: bankalLng + 0.0015,
        breed: 'Puspin Tabby',
        rarity: 'Common',
        confidence: 0.95,
        createdAt: now.subtract(const Duration(minutes: 2)),
        expiresAt: now.add(const Duration(minutes: 8)),
      ),
      LiveSighting(
        id: 'cat_bankal_02',
        latitude: bankalLat - 0.0012,
        longitude: bankalLng - 0.0015,
        breed: 'Calico Shorthair',
        rarity: 'Rare',
        confidence: 0.91,
        createdAt: now.subtract(const Duration(minutes: 4)),
        expiresAt: now.add(const Duration(minutes: 6)),
      ),
      LiveSighting(
        id: 'cat_bankal_03',
        latitude: bankalLat + 0.0008,
        longitude: bankalLng - 0.0018,
        breed: 'Siamese Cross',
        rarity: 'Mythic',
        confidence: 0.88,
        createdAt: now.subtract(const Duration(minutes: 6)),
        expiresAt: now.add(const Duration(minutes: 4)),
      ),
    ]);
  }

  @override
  Stream<List<LiveSighting>> getActiveSightingsStream() async* {
    yield _activeSightings;
    yield* _controller.stream;
  }

  List<LiveSighting> get _activeSightings {
    return _sightings.where((s) => !s.isExpired).toList();
  }

  @override
  Future<void> dropSighting(LiveSighting sighting) async {
    _sightings.removeWhere((s) => s.id == sighting.id);
    _sightings.insert(0, sighting);
    _controller.add(_activeSightings);
  }

  void dispose() {
    _controller.close();
  }
}
