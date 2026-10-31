import 'package:flutter/material.dart';

import '../../data/datasources/local_event_catalog.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/feline_event.dart';
import '../../domain/entities/user_event_wallet.dart';
import '../../domain/repositories/event_repository.dart';
import 'event_center_sheet.dart';

class EventBannerCard extends StatelessWidget {
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final EventRepository? repository;

  const EventBannerCard({
    super.key,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? EventRepositoryImpl.instance;

    return StreamBuilder<FelineEvent>(
      stream: repo.watchActiveEvent(),
      builder: (context, eventSnapshot) {
        final event = eventSnapshot.data ?? LocalEventCatalog.activeFestival;

        return StreamBuilder<UserEventWallet>(
          stream: repo.watchUserWallet(userId, event.id),
          builder: (context, walletSnapshot) {
            final wallet = walletSnapshot.data;
            final coins = wallet?.coinBalance ?? 0;

            return GestureDetector(
              onTap: () => EventCenterSheet.show(
                context,
                userId: userId,
                userDisplayName: userDisplayName,
                userPhotoUrl: userPhotoUrl,
                repository: repo,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      event.bannerColor,
                      Color.lerp(event.bannerColor, Colors.black, 0.25)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: event.bannerColor.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  event.remainingFormatted,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Earn ${event.currencyCode} to unlock exclusive profile borders',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(210),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: event.accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.toll_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$coins ${event.currencyCode}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
