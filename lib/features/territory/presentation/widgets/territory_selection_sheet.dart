import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/ph_territory_catalog.dart';
import '../../data/services/territory_service_impl.dart';
import '../../domain/entities/explorer_territory.dart';

class TerritorySelectionSheet extends StatefulWidget {
  final String userId;
  final ExplorerTerritory initialTerritory;
  final ValueChanged<ExplorerTerritory>? onTerritorySaved;

  const TerritorySelectionSheet({
    super.key,
    required this.userId,
    required this.initialTerritory,
    this.onTerritorySaved,
  });

  static Future<ExplorerTerritory?> show(
    BuildContext context, {
    required String userId,
    required ExplorerTerritory currentTerritory,
    ValueChanged<ExplorerTerritory>? onSaved,
  }) {
    return showModalBottomSheet<ExplorerTerritory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TerritorySelectionSheet(
        userId: userId,
        initialTerritory: currentTerritory,
        onTerritorySaved: onSaved,
      ),
    );
  }

  @override
  State<TerritorySelectionSheet> createState() =>
      _TerritorySelectionSheetState();
}

class _TerritorySelectionSheetState extends State<TerritorySelectionSheet> {
  late String _selectedCity;
  late String _selectedBarangay;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialTerritory.city;
    _selectedBarangay = widget.initialTerritory.barangay;

    // Ensure selected city exists in catalog, or default to first
    final hasCity = PhTerritoryCatalog.cities.any(
      (c) => c.city == _selectedCity,
    );
    if (!hasCity) {
      _selectedCity = PhTerritoryCatalog.cities.first.city;
    }

    final cityEntry = PhTerritoryCatalog.cities.firstWhere(
      (c) => c.city == _selectedCity,
    );
    if (!cityEntry.barangays.contains(_selectedBarangay)) {
      _selectedBarangay = cityEntry.barangays.first;
    }
  }

  PhCityTerritory get _currentCityEntry {
    return PhTerritoryCatalog.cities.firstWhere(
      (c) => c.city == _selectedCity,
      orElse: () => PhTerritoryCatalog.cities.first,
    );
  }

  Future<void> _handleGpsDetect() async {
    setState(() => _isDetecting = true);
    final detected = await TerritoryServiceImpl.instance.detectFromGps();
    if (!mounted) return;

    setState(() {
      _isDetecting = false;
      _selectedCity = detected.city;
      _selectedBarangay = detected.barangay;
    });
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
      child: Column(
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
                      'Your primary competitive ladder and neighborhood pool',
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
          const SizedBox(height: 18),
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
                  ? 'Detecting GPS...'
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
          const SizedBox(height: 16),
          // City Picker
          const Text(
            'City / Municipality',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
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
                value: _selectedCity,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                items: PhTerritoryCatalog.cities.map((c) {
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
                      final newEntry = PhTerritoryCatalog.cities.firstWhere(
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
          // Barangay Picker
          const Text(
            'Barangay (Neighborhood)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
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
                value: _selectedBarangay,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                items: cityEntry.barangays.map((b) {
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
