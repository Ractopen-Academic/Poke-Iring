import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/calico_theme_controller.dart';

/// Card for customizing app appearance and feline coat color themes.
class DashboardCoatThemeCard extends StatelessWidget {
  final VoidCallback onThemeChanged;

  const DashboardCoatThemeCard({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'App Appearance / Theme',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dynamicBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coat Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CalicoThemeController.instance.mode.description,
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dynamicFieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dynamicBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CalicoCoatMode>(
                    value: CalicoThemeController.instance.mode,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.dynamicTextSecondary,
                    ),
                    dropdownColor: AppColors.dynamicSurface,
                    borderRadius: BorderRadius.circular(16),
                    items: CalicoCoatMode.values.map((mode) {
                      final isSelected =
                          mode == CalicoThemeController.instance.mode;
                      return DropdownMenuItem<CalicoCoatMode>(
                        value: mode,
                        child: Row(
                          children: [
                            Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: mode.swatchColor,
                                border: Border.all(
                                  color: AppColors.dynamicBorder,
                                  width: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.dynamicTextPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newMode) async {
                      if (newMode == null) return;
                      await CalicoThemeController.instance.setMode(newMode);
                      onThemeChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
