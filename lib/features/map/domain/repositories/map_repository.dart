import '../entities/live_sighting.dart';

abstract class MapRepository {
  Stream<List<LiveSighting>> getActiveSightingsStream();
  Future<void> dropSighting(LiveSighting sighting);
}
