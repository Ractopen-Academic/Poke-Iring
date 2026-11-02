import 'package:flutter/material.dart';

import '../../../../core/theme/girly_theme.dart';
import '../../domain/entities/explorer_title.dart';

class EquippedTitleBadge extends StatelessWidget {
  final ExplorerTitle title;
  final VoidCallback? onTap;
  final bool isInteractive;

  const EquippedTitleBadge({
    super.key,
    required this.title,
    this.onTap,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final tier = title.tier;
    final isGirly = GirlyThemeProvider.isGirly(context);
    final backgroundColor =
        isGirly ? GirlyColors.primaryLight : tier.backgroundColor;
    final borderColor = isGirly ? GirlyColors.border : tier.borderColor;
    final accentColor = isGirly ? GirlyColors.primaryDark : tier.primaryColor;
    final textColor = isGirly ? GirlyColors.textPrimary : tier.secondaryColor;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
          if (isInteractive && onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.unfold_more_rounded,
              size: 14,
              color: textColor,
            ),
          ],
        ],
      ),
    );

    if (isInteractive && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return badge;
  }
}
