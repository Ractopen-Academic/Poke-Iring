import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase Configuration & Rules Contract', () {
    test('firebase.json exists and links rules and indexes', () {
      final file = File('firebase.json');
      expect(file.existsSync(), isTrue);

      final content =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(content['firestore'], isNotNull);
      expect(content['firestore']['rules'], equals('firestore.rules'));
      expect(content['firestore']['indexes'], equals('firestore.indexes.json'));
      expect(content['storage'], isNotNull);
      expect(content['storage']['rules'], equals('storage.rules'));
    });

    test(
      'firestore.indexes.json is valid and contains sightings composite index',
      () {
        final file = File('firestore.indexes.json');
        expect(file.existsSync(), isTrue);

        final content =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final indexes = content['indexes'] as List<dynamic>;
        expect(indexes, isNotEmpty);

        final sightingsIndex = indexes.firstWhere(
          (idx) => idx['collectionGroup'] == 'sightings',
          orElse: () => null,
        );
        expect(sightingsIndex, isNotNull);
        final fields = sightingsIndex['fields'] as List<dynamic>;
        expect(fields.any((f) => f['fieldPath'] == 'userId'), isTrue);
        expect(fields.any((f) => f['fieldPath'] == 'createdAt'), isTrue);
      },
    );

    test(
      'firestore.rules covers all core domain collections and subcollections',
      () {
        final file = File('firestore.rules');
        expect(file.existsSync(), isTrue);

        final text = file.readAsStringSync();
        expect(text.contains("rules_version = '2';"), isTrue);
        expect(text.contains('service cloud.firestore'), isTrue);

        // Helper functions
        expect(text.contains('function isAuthenticated()'), isTrue);
        expect(text.contains('function isOwner('), isTrue);
        expect(text.contains('function isBoopUpdate()'), isTrue);
        expect(text.contains('function isPointsIncrement()'), isTrue);

        // Collections
        expect(text.contains('match /users/{userId}'), isTrue);
        expect(text.contains('match /vault_photos/{photoId}'), isTrue);
        expect(text.contains('match /event_wallets/{walletId}'), isTrue);
        expect(text.contains('match /sightings/{sightingId}'), isTrue);
        expect(text.contains('match /stories/{storyId}'), isTrue);
        expect(text.contains('match /live_sightings/{docId}'), isTrue);
        expect(text.contains('match /dex_species/{speciesId}'), isTrue);
        expect(text.contains('match /territories/{territoryId}'), isTrue);
        expect(text.contains('match /events/{eventId}'), isTrue);
        expect(text.contains('match /quest_pool/{questId}'), isTrue);
        expect(text.contains('match /achievement_tracks/{trackId}'), isTrue);
        expect(text.contains('match /seasons/{seasonId}'), isTrue);
      },
    );

    test('storage.rules covers all media upload targets with size limits', () {
      final file = File('storage.rules');
      expect(file.existsSync(), isTrue);

      final text = file.readAsStringSync();
      expect(text.contains("rules_version = '2';"), isTrue);
      expect(text.contains('service firebase.storage'), isTrue);

      // Storage targets
      expect(text.contains('match /sightings/{userId}/{fileName}'), isTrue);
      expect(text.contains('match /stories/{userId}/{fileName}'), isTrue);
      expect(text.contains('match /vault/{userId}/{fileName}'), isTrue);
      expect(text.contains('match /users/{userId}/{fileName}'), isTrue);

      // Constraints
      expect(text.contains('15 * 1024 * 1024'), isTrue);
      expect(text.contains('30 * 1024 * 1024'), isTrue);
      expect(
        text.contains("request.resource.contentType.matches('image/.*')"),
        isTrue,
      );
    });
  });
}
