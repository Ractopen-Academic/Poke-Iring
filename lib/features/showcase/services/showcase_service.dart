import 'package:shared_preferences/shared_preferences.dart';

import '../../dex/domain/entities/feline_dex_species.dart';
import '../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../scanner/domain/entities/cat_sighting.dart';
import '../domain/entities/explorer_showcase_profile.dart';

class ShowcaseService {
  static final ShowcaseService instance = ShowcaseService._internal();

  ShowcaseService._internal();

  static const String _prefKeyPrivacy = 'pokeiring_showcase_is_public';
  static const String _prefKeyPinnedSightings = 'pokeiring_pinned_showcase_ids';

  SharedPreferences? _prefs;
  FirebaseSightingsDataSource? _sightingsDataSource;

  bool _isPublic = true;
  final List<String> _pinnedSightingIds = [];

  bool get isPublicShowcaseEnabled => _isPublic;
  List<String> get pinnedSightingIds => List.unmodifiable(_pinnedSightingIds);
  int get pinnedCount => _pinnedSightingIds.length;

  Future<ExplorerShowcaseProfile> getProfileForUser({
    required String userId,
    required String displayName,
    String avatarUrl = '',
    int rank = 4,
    int pawPoints = 340,
    String tierTitle = 'Trail Scout',
    String territory = 'Bankal, Lapu-Lapu City',
  }) {
    return getProfile(
      targetUserId: userId,
      currentUserId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      rank: rank,
      tierTitle: tierTitle,
      pawPoints: pawPoints,
      territory: territory,
    );
  }

  Future<void> init({
    SharedPreferences? prefs,
    FirebaseSightingsDataSource? sightingsDataSource,
  }) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    _sightingsDataSource = sightingsDataSource ?? FirebaseSightingsDataSource();

    _isPublic = _prefs?.getBool(_prefKeyPrivacy) ?? true;

    final rawPinned = _prefs?.getStringList(_prefKeyPinnedSightings) ?? [];
    _pinnedSightingIds.clear();
    _pinnedSightingIds.addAll(rawPinned);
  }

  Future<void> setPublicShowcaseEnabled(bool enabled) async {
    _isPublic = enabled;
    await _prefs?.setBool(_prefKeyPrivacy, enabled);
  }

  bool isSightingPinned(String sightingId) {
    return _pinnedSightingIds.contains(sightingId);
  }

  Future<bool> togglePinSighting(CatSighting sighting) async {
    if (_pinnedSightingIds.contains(sighting.id)) {
      _pinnedSightingIds.remove(sighting.id);
      await _persistPinnedIds();
      return false;
    } else {
      if (_pinnedSightingIds.length >=
          ExplorerShowcaseProfile.maxShowcaseSlots) {
        throw StateError(
          'Showcase is full (maximum ${ExplorerShowcaseProfile.maxShowcaseSlots} cards). Unpin another cat first.',
        );
      }
      _pinnedSightingIds.add(sighting.id);
      await _persistPinnedIds();
      return true;
    }
  }

  Future<void> _persistPinnedIds() async {
    await _prefs?.setStringList(_prefKeyPinnedSightings, _pinnedSightingIds);
  }

  Future<ExplorerShowcaseProfile> getProfile({
    required String targetUserId,
    required String currentUserId,
    required String displayName,
    required String avatarUrl,
    required int rank,
    String tierTitle = 'Scout',
    required int pawPoints,
    String territory = 'Bankal, Lapu-Lapu City',
  }) async {
    final ds = _sightingsDataSource ?? FirebaseSightingsDataSource();
    final allSightings = await ds
        .watchNearbySightings(latitude: 10.314, longitude: 123.972)
        .first;

    final isCurrentUser = targetUserId == currentUserId;

    if (isCurrentUser) {
      // Find current user's pinned sightings or fall back to their first encounters
      final userSightings = allSightings
          .where((s) => s.userId == targetUserId)
          .toList();
      final sourceList = userSightings.isNotEmpty
          ? userSightings
          : allSightings;

      List<CatSighting> pinned = [];
      if (_pinnedSightingIds.isNotEmpty) {
        pinned = sourceList
            .where((s) => _pinnedSightingIds.contains(s.id))
            .toList();
      }

      if (pinned.isEmpty) {
        pinned = sourceList
            .take(ExplorerShowcaseProfile.maxShowcaseSlots)
            .toList();
      }

      return ExplorerShowcaseProfile(
        userId: targetUserId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        rank: rank,
        tierTitle: tierTitle,
        pawPoints: pawPoints,
        dexDiscoveredCount: 6,
        totalDexSpecies: FelineDexSpecies.canonicalSpecies.length,
        totalBoops: pinned.fold<int>(0, (sum, s) => sum + s.boopsCount),
        territory: territory,
        isPublic: _isPublic,
        showcaseCards: pinned,
      );
    } else {
      // Competitor explorer profile from leaderboard
      final competitorSightings = allSightings
          .where((s) => s.userId == targetUserId || s.authorName == displayName)
          .toList();

      final cards = competitorSightings.isNotEmpty
          ? competitorSightings
                .take(ExplorerShowcaseProfile.maxShowcaseSlots)
                .toList()
          : allSightings.take(3).toList();

      // Check if target user has a mock private flag (for testing/demo)
      final isTargetPublic =
          !displayName.toLowerCase().contains('shadow') &&
          !displayName.toLowerCase().contains('private');

      return ExplorerShowcaseProfile(
        userId: targetUserId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        rank: rank,
        tierTitle: tierTitle,
        pawPoints: pawPoints,
        dexDiscoveredCount: (rank <= 3) ? 12 : (rank <= 10 ? 8 : 4),
        totalDexSpecies: FelineDexSpecies.canonicalSpecies.length,
        totalBoops:
            cards.fold<int>(0, (sum, s) => sum + s.boopsCount) + (rank * 5),
        territory: territory,
        isPublic: isTargetPublic,
        showcaseCards: cards,
      );
    }
  }
}
