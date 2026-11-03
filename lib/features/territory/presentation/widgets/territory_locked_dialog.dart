import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../domain/entities/explorer_territory.dart';

class TerritoryLockedDialog extends StatelessWidget {
  final ExplorerTerritory territory;
  final bool isAdmin;
  final VoidCallback? onAdminOverride;

  const TerritoryLockedDialog({
    super.key,
    required this.territory,
    this.isAdmin = false,
    this.onAdminOverride,
  });

  static Future<void> show(
    BuildContext context, {
    required ExplorerTerritory territory,
    bool isAdmin = false,
    VoidCallback? onAdminOverride,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => TerritoryLockedDialog(
        territory: territory,
        isAdmin: isAdmin,
        onAdminOverride: onAdminOverride,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysRemaining = territory.daysUntilChangeAvailable;
    final nextDate = territory.nextChangeDateFormatted;
    final isLight = CalicoThemeController.instance.isCalicoLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dynamicSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.dynamicBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isLight ? 30 : 90),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLight
                      ? const [Color(0xFFFBF6F0), Color(0xFFF4ECE1)]
                      : const [Color(0xFF2E241E), Color(0xFF1E1714)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.dynamicBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Color(0xFFFFB300),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Territory Locked',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Annual Seasonal Cooldown',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To protect tournament integrity and prevent district hopping during active seasons, official territories can only be modified once every 365 days.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.dynamicTextSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicFieldFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.dynamicBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Locked Division',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.dynamicTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8F00).withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          territory.shortLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        Divider(height: 18, color: AppColors.dynamicBorder),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cooldown Remaining',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.dynamicTextSecondary,
                              ),
                            ),
                            Text(
                              '$daysRemaining days',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Next Eligible Change',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.dynamicTextSecondary,
                              ),
                            ),
                            Text(
                              nextDate,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dynamicTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Understood',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isAdmin && onAdminOverride != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onAdminOverride?.call();
                          },
                          child: Text(
                            'Admin Override: Change Territory',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dynamicTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
