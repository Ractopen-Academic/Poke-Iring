import '../entities/explorer_territory.dart';

abstract class TerritoryService {
  Stream<ExplorerTerritory> watchTerritory(String userId);
  Future<ExplorerTerritory> getTerritory(String userId);
  Future<void> updateTerritory(String userId, ExplorerTerritory territory);
  Future<ExplorerTerritory> detectFromGps();
}
