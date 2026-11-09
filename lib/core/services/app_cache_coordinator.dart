import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/dex/data/datasources/firebase_dex_datasource.dart';
import '../../features/dex/domain/entities/feline_dex_species.dart';
import '../../features/events/data/repositories/event_repository_impl.dart';
import '../../features/events/domain/entities/feline_event.dart';
import '../../features/leaderboard/data/datasources/firebase_leaderboard_datasource.dart';
import '../../features/leaderboard/domain/entities/leaderboard_entry.dart';
import '../../features/quests/data/datasources/firebase_quest_datasource.dart';
import '../../features/quests/domain/entities/quest_template.dart';
import '../../features/seasons/data/datasources/firebase_seasons_datasource.dart';

/// Detailed report of a cache invalidation and cloud re-synchronization cycle.
class RecacheReport {
  final int syncedCollectionsCount;
  final bool hasNetworkErrors;
  final String statusSummary;
  final DateTime timestamp;

  const RecacheReport({
    required this.syncedCollectionsCount,
    required this.hasNetworkErrors,
    required this.statusSummary,
    required this.timestamp,
  });
}

/// Central coordinator for invalidating and force-refreshing local and cloud caches across all features.
///
/// Ensures edge-case resilience:
/// - Retains existing memory/local caches if the device is offline or the remote fetch times out.
/// - Catches isolated collection errors independently so one failing endpoint does not abort others.
class AppCacheCoordinator {
  static final AppCacheCoordinator instance = AppCacheCoordinator._internal();

  AppCacheCoordinator._internal();

  /// Forces a complete invalidation and fresh cloud synchronization across all feature catalogs:
  /// Dex Species, Events, Quests, Leaderboard rankings, and Seasons.
  Future<RecacheReport> forceRecacheAll({String? userId}) async {
    int syncedCount = 0;
    bool hasError = false;

    // 1. Dex Species
    try {
      await FirebaseDexDataSource.instance.forceRefreshSpecies();
      syncedCount++;
    } catch (e) {
      hasError = true;
      debugPrint('Recache dex species error: $e');
    }

    // 2. Active Events
    try {
      await EventRepositoryImpl.instance.forceRefreshActiveEvents();
      syncedCount++;
    } catch (e) {
      hasError = true;
      debugPrint('Recache active events error: $e');
    }

    // 3. Quest Pool
    try {
      await FirebaseQuestDataSource.instance.forceRefreshQuestPool();
      syncedCount++;
    } catch (e) {
      hasError = true;
      debugPrint('Recache quest pool error: $e');
    }

    // 4. Leaderboard
    try {
      await FirebaseLeaderboardDataSource.instance.forceRefreshEntries(
        currentUserId: userId,
      );
      syncedCount++;
    } catch (e) {
      hasError = true;
      debugPrint('Recache leaderboard error: $e');
    }

    // 5. Active Season
    try {
      await FirebaseSeasonsDataSource.instance.forceRefreshActiveSeason();
      syncedCount++;
    } catch (e) {
      hasError = true;
      debugPrint('Recache season error: $e');
    }

    return RecacheReport(
      syncedCollectionsCount: syncedCount,
      hasNetworkErrors: hasError,
      statusSummary: hasError
          ? 'Synchronized $syncedCount collections with fallback data retained.'
          : 'Successfully synchronized all $syncedCount catalog collections.',
      timestamp: DateTime.now(),
    );
  }

  /// Refreshes the Home Feed items (Events, Leaderboard preview, Quests)
  Future<void> refreshHomeFeed({String? userId}) async {
    await Future.wait([
      EventRepositoryImpl.instance.forceRefreshActiveEvents().catchError(
        (_) => const <FelineEvent>[],
      ),
      FirebaseLeaderboardDataSource.instance
          .forceRefreshEntries(currentUserId: userId)
          .catchError((_) => const <LeaderboardEntry>[]),
      FirebaseQuestDataSource.instance.forceRefreshQuestPool().catchError(
        (_) => const <QuestTemplate>[],
      ),
    ]);
  }

  /// Refreshes the Dex catalog
  Future<void> refreshDex() async {
    await FirebaseDexDataSource.instance.forceRefreshSpecies().catchError(
      (_) => const <FelineDexSpecies>[],
    );
  }

  /// Refreshes the Leaderboard
  Future<void> refreshLeaderboard({String? userId}) async {
    await FirebaseLeaderboardDataSource.instance
        .forceRefreshEntries(currentUserId: userId)
        .catchError((_) => const <LeaderboardEntry>[]);
  }
}
