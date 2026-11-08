import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../territory/domain/entities/explorer_territory.dart';
import '../../../territory/domain/services/territory_service.dart';
import '../../../territory/presentation/widgets/territory_selection_sheet.dart';

/// Card displaying active territory, GPS verification status, and manual/auto-sync actions.
class DashboardTerritoryCard extends StatelessWidget {
  final String userId;
  final TerritoryService territoryService;
  final bool isAutoDetecting;
  final VoidCallback onAutoSync;

  const DashboardTerritoryCard({
    super.key,
    required this.userId,
    required this.territoryService,
    required this.isAutoDetecting,
    required this.onAutoSync,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ExplorerTerritory>(
      stream: territoryService.watchTerritory(userId),
      initialData: ExplorerTerritory.defaultTerritory,
      builder: (context, snapshot) {
        final territory = snapshot.data ?? ExplorerTerritory.defaultTerritory;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dynamicBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: () {
                    TerritorySelectionSheet.show(
                      context,
                      userId: userId,
                      currentTerritory: territory,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Active Territory',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dynamicTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: territory.isHomeConfirmed
                                  ? const Color(0xFF13361E)
                                  : const Color(0xFF332011),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: territory.isHomeConfirmed
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF92400E),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              territory.isHomeConfirmed
                                  ? 'GPS Verified'
                                  : 'Default Area',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: territory.isHomeConfirmed
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFDBA74),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${territory.barangay}, ${territory.city}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dynamicTextPrimary,
                        ),
                      ),
                      Text(
                        '${territory.province}, ${territory.country}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.dynamicTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: isAutoDetecting ? null : onAutoSync,
                icon: isAutoDetecting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                label: Text(
                  isAutoDetecting ? 'Syncing...' : 'Auto-Sync',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
