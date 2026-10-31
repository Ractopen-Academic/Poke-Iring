import 'package:flutter/material.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../data/repositories/stories_repository_impl.dart';
import '../../domain/entities/iring_story.dart';
import '../../domain/repositories/stories_repository.dart';
import '../pages/story_viewer_page.dart';
import 'create_story_dialog.dart';
import 'story_circle_item.dart';

class StoriesTray extends StatefulWidget {
  final AuthUser user;
  final StoriesRepository? repository;

  const StoriesTray({super.key, required this.user, this.repository});

  @override
  State<StoriesTray> createState() => _StoriesTrayState();
}

class _StoriesTrayState extends State<StoriesTray> {
  late final StoriesRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StoriesRepositoryImpl();
  }

  void _openCreateStory() {
    CreateStoryDialog.show(context, user: widget.user, repository: _repository);
  }

  void _openStoryViewer(List<IringStory> stories, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerPage(
          stories: stories,
          initialIndex: index,
          currentUserId: widget.user.id.isNotEmpty
              ? widget.user.id
              : widget.user.email,
          repository: _repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.user.id.isNotEmpty
        ? widget.user.id
        : widget.user.email;

    return StreamBuilder<List<IringStory>>(
      stream: _repository.watchActiveStories(),
      builder: (context, snapshot) {
        final stories = snapshot.data ?? const [];

        return SizedBox(
          height: 94,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 1 + stories.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return StoryCircleItem(
                  label: 'Your Story',
                  seed: widget.user.displayName.isNotEmpty
                      ? widget.user.displayName
                      : widget.user.email,
                  photoUrl: widget.user.photoUrl,
                  isUser: true,
                  onTap: _openCreateStory,
                );
              }

              final storyIndex = index - 1;
              final story = stories[storyIndex];
              final isViewed = story.isViewedBy(currentUserId);

              return StoryCircleItem(
                label: story.authorName,
                seed: story.authorName,
                photoUrl: story.authorAvatarUrl,
                isViewed: isViewed,
                onTap: () => _openStoryViewer(stories, storyIndex),
              );
            },
          ),
        );
      },
    );
  }
}
