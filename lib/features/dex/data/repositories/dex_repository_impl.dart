import '../../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../domain/entities/feline_dex_species.dart';
import '../../domain/entities/iring_dex_entry.dart';
import '../../domain/repositories/dex_repository.dart';
import '../datasources/firebase_dex_datasource.dart';

class DexRepositoryImpl implements DexRepository {
  final FirebaseSightingsDataSource _dataSource;
  final FirebaseDexDataSource _dexDataSource;

  DexRepositoryImpl({
    FirebaseSightingsDataSource? dataSource,
    FirebaseDexDataSource? dexDataSource,
  }) : _dataSource = dataSource ?? FirebaseSightingsDataSource(),
       _dexDataSource = dexDataSource ?? FirebaseDexDataSource.instance;

  @override
  Stream<List<CatSighting>> watchUserSightings(String userId) {
    return _dataSource.watchSightingsByUser(userId);
  }

  @override
  Future<List<CatSighting>> getUserSightings(String userId) {
    return _dataSource.watchSightingsByUser(userId).first;
  }

  @override
  Stream<List<FelineDexSpecies>> watchSpecies() {
    return _dexDataSource.watchSpecies();
  }

  @override
  Future<List<FelineDexSpecies>> getSpecies() {
    return _dexDataSource.getSpecies();
  }

  @override
  Stream<List<IringDexEntry>> watchDexEntries(String userId) {
    return _dataSource.watchSightingsByUser(userId).asyncMap((sightings) async {
      final speciesList = await _dexDataSource.getSpecies();
      return _buildEntries(sightings, speciesList);
    });
  }

  @override
  Future<List<IringDexEntry>> getDexEntries(String userId) async {
    final sightings = await getUserSightings(userId);
    final speciesList = await _dexDataSource.getSpecies();
    return _buildEntries(sightings, speciesList);
  }

  List<IringDexEntry> _buildEntries(
    List<CatSighting> sightings, [
    List<FelineDexSpecies>? speciesList,
  ]) {
    final effectiveSpecies = (speciesList != null && speciesList.isNotEmpty)
        ? speciesList
        : FelineDexSpecies.canonicalSpecies;

    return effectiveSpecies.map((species) {
      final matches = sightings
          .where((s) => matchesSpecies(species, s))
          .toList();
      return IringDexEntry.fromSightings(
        species: species,
        matchedSightings: matches,
      );
    }).toList();
  }

  /// Resolves which canonical [FelineDexSpecies] a [CatSighting] belongs to.
  static bool matchesSpecies(FelineDexSpecies species, CatSighting sighting) {
    final sBreed = sighting.breed.toLowerCase().trim();
    final sCoat = sighting.coatPattern.toLowerCase().trim();
    final sColor = sighting.dominantColor.toLowerCase().trim();

    final specName = species.name.toLowerCase();
    final specCommon = species.commonName.toLowerCase();
    final specCoat = species.coatPattern.toLowerCase();

    // 1. Specific purebreds match first
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
    if (specName.contains('british shorthair') &&
        (sBreed.contains('british') || sCoat.contains('solid blue'))) {
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

    // 2. Specialized native Puspin coat patterns
    final isCalico = sBreed.contains('calico') || sCoat.contains('calico');
    if (specCoat.contains('calico')) return isCalico;

    final isTortie =
        sBreed.contains('tortoiseshell') ||
        sBreed.contains('tortie') ||
        sCoat.contains('tortie') ||
        sCoat.contains('tortoiseshell');
    if (specCoat.contains('tortoiseshell')) return isTortie;

    final isTuxedo =
        sBreed.contains('tuxedo') ||
        sCoat.contains('tuxedo') ||
        (sCoat.contains('bicolor') &&
            sColor.contains('black') &&
            sColor.contains('white'));
    if (specCoat.contains('tuxedo')) return isTuxedo;

    final isGinger =
        sBreed.contains('orange') ||
        sBreed.contains('ginger') ||
        sCoat.contains('orange') ||
        sColor.contains('ginger');
    if (specCoat.contains('orange tabby')) return isGinger;

    final isSolidBlack =
        (sCoat.contains('solid black') ||
            (sCoat.contains('black') &&
                !sCoat.contains('tuxedo') &&
                !sCoat.contains('calico') &&
                !sCoat.contains('bicolor')) ||
            sColor == 'black' ||
            sColor.contains('solid black')) &&
        !sCoat.contains('bicolor') &&
        !isTuxedo &&
        !isCalico;
    if (specCoat.contains('solid black')) return isSolidBlack;

    final isSolidWhite =
        (sCoat.contains('solid white') ||
            (sCoat.contains('white') &&
                !sCoat.contains('tuxedo') &&
                !sCoat.contains('calico') &&
                !sCoat.contains('bicolor')) ||
            sColor == 'white' ||
            sColor.contains('solid white')) &&
        !sCoat.contains('bicolor') &&
        !isTuxedo &&
        !isCalico;
    if (specCoat.contains('solid white')) return isSolidWhite;

    // 3. Classic Tabby Puspin (dex_001): catches classic/brown tabbies and
    // general domestic shorthair/bicolor/uncategorized street cats that do not
    // belong to another specialized coat or purebred entry.
    if (species.id == 'dex_001') {
      final hasNamedPurebred =
          sBreed.contains('siamese') ||
          sBreed.contains('bengal') ||
          sBreed.contains('persian') ||
          sBreed.contains('british') ||
          sBreed.contains('scottish') ||
          sBreed.contains('ragdoll') ||
          sBreed.contains('russian blue') ||
          sBreed.contains('maine coon') ||
          sBreed.contains('sphynx');
      final hasSpecializedCoat =
          isCalico ||
          isTortie ||
          isTuxedo ||
          isGinger ||
          isSolidBlack ||
          isSolidWhite ||
          sCoat.contains('colorpoint') ||
          sCoat.contains('rosetted');

      if (!hasNamedPurebred && !hasSpecializedCoat) {
        return sCoat.contains('tabby') ||
            sCoat.contains('bicolor') ||
            sCoat.contains('solid gray') ||
            sBreed.contains('domestic shorthair') ||
            sBreed.contains('domestic longhair') ||
            sBreed.contains('puspin') ||
            sBreed.contains('uncategorized') ||
            sBreed.contains('other') ||
            sBreed.isEmpty;
      }
      return false;
    }

    return (sBreed.isNotEmpty &&
            (specCommon.contains(sBreed) ||
                specName.contains(sBreed) ||
                sBreed.contains(specName))) ||
        (specCoat.isNotEmpty && sCoat.contains(specCoat));
  }
}
