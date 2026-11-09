import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_version.dart';

/// Discreet version badge indicator placed at the bottom-left corner of pre-auth,
/// loading, and connection/lockout screens.
class AppVersionBadge extends StatelessWidget {
  const AppVersionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.dynamicChromeTrack.withAlpha(180),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: AppColors.dynamicBorder.withAlpha(140),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          AppVersion.releaseTag,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.dynamicTextSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
