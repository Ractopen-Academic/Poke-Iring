import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/calico_theme_controller.dart';

/// Horizontal color-swatch palette selector for feline coat themes.
class DashboardCoatThemeCard extends StatelessWidget {
  final VoidCallback onThemeChanged;

  const DashboardCoatThemeCard({super.key, required this.onThemeChanged});

  List<Color> _swatchColors(CalicoCoatMode mode) {
    return switch (mode) {
      CalicoCoatMode.calicoDark => const [
        Color(0xFF141416),
        Color(0xFFE06D22),
        Color(0xFFEFE8DE),
      ],
      CalicoCoatMode.calicoLight => const [
        Color(0xFFFAF6F0),
        Color(0xFFD9681E),
        Color(0xFF3D2619),
      ],
      CalicoCoatMode.calicoPink => const [
        Color(0xFFFFF0F5),
        Color(0xFFE24B76),
        Color(0xFF4A1525),
      ],
      CalicoCoatMode.calicoWhite => const [
        Color(0xFFFFFFFF),
        Color(0xFFFF8C1A),
        Color(0xFF212121),
      ],
      CalicoCoatMode.system => const [
        Color(0xFF78909C),
        Color(0xFFFF8C1A),
        Color(0xFF1E1E1E),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = CalicoThemeController.instance.mode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Coat Mode (Theme)',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
            Text(
              currentMode.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: CalicoCoatMode.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final mode = CalicoCoatMode.values[index];
              final isSelected = mode == currentMode;
              final swatches = _swatchColors(mode);

              return InkWell(
                onTap: () async {
                  if (mode == currentMode) return;
                  await CalicoThemeController.instance.setMode(mode);
                  onThemeChanged();
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.dynamicSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.dynamicBorder,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tri-tone color swatch preview dots
                      SizedBox(
                        height: 24,
                        width: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: swatches[0],
                                  border: Border.all(
                                    color: Colors.white.withAlpha(120),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: swatches[1],
                                  border: Border.all(
                                    color: Colors.white.withAlpha(120),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 32,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: swatches[2],
                                  border: Border.all(
                                    color: Colors.white.withAlpha(120),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mode.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.dynamicTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
