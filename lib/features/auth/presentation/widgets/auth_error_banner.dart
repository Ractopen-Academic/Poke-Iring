import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Semantic alert banner displaying authentication errors.
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.isCalicoLight
            ? const Color(0xFFFEE2E2)
            : const Color(0xFF2A1515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.isCalicoLight
              ? const Color(0xFFFCA5A5)
              : const Color(0xFF7F2323),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.isCalicoLight
                ? const Color(0xFFDC2626)
                : const Color(0xFFF87171),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.isCalicoLight
                    ? const Color(0xFF991B1B)
                    : const Color(0xFFFCA5A5),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
