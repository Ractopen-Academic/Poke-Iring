import '../../domain/entities/live_sighting.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDatasource datasource;

  MapRepositoryImpl({required this.datasource});

  @override
  Stream<List<LiveSighting>> getActiveSightingsStream() {
    return datasource.getActiveSightingsStream();
  }

  @override
  Future<void> dropSighting(LiveSighting sighting) {
    return datasource.dropSighting(sighting);
  }
}
