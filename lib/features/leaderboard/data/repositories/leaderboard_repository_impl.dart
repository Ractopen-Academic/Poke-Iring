import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_query.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/firebase_leaderboard_datasource.dart';
import '../datasources/mock_leaderboard_datasource.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final MockLeaderboardDatasource datasource;
  final FirebaseLeaderboardDataSource firebaseDatasource;

  LeaderboardRepositoryImpl({
    this.datasource = const MockLeaderboardDatasource(),
    FirebaseLeaderboardDataSource? firebaseDatasource,
  }) : firebaseDatasource =
           firebaseDatasource ?? FirebaseLeaderboardDataSource.instance;

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardFilter filter,
    required String currentUserId,
  }) async {
    final allEntries = await _getAllEntries(currentUserId, filter);
    final filtered = _filterByScope(allEntries, filter);
    final sorted = _sortByCategory(filtered, filter.category);
    final ranked = _assignRanks(sorted);

    final capacity = filter.scope.poolCapacity;
    final effectiveLimit = filter.limit > capacity ? capacity : filter.limit;

    final start = filter.offset.clamp(0, ranked.length);
    final end = (start + effectiveLimit).clamp(start, ranked.length);

    return ranked.sublist(start, end);
  }

  @override
  Future<LeaderboardEntry?> getUserStanding({
    required String userId,
    required LeaderboardFilter filter,
  }) async {
    final allEntries = await _getAllEntries(userId, filter);
    final filtered = _filterByScope(allEntries, filter);
    final sorted = _sortByCategory(filtered, filter.category);
    final ranked = _assignRanks(sorted);

    try {
      return ranked.firstWhere((e) => e.userId == userId || e.isCurrentUser);
    } catch (_) {
      return null;
    }
  }

  Future<List<LeaderboardEntry>> _getAllEntries(
    String currentUserId,
    LeaderboardFilter filter,
  ) async {
    final liveEntries = await firebaseDatasource.fetchEntries(
      currentUserId: currentUserId,
    );
    final entries = liveEntries.isNotEmpty
        ? liveEntries
        : datasource.getSeedEntries();

    final hasUser = entries.any((e) => e.userId == currentUserId);

    if (hasUser) {
      return entries
          .map((e) => e.copyWith(isCurrentUser: e.userId == currentUserId))
          .toList();
    }

    final currentUserEntry = LeaderboardEntry(
      id: 'current-user-entry',
      rank: 0,
      userId: currentUserId,
      displayName: 'You (Explorer)',
      avatarColorIndex: 2,
      barangay: filter.barangay,
      city: filter.city,
      region: filter.region,
      country: filter.country,
      points: 2150,
      catsSnapped: 15,
      distanceKm: 12.8,
      mythicPaws: 0,
      isCurrentUser: true,
    );

    return [...entries, currentUserEntry];
  }

  List<LeaderboardEntry> _filterByScope(
    List<LeaderboardEntry> entries,
    LeaderboardFilter filter,
  ) {
    switch (filter.scope) {
      case LeaderboardScope.barangay:
        return entries
            .where(
              (e) => e.barangay.toLowerCase() == filter.barangay.toLowerCase(),
            )
            .toList();
      case LeaderboardScope.city:
        return entries
            .where((e) => e.city.toLowerCase() == filter.city.toLowerCase())
            .toList();
      case LeaderboardScope.region:
        return entries
            .where((e) => e.region.toLowerCase() == filter.region.toLowerCase())
            .toList();
      case LeaderboardScope.national:
        return entries
            .where(
              (e) => e.country.toLowerCase() == filter.country.toLowerCase(),
            )
            .toList();
      case LeaderboardScope.global:
        return List<LeaderboardEntry>.from(entries);
    }
  }

  List<LeaderboardEntry> _sortByCategory(
    List<LeaderboardEntry> entries,
    LeaderboardCategory category,
  ) {
    final list = List<LeaderboardEntry>.from(entries);
    switch (category) {
      case LeaderboardCategory.overall:
        list.sort((a, b) => b.points.compareTo(a.points));
        break;
      case LeaderboardCategory.snaps:
        list.sort((a, b) => b.catsSnapped.compareTo(a.catsSnapped));
        break;
      case LeaderboardCategory.distance:
        list.sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
        break;
    }
    return list;
  }

  List<LeaderboardEntry> _assignRanks(List<LeaderboardEntry> entries) {
    return List.generate(entries.length, (index) {
      return entries[index].copyWith(rank: index + 1);
    });
  }
}
