import '../../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../domain/entities/feline_dex_species.dart';
import '../../domain/entities/iring_dex_entry.dart';
import '../../domain/repositories/dex_repository.dart';

class DexRepositoryImpl implements DexRepository {
  final FirebaseSightingsDataSource _dataSource;

  DexRepositoryImpl({FirebaseSightingsDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseSightingsDataSource();

  @override
  Stream<List<CatSighting>> watchUserSightings(String userId) {
    return _dataSource.watchSightingsByUser(userId);
  }

  @override
  Future<List<CatSighting>> getUserSightings(String userId) {
    return _dataSource.watchSightingsByUser(userId).first;
  }

  @override
  Stream<List<IringDexEntry>> watchDexEntries(String userId) {
    return _dataSource.watchSightingsByUser(userId).map((sightings) {
      return _buildEntries(sightings);
    });
  }

  @override
  Future<List<IringDexEntry>> getDexEntries(String userId) async {
    final sightings = await getUserSightings(userId);
    return _buildEntries(sightings);
  }

  List<IringDexEntry> _buildEntries(List<CatSighting> sightings) {
    return FelineDexSpecies.canonicalSpecies.map((species) {
      final matches = sightings
          .where((s) => _matchesSpecies(species, s))
          .toList();
      return IringDexEntry.fromSightings(
        species: species,
        matchedSightings: matches,
      );
    }).toList();
  }

  bool _matchesSpecies(FelineDexSpecies species, CatSighting sighting) {
    final sBreed = sighting.breed.toLowerCase();
    final sCoat = sighting.coatPattern.toLowerCase();
    final sColor = sighting.dominantColor.toLowerCase();

    final specName = species.name.toLowerCase();
    final specCommon = species.commonName.toLowerCase();
    final specCoat = species.coatPattern.toLowerCase();

    // Check specific breed names
    if (specName.contains('siamese') &&
        (sBreed.contains('siamese') || sCoat.contains('colorpoint'))) {
      return true;
    }
    if (specName.contains('bengal') &&
        (sBreed.contains('bengal') || sCoat.contains('rosetted'))) {
      return true;
    }
    if (specName.contains('persian') && sBreed.contains('persian')) {
      return true;
    }
    if (specName.contains('british shorthair') && sBreed.contains('british')) {
      return true;
    }
    if (specName.contains('scottish fold') && sBreed.contains('scottish')) {
      return true;
    }
    if (specName.contains('ragdoll') && sBreed.contains('ragdoll')) {
      return true;
    }
    if (specName.contains('russian blue') &&
        (sBreed.contains('russian blue') || sCoat.contains('slate'))) {
      return true;
    }
    if (specName.contains('maine coon') && sBreed.contains('maine coon')) {
      return true;
    }
    if (specName.contains('sphynx') &&
        (sBreed.contains('sphynx') || sCoat.contains('hairless'))) {
      return true;
    }

    // Check coat pattern variants
    if (specCoat.contains('calico') &&
        (sBreed.contains('calico') || sCoat.contains('calico'))) {
      return true;
    }
    if (specCoat.contains('tortoiseshell') &&
        (sBreed.contains('tortoiseshell') ||
            sCoat.contains('tortie') ||
            sCoat.contains('tortoiseshell'))) {
      return true;
    }
    if (specCoat.contains('tuxedo') &&
        (sBreed.contains('tuxedo') || sCoat.contains('tuxedo'))) {
      return true;
    }
    if (specCoat.contains('orange tabby') &&
        (sBreed.contains('orange') ||
            sBreed.contains('ginger') ||
            sCoat.contains('orange') ||
            sColor.contains('ginger'))) {
      return true;
    }
    if (specCoat.contains('solid black') &&
        (sCoat.contains('black') || sColor.contains('black')) &&
        !sCoat.contains('tuxedo') &&
        !sCoat.contains('calico')) {
      return true;
    }
    if (specCoat.contains('solid white') &&
        (sCoat.contains('white') || sColor.contains('white')) &&
        !sCoat.contains('tuxedo') &&
        !sCoat.contains('calico')) {
      return true;
    }
    if (species.id == 'dex_001') {
      // Classic Puspin Tabby: matches general Tabby or Puspin without special markings
      if (sBreed.contains('domestic shorthair') ||
          sBreed.contains('puspin') ||
          sCoat.contains('tabby')) {
        return true;
      }
    }

    return specCommon.contains(sBreed) || specName.contains(sBreed);
  }
}
