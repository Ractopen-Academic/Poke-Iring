import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pokeiring/core/services/image_compression_service.dart';
import 'package:pokeiring/core/widgets/feline_avatar.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/stories/data/datasources/firebase_stories_datasource.dart';
import 'package:pokeiring/features/stories/data/repositories/stories_repository_impl.dart';
import 'package:pokeiring/features/stories/domain/entities/iring_story.dart';
import 'package:pokeiring/features/stories/presentation/widgets/stories_tray.dart';
import 'package:pokeiring/features/stories/presentation/widgets/story_circle_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCompressionService', () {
    test('compresses image bytes and restricts dimension bounds', () async {
      // Create a 2000x2000 large test image
      final testImg = img.Image(width: 2000, height: 2000);
      img.fill(testImg, color: img.ColorRgb8(240, 100, 30));
      final rawBytes = Uint8List.fromList(img.encodeJpg(testImg, quality: 100));

      final service = ImageCompressionService();
      final result = await service.compressStoryImage(rawBytes);

      expect(result.compressedBytes, isNotEmpty);
      expect(result.width, lessThanOrEqualTo(ImageCompressionService.maxStoryWidth));
      expect(result.height, lessThanOrEqualTo(ImageCompressionService.maxStoryHeight));
      expect(result.compressedSizeBytes, lessThan(result.originalSizeBytes));
    });
  });

  group('IringStory Entity', () {
    test('evaluates view, boop, and expiration states accurately', () {
      final now = DateTime.now();
      final activeStory = IringStory(
        id: 'story-test-1',
        userId: 'author-123',
        authorName: 'CalicoQueen',
        mediaUrl: '',
        caption: 'Testing story entity',
        catBreed: 'Calico Puspin',
        locationTag: 'Bankal, Lapu-Lapu City',
        boopsCount: 5,
        boopedBy: const ['user-a'],
        viewedBy: const ['user-b'],
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(hours: 23)),
      );

      expect(activeStory.isViewedBy('user-b'), isTrue);
      expect(activeStory.isViewedBy('user-c'), isFalse);
      expect(activeStory.isBoopedBy('user-a'), isTrue);
      expect(activeStory.isBoopedBy('user-c'), isFalse);
      expect(activeStory.isExpired, isFalse);

      final expiredStory = activeStory.copyWith(
        expiresAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(expiredStory.isExpired, isTrue);
    });
  });

  group('FirebaseStoriesDataSource', () {
    test('loads seed stories, records view, and registers community boop', () async {
      final dataSource = FirebaseStoriesDataSource();

      final stories = await dataSource.watchStories().first;
      expect(stories, isNotEmpty);
      expect(stories.any((s) => s.authorName == 'CalicoQueen'), isTrue);

      final target = stories.first;
      final initialBoops = target.boopsCount;

      await dataSource.boopStory(target.id, 'user-booper-99');
      await dataSource.markStoryViewed(target.id, 'user-viewer-88');

      final updated = await dataSource.watchStories().first;
      final updatedTarget = updated.firstWhere((s) => s.id == target.id);

      expect(updatedTarget.boopsCount, equals(initialBoops + 1));
      expect(updatedTarget.boopedBy, contains('user-booper-99'));
      expect(updatedTarget.viewedBy, contains('user-viewer-88'));
    });
  });

  group('FelineAvatar Widget', () {
    testWidgets('renders default stylized feline avatar from seed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FelineAvatar(
              seed: 'test.explorer',
              radius: 30,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FelineAvatar), findsOneWidget);
    });
  });

  group('StoriesTray Widget', () {
    testWidgets('renders Your Story add button and community story circles', (tester) async {
      const mockUser = AuthUser(
        id: 'test-explorer-id',
        email: 'explorer@pokeiring.test',
        displayName: 'WhiskersAce',
        photoUrl: '',
        emailVerified: true,
      );

      final repository = StoriesRepositoryImpl(
        dataSource: FirebaseStoriesDataSource(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoriesTray(
              user: mockUser,
              repository: repository,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Story'), findsOneWidget);
      expect(find.byType(StoryCircleItem), findsWidgets);
      expect(find.text('CalicoQueen'), findsOneWidget);
    });
  });
}
