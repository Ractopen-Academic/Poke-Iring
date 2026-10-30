import '../../../scanner/domain/entities/cat_sighting.dart';
import 'feline_dex_species.dart';

class IringDexEntry {
  final FelineDexSpecies species;
  final bool isDiscovered;
  final int timesSighted;
  final DateTime? firstSightedAt;
  final DateTime? lastSightedAt;
  final String? bestLocation;
  final int bestPawPoints;
  final String? bestPhotoUrl;
  final String? bestStickerUrl;
  final List<CatSighting> sightings;

  const IringDexEntry({
    required this.species,
    required this.isDiscovered,
    this.timesSighted = 0,
    this.firstSightedAt,
    this.lastSightedAt,
    this.bestLocation,
    this.bestPawPoints = 0,
    this.bestPhotoUrl,
    this.bestStickerUrl,
    this.sightings = const [],
  });

  factory IringDexEntry.undiscovered(FelineDexSpecies species) {
    return IringDexEntry(
      species: species,
      isDiscovered: false,
      timesSighted: 0,
    );
  }

  factory IringDexEntry.fromSightings({
    required FelineDexSpecies species,
    required List<CatSighting> matchedSightings,
  }) {
    if (matchedSightings.isEmpty) {
      return IringDexEntry.undiscovered(species);
    }

    final sorted = List<CatSighting>.from(matchedSightings)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final bestByPoints = List<CatSighting>.from(matchedSightings)
      ..sort((a, b) => b.pawPoints.compareTo(a.pawPoints));

    final best = bestByPoints.first;

    return IringDexEntry(
      species: species,
      isDiscovered: true,
      timesSighted: matchedSightings.length,
      firstSightedAt: sorted.first.createdAt,
      lastSightedAt: sorted.last.createdAt,
      bestLocation: '${best.barangay}, ${best.city}',
      bestPawPoints: best.pawPoints,
      bestPhotoUrl: best.photoUrl.isNotEmpty ? best.photoUrl : null,
      bestStickerUrl: best.stickerUrl.isNotEmpty ? best.stickerUrl : null,
      sightings: List.unmodifiable(matchedSightings),
    );
  }
}
