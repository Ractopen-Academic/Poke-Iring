import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/firebase_territory_datasource.dart';
import '../../data/datasources/ph_territory_catalog.dart';
import '../../data/services/territory_service_impl.dart';
import '../../domain/entities/explorer_territory.dart';

class TerritorySelectionSheet extends StatefulWidget {
  final String userId;
  final ExplorerTerritory initialTerritory;
  final ValueChanged<ExplorerTerritory>? onTerritorySaved;
  final FirebaseTerritoryDataSource? territoryDataSource;

  const TerritorySelectionSheet({
    super.key,
    required this.userId,
    required this.initialTerritory,
    this.onTerritorySaved,
    this.territoryDataSource,
  });

  static Future<ExplorerTerritory?> show(
    BuildContext context, {
    required String userId,
    required ExplorerTerritory currentTerritory,
    ValueChanged<ExplorerTerritory>? onSaved,
    FirebaseTerritoryDataSource? territoryDataSource,
  }) {
    return showModalBottomSheet<ExplorerTerritory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TerritorySelectionSheet(
        userId: userId,
        initialTerritory: currentTerritory,
        onTerritorySaved: onSaved,
        territoryDataSource: territoryDataSource,
      ),
    );
  }

  @override
  State<TerritorySelectionSheet> createState() =>
      _TerritorySelectionSheetState();
}

class _TerritorySelectionSheetState extends State<TerritorySelectionSheet> {
  late final FirebaseTerritoryDataSource _dataSource;
  List<PhCityTerritory> _cities = [];
  late String _selectedCity;
  late String _selectedBarangay;
  bool _isLoading = true;
  bool _isDetecting = false;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _dataSource =
        widget.territoryDataSource ?? FirebaseTerritoryDataSource.instance;
    _selectedCity = widget.initialTerritory.city;
    _selectedBarangay = widget.initialTerritory.barangay;
    _loadTerritories();
  }

  Future<void> _loadTerritories() async {
    final cities = await _dataSource.getCities();
    if (!mounted) return;

    setState(() {
      _cities = cities;
      _isLoading = false;

      // Ensure city exists or add initial
      final hasCity = _cities.any(
        (c) => c.city.toLowerCase() == _selectedCity.toLowerCase(),
      );

      if (!hasCity) {
        final newEntry = PhCityTerritory(
          city: _selectedCity,
          province: widget.initialTerritory.province,
          region: widget.initialTerritory.region,
          barangays: [_selectedBarangay],
        );
        _cities = [..._cities, newEntry]
          ..sort((a, b) => a.city.compareTo(b.city));
      }

      final cityEntry = _currentCityEntry;
      if (!cityEntry.barangays.contains(_selectedBarangay)) {
        _selectedBarangay = cityEntry.barangays.first;
      }
    });
  }

  PhCityTerritory get _currentCityEntry {
    if (_cities.isEmpty) {
      return PhTerritoryCatalog.cities.first;
    }
    return _cities.firstWhere(
      (c) => c.city.toLowerCase() == _selectedCity.toLowerCase(),
      orElse: () => _cities.first,
    );
  }

  List<PhCityTerritory> get _filteredCities {
    if (_searchFilter.trim().isEmpty) return _cities;
    final query = _searchFilter.toLowerCase().trim();
    return _cities
        .where(
          (c) =>
              c.city.toLowerCase().contains(query) ||
              c.province.toLowerCase().contains(query) ||
              c.region.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _handleGpsDetect() async {
    setState(() => _isDetecting = true);
    final detected = await TerritoryServiceImpl.instance.detectFromGps();
    if (!mounted) return;

    setState(() {
      _isDetecting = false;
      _selectedCity = detected.city;
      _selectedBarangay = detected.barangay;

      // Ensure detected city and barangay exist in the in-memory list
      final cityIdx = _cities.indexWhere(
        (c) => c.city.toLowerCase() == detected.city.toLowerCase(),
      );

      if (cityIdx == -1) {
        final detectedEntry = PhCityTerritory(
          city: detected.city,
          province: detected.province,
          region: detected.region,
          barangays: [detected.barangay],
        );
        _cities = [..._cities, detectedEntry]
          ..sort((a, b) => a.city.compareTo(b.city));
      } else {
        final existing = _cities[cityIdx];
        if (!existing.barangays.contains(detected.barangay)) {
          final updated = existing.copyWith(
            barangays: [...existing.barangays, detected.barangay]..sort(),
          );
          _cities[cityIdx] = updated;
        }
      }
    });
  }

  Future<void> _promptAddCustomBarangay() async {
    final textController = TextEditingController();
    final newBarangay = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Neighborhood Barangay'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Barangay Name',
            hintText: 'e.g. San Roque',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newBarangay != null && mounted) {
      await _dataSource.registerBarangay(
        cityName: _selectedCity,
        barangayName: newBarangay,
      );
      await _loadTerritories();
      setState(() {
        _selectedBarangay = newBarangay;
      });
    }
  }

  Future<void> _saveTerritory() async {
    final entry = _currentCityEntry;
    final newTerritory = ExplorerTerritory(
      barangay: _selectedBarangay,
      city: _selectedCity,
      province: entry.province,
      country: 'Philippines',
      isHomeConfirmed: true,
    );

    await TerritoryServiceImpl.instance.updateTerritory(
      widget.userId,
      newTerritory,
    );
    widget.onTerritorySaved?.call(newTerritory);

    if (mounted) {
      Navigator.of(context).pop(newTerritory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityEntry = _currentCityEntry;
    final availableBarangays = cityEntry.barangays.contains(_selectedBarangay)
        ? cityEntry.barangays
        : [_selectedBarangay, ...cityEntry.barangays];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home Neighborhood',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Cloud database & live GPS reverse geocoding',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GPS Auto-detect button
                OutlinedButton.icon(
                  onPressed: _isDetecting ? null : _handleGpsDetect,
                  icon: _isDetecting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(
                    _isDetecting
                        ? 'Detecting GPS (Reverse Geocoding)...'
                        : 'Detect Neighborhood from GPS',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // City Picker with Search Filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'City / Municipality',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_cities.length} cities in database',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchFilter = val),
                    decoration: const InputDecoration(
                      hintText: 'Search city or province...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _cities.any((c) => c.city == _selectedCity)
                          ? _selectedCity
                          : _cities.first.city,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      items: _filteredCities.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.city,
                          child: Text(
                            '${c.city} (${c.province})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newCity) {
                        if (newCity != null) {
                          setState(() {
                            _selectedCity = newCity;
                            final newEntry = _cities.firstWhere(
                              (c) => c.city == newCity,
                            );
                            _selectedBarangay = newEntry.barangays.first;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Barangay Picker & Add Custom Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Barangay (Neighborhood)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _promptAddCustomBarangay,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add Barangay',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availableBarangays.contains(_selectedBarangay)
                          ? _selectedBarangay
                          : availableBarangays.first,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      items: availableBarangays.map((b) {
                        return DropdownMenuItem<String>(
                          value: b,
                          child: Text(
                            b,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newBarangay) {
                        if (newBarangay != null) {
                          setState(() => _selectedBarangay = newBarangay);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Save button
                ElevatedButton(
                  onPressed: _saveTerritory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Set as Home Territory',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
    );
  }
}
