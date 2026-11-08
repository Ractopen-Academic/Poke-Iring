import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Segmented tab switcher between Sign In and Sign Up modes.
class AuthModeSelector extends StatelessWidget {
  final bool isSignUp;
  final ValueChanged<bool> onModeChanged;

  const AuthModeSelector({
    super.key,
    required this.isSignUp,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.dynamicChromeTrack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeSegment(
              label: 'Sign In',
              isSelected: !isSignUp,
              onTap: () => onModeChanged(false),
            ),
          ),
          Expanded(
            child: _AuthModeSegment(
              label: 'Sign Up',
              isSelected: isSignUp,
              onTap: () => onModeChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthModeSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.dynamicTextSecondary,
          ),
        ),
      ),
    );
  }
}
