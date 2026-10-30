import '../../../scanner/domain/entities/cat_sighting.dart';
import '../entities/iring_dex_entry.dart';

abstract class DexRepository {
  Stream<List<IringDexEntry>> watchDexEntries(String userId);
  Future<List<IringDexEntry>> getDexEntries(String userId);
  Stream<List<CatSighting>> watchUserSightings(String userId);
  Future<List<CatSighting>> getUserSightings(String userId);
}
