import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/local_event_catalog.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/feline_event.dart';
import '../../domain/repositories/event_repository.dart';
import 'event_center_sheet.dart';

class ActiveEventsCarousel extends StatefulWidget {
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final EventRepository? repository;
  final Duration autoScrollDuration;

  const ActiveEventsCarousel({
    super.key,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl,
    this.repository,
    this.autoScrollDuration = const Duration(seconds: 5),
  });

  @override
  State<ActiveEventsCarousel> createState() => _ActiveEventsCarouselState();
}

class _ActiveEventsCarouselState extends State<ActiveEventsCarousel> {
  late final EventRepository _repository;
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EventRepositoryImpl.instance;
    _pageController = PageController(viewportFraction: 0.94);
  }

  void _startAutoScroll(int count) {
    _autoScrollTimer?.cancel();
    if (count <= 1) return;
    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % count;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FelineEvent>>(
      stream: _repository.watchActiveEvents(),
      builder: (context, snapshot) {
        final allEvents =
            snapshot.data ?? LocalEventCatalog.defaultActiveEvents;
        final carouselEvents = allEvents
            .where((e) => e.isFeaturedInCarousel && e.isActive)
            .toList();

        final displayEvents = carouselEvents.isNotEmpty
            ? carouselEvents
            : LocalEventCatalog.defaultActiveEvents;

        if (_itemCount != displayEvents.length) {
          _itemCount = displayEvents.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startAutoScroll(_itemCount);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 148,
              child: PageView.builder(
                controller: _pageController,
                itemCount: displayEvents.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final event = displayEvents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _CarouselEventCard(
                      event: event,
                      onTap: () {
                        EventCenterSheet.show(
                          context,
                          userId: widget.userId,
                          userDisplayName: widget.userDisplayName,
                          userPhotoUrl: widget.userPhotoUrl,
                          repository: _repository,
                          event: event,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            if (displayEvents.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(displayEvents.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CarouselEventCard extends StatelessWidget {
  final FelineEvent event;
  final VoidCallback onTap;

  const _CarouselEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPartnership = event.isPartnership;
    final partnerLabel =
        event.partnerName != null && event.partnerName!.isNotEmpty
        ? event.partnerName!
        : (isPartnership ? 'Partnership' : 'Limited Event');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              event.bannerColor,
              Color.lerp(event.bannerColor, Colors.black, 0.3)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: event.bannerColor.withAlpha(55),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPartnership
                            ? Icons.handshake_rounded
                            : Icons.celebration_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        partnerLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        event.remainingFormatted,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.white70,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: event.accentColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: event.accentColor.withAlpha(120),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Earn ${event.currencyCode}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: event.accentColor,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'View Event',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
