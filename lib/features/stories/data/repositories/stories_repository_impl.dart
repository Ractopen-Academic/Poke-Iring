import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/iring_story.dart';
import '../../domain/repositories/stories_repository.dart';
import '../datasources/firebase_stories_datasource.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  final FirebaseStoriesDataSource _dataSource;

  StoriesRepositoryImpl({FirebaseStoriesDataSource? dataSource})
      : _dataSource = dataSource ?? FirebaseStoriesDataSource();

  @override
  Future<List<IringStory>> getActiveStories() {
    return _dataSource.watchStories().first;
  }

  @override
  Stream<List<IringStory>> watchActiveStories() {
    return _dataSource.watchStories();
  }

  @override
  Future<IringStory> publishStory({
    required AuthUser user,
    required Uint8List compressedImageBytes,
    required String caption,
    required String catBreed,
    required String locationTag,
  }) {
    final now = DateTime.now();
    final story = IringStory(
      id: 'story_${now.millisecondsSinceEpoch}',
      userId: user.id.isNotEmpty ? user.id : user.email,
      authorName: user.displayName.isNotEmpty
          ? user.displayName
          : user.email.split('@').first,
      authorAvatarUrl: user.photoUrl,
      mediaUrl: '',
      caption: caption,
      catBreed: catBreed,
      locationTag: locationTag,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );

    return _dataSource.publishStory(
      story: story,
      compressedBytes: compressedImageBytes,
    );
  }

  @override
  Future<void> markStoryViewed({
    required String storyId,
    required String userId,
  }) {
    return _dataSource.markStoryViewed(storyId, userId);
  }

  @override
  Future<void> boopStory({
    required String storyId,
    required String userId,
  }) {
    return _dataSource.boopStory(storyId, userId);
  }
}
