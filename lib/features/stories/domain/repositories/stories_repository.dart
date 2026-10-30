import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../entities/iring_story.dart';

abstract class StoriesRepository {
  Future<List<IringStory>> getActiveStories();

  Stream<List<IringStory>> watchActiveStories();

  Future<IringStory> publishStory({
    required AuthUser user,
    required Uint8List compressedImageBytes,
    required String caption,
    required String catBreed,
    required String locationTag,
  });

  Future<void> markStoryViewed({
    required String storyId,
    required String userId,
  });

  Future<void> boopStory({required String storyId, required String userId});
}
