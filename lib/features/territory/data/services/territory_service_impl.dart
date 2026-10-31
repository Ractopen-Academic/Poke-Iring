import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/location_service_impl.dart';
import '../../domain/entities/explorer_territory.dart';
import '../../domain/services/territory_service.dart';
import '../datasources/ph_territory_catalog.dart';

class TerritoryServiceImpl implements TerritoryService {
  static TerritoryServiceImpl? _instance;
  static TerritoryServiceImpl get instance =>
      _instance ??= TerritoryServiceImpl();

  final LocationService _locationService;
  final Map<String, StreamController<ExplorerTerritory>> _controllers = {};
  final Map<String, ExplorerTerritory> _cache = {};

  TerritoryServiceImpl({LocationService? locationService})
    : _locationService = locationService ?? LocationServiceImpl();

  String _prefKey(String userId) => 'territory_$userId';

  @override
  Stream<ExplorerTerritory> watchTerritory(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<ExplorerTerritory>.broadcast(
        onListen: () {
          getTerritory(userId).then((t) {
            if (_controllers[userId]?.isClosed == false) {
              _controllers[userId]?.add(t);
            }
          });
        },
      );
    }
    return _controllers[userId]!.stream;
  }

  @override
  Future<ExplorerTerritory> getTerritory(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final barangay = prefs.getString('${_prefKey(userId)}_barangay');
      final city = prefs.getString('${_prefKey(userId)}_city');
      final province =
          prefs.getString('${_prefKey(userId)}_province') ?? 'Cebu';
      final country =
          prefs.getString('${_prefKey(userId)}_country') ?? 'Philippines';
      final isConfirmed =
          prefs.getBool('${_prefKey(userId)}_confirmed') ?? false;

      if (barangay != null && city != null) {
        final territory = ExplorerTerritory(
          barangay: barangay,
          city: city,
          province: province,
          country: country,
          isHomeConfirmed: isConfirmed,
        );
        _cache.putIfAbsent(userId, () => territory);
        return _cache[userId]!;
      }
    } catch (_) {}

    final defaultTerritory = ExplorerTerritory.defaultTerritory;
    _cache.putIfAbsent(userId, () => defaultTerritory);
    return _cache[userId]!;
  }

  @override
  Future<void> updateTerritory(
    String userId,
    ExplorerTerritory territory,
  ) async {
    _cache[userId] = territory;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_prefKey(userId)}_barangay', territory.barangay);
      await prefs.setString('${_prefKey(userId)}_city', territory.city);
      await prefs.setString('${_prefKey(userId)}_province', territory.province);
      await prefs.setString('${_prefKey(userId)}_country', territory.country);
      await prefs.setBool(
        '${_prefKey(userId)}_confirmed',
        territory.isHomeConfirmed,
      );
    } catch (_) {}

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(territory);
    }
  }

  @override
  Future<ExplorerTerritory> detectFromGps() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        return PhTerritoryCatalog.resolveCoordinates(
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      }
    } catch (_) {}

    return ExplorerTerritory.defaultTerritory;
  }
}
