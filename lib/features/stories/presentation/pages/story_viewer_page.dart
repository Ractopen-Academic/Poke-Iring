import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../domain/entities/iring_story.dart';
import '../../domain/repositories/stories_repository.dart';

class StoryViewerPage extends StatefulWidget {
  final List<IringStory> stories;
  final int initialIndex;
  final String currentUserId;
  final StoriesRepository repository;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.currentUserId,
    required this.repository,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  late List<IringStory> _stories;
  String? _recentReaction;

  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.stories);
    _currentIndex = widget.initialIndex.clamp(0, _stories.length - 1);

    _progressController =
        AnimationController(vsync: this, duration: _storyDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextStory();
            }
          });

    _markCurrentViewed();
    _progressController.forward();
  }

  void _markCurrentViewed() {
    if (_stories.isNotEmpty && _currentIndex < _stories.length) {
      final story = _stories[_currentIndex];
      widget.repository.markStoryViewed(
        storyId: story.id,
        userId: widget.currentUserId,
      );
    }
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
        _recentReaction = null;
      });
      _markCurrentViewed();
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _recentReaction = null;
      });
      _markCurrentViewed();
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _pause() {
    _progressController.stop();
  }

  void _resume() {
    _progressController.forward();
  }

  void _handleBoop([String reactionText = 'Boop!']) {
    final story = _stories[_currentIndex];
    if (story.isBoopedBy(widget.currentUserId)) return;

    setState(() {
      _stories[_currentIndex] = story.copyWith(
        boopsCount: story.boopsCount + 1,
        boopedBy: List<String>.from(story.boopedBy)..add(widget.currentUserId),
      );
      _recentReaction = reactionText;
    });

    widget.repository.boopStory(
      storyId: story.id,
      userId: widget.currentUserId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
        content: Text(
          '$reactionText sent to ${story.authorName}!',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(body: Center(child: Text('No stories active')));
    }

    final story = _stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth * 0.35) {
              _previousStory();
            } else {
              _nextStory();
            }
          },
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Content / Background
              _buildStoryMedia(story),

              // Gradient overlays for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha(150),
                        Colors.transparent,
                        Colors.black.withAlpha(200),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Top Segmented Progress Bar & Header
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    _buildSegmentedProgressBar(),
                    const SizedBox(height: 12),
                    _buildStoryHeader(story),
                  ],
                ),
              ),

              // Reaction Overlay (if any)
              if (_recentReaction != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _recentReaction!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Bottom Caption & Interactive Reactions Bar
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildBottomInteractiveBar(story),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryMedia(IringStory story) {
    if (story.mediaUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: story.mediaUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            _buildFallbackFelineGraphic(story),
      );
    }
    return _buildFallbackFelineGraphic(story);
  }

  Widget _buildFallbackFelineGraphic(IringStory story) {
    return Container(
      color: const Color(0xFF1E1E24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FelineAvatar(
              seed: story.authorName,
              radius: 54,
              showBorder: true,
              borderColor: Colors.white24,
              borderWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              story.catBreed,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Text(
                story.locationTag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedProgressBar() {
    return Row(
      children: List.generate(_stories.length, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: index < _currentIndex
                    ? const ColoredBox(color: Colors.white)
                    : index == _currentIndex
                    ? AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          );
                        },
                      )
                    : const ColoredBox(color: Colors.white24),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStoryHeader(IringStory story) {
    return Row(
      children: [
        FelineAvatar(
          photoUrl: story.authorAvatarUrl,
          seed: story.authorName,
          radius: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.authorName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '${story.catBreed} • ${story.locationTag}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBottomInteractiveBar(IringStory story) {
    final hasBooped = story.isBoopedBy(widget.currentUserId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (story.caption.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              story.caption,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Quick reaction chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildReactionChip('Ka-cute!'),
              _buildReactionChip('Pspsps'),
              _buildReactionChip('Majestic loaf!'),
              _buildReactionChip('Spotter MVP!'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Boop Action Button
        ElevatedButton.icon(
          onPressed: hasBooped ? null : () => _handleBoop('Booped!'),
          icon: Icon(
            hasBooped ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: Colors.white,
          ),
          label: Text(
            hasBooped
                ? 'Booped (${story.boopsCount})'
                : 'Boop this Cat! (${story.boopsCount})',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildReactionChip(String reaction) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(
          reaction,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.white.withAlpha(35),
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _handleBoop(reaction),
      ),
    );
  }
}
