import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/iring_story.dart';

class FirebaseStoriesDataSource {
  final FirebaseFirestore? firestore;
  final FirebaseStorage? storage;

  final List<IringStory> _localStories = [];
  final StreamController<List<IringStory>> _streamController =
      StreamController<List<IringStory>>.broadcast();

  FirebaseStoriesDataSource({this.firestore, this.storage}) {
    _initLocalSeedStories();
  }

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _initLocalSeedStories() {
    final now = DateTime.now();
    _localStories.addAll([
      IringStory(
        id: 'seed-story-1',
        userId: 'dev-user-calico',
        authorName: 'CalicoQueen',
        authorAvatarUrl: '',
        mediaUrl: '',
        caption:
            'Spotted this gorgeous calico perched on a sari-sari store awning!',
        catBreed: 'Calico (Puspin)',
        locationTag: 'Bankal, Lapu-Lapu City',
        boopsCount: 18,
        boopedBy: const ['dev-user-ace'],
        viewedBy: const [],
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
      ),
      IringStory(
        id: 'seed-story-2',
        userId: 'dev-user-ace',
        authorName: 'WhiskersAce',
        authorAvatarUrl: '',
        mediaUrl: '',
        caption:
            'Orange tabby taking an epic midday loaf on a warm tricycle seat.',
        catBreed: 'Orange Tabby (Puspin)',
        locationTag: 'Basak, Lapu-Lapu City',
        boopsCount: 24,
        boopedBy: const [],
        viewedBy: const [],
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(hours: 19)),
      ),
      IringStory(
        id: 'seed-story-3',
        userId: 'dev-user-prowler',
        authorName: 'ProwlerSam',
        authorAvatarUrl: '',
        mediaUrl: '',
        caption: 'Tuxedo guardian patrolling near the barangay sports complex.',
        catBreed: 'Tuxedo Puspin',
        locationTag: 'Pajac, Lapu-Lapu City',
        boopsCount: 11,
        boopedBy: const [],
        viewedBy: const [],
        createdAt: now.subtract(const Duration(hours: 8)),
        expiresAt: now.add(const Duration(hours: 16)),
      ),
      IringStory(
        id: 'seed-story-4',
        userId: 'dev-user-tabby',
        authorName: 'TabbyTracker',
        authorAvatarUrl: '',
        mediaUrl: '',
        caption: 'Sleepy eyes greeting morning walkers along the acacia shade.',
        catBreed: 'Brown Tabby',
        locationTag: 'Punta Engaño, Lapu-Lapu City',
        boopsCount: 32,
        boopedBy: const [],
        viewedBy: const [],
        createdAt: now.subtract(const Duration(hours: 11)),
        expiresAt: now.add(const Duration(hours: 13)),
      ),
    ]);
  }

  Future<IringStory> publishStory({
    required IringStory story,
    required Uint8List compressedBytes,
  }) async {
    if (_isFirebaseAvailable) {
      try {
        final st = storage ?? FirebaseStorage.instance;
        final db = firestore ?? FirebaseFirestore.instance;

        final photoRef = st.ref().child(
          'stories/${story.userId}/${story.id}.jpg',
        );
        await photoRef.putData(
          compressedBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final downloadUrl = await photoRef.getDownloadURL();

        final persisted = story.copyWith(mediaUrl: downloadUrl);

        await db.collection('stories').doc(story.id).set({
          ...persisted.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(persisted.expiresAt),
        });

        return persisted;
      } catch (e) {
        debugPrint('Firebase publishStory failed ($e). Saving locally.');
      }
    }

    _localStories.insert(0, story);
    _streamController.add(List.unmodifiable(_localStories));
    return story;
  }

  Stream<List<IringStory>> watchStories() async* {
    if (_isFirebaseAvailable) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        yield* db
            .collection('stories')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('expiresAt', descending: true)
            .limit(30)
            .snapshots()
            .map((snap) {
              final list = snap.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return IringStory.fromMap(data);
              }).toList();

              if (list.isNotEmpty) return list;
              return List.unmodifiable(_localStories);
            });
        return;
      } catch (e) {
        debugPrint('Firebase watchStories failed ($e). Streaming local.');
      }
    }

    yield List.unmodifiable(_localStories);
    yield* _streamController.stream;
  }

  Future<void> markStoryViewed(String storyId, String userId) async {
    if (_isFirebaseAvailable) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        await db.collection('stories').doc(storyId).update({
          'viewedBy': FieldValue.arrayUnion([userId]),
        });
        return;
      } catch (e) {
        debugPrint('Firebase markStoryViewed error: $e');
      }
    }

    final index = _localStories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final s = _localStories[index];
      if (!s.viewedBy.contains(userId)) {
        final updatedViewed = List<String>.from(s.viewedBy)..add(userId);
        _localStories[index] = s.copyWith(viewedBy: updatedViewed);
        _streamController.add(List.unmodifiable(_localStories));
      }
    }
  }

  Future<void> boopStory(String storyId, String userId) async {
    if (_isFirebaseAvailable) {
      try {
        final db = firestore ?? FirebaseFirestore.instance;
        await db.collection('stories').doc(storyId).update({
          'boopsCount': FieldValue.increment(1),
          'boopedBy': FieldValue.arrayUnion([userId]),
        });
        return;
      } catch (e) {
        debugPrint('Firebase boopStory error: $e');
      }
    }

    final index = _localStories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final s = _localStories[index];
      if (!s.boopedBy.contains(userId)) {
        final updatedBooped = List<String>.from(s.boopedBy)..add(userId);
        _localStories[index] = s.copyWith(
          boopsCount: s.boopsCount + 1,
          boopedBy: updatedBooped,
        );
        _streamController.add(List.unmodifiable(_localStories));
      }
    }
  }
}
