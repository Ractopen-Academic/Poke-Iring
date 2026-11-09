import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../subscription/data/services/subscription_service_impl.dart';
import '../../../subscription/domain/entities/subscription_tier.dart';
import '../../../subscription/presentation/widgets/feline_club_paywall_sheet.dart';

/// Card showing Feline Club membership status and upgrade/management action.
class DashboardFelineClubCard extends StatelessWidget {
  final String userId;

  const DashboardFelineClubCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionStatus>(
      stream: SubscriptionServiceImpl.instance.watchSubscription(userId),
      initialData: SubscriptionStatus.free(userId),
      builder: (context, snapshot) {
        final status = snapshot.data ?? SubscriptionStatus.free(userId);
        final isClub = status.isClubMember;
        final isLight = CalicoThemeController.instance.isCalicoLight;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isClub
                ? (isLight ? const Color(0xFFFFF8E1) : const Color(0xFF2C2216))
                : AppColors.dynamicSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isClub
                  ? (isLight
                        ? const Color(0xFFFFA000)
                        : const Color(0xFFFFB300))
                  : AppColors.dynamicBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isClub
                      ? const Color(0xFFFF8F00).withAlpha(30)
                      : AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isClub
                      ? Icons.workspace_premium_rounded
                      : Icons.card_membership_rounded,
                  size: 20,
                  color: isClub ? const Color(0xFFE65100) : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClub ? 'Feline Club Member' : 'Feline Club Membership',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isClub
                            ? (isLight
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFFFFD54F))
                            : AppColors.dynamicTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isClub
                          ? 'RAW Photo Vault Unlocked • Auto-renews'
                          : 'Unlock uncompressed RAW photo vault archiving',
                      style: TextStyle(
                        fontSize: 11,
                        color: isClub
                            ? (isLight
                                  ? const Color(0xFF8D6E63)
                                  : const Color(0xFFFFE082))
                            : AppColors.dynamicTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  FelineClubPaywallSheet.show(context, userId: userId);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: isClub ? const Color(0xFFFF8F00) : AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isClub ? 'Manage' : 'Upgrade',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isClub ? const Color(0xFFE65100) : AppColors.primary,
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
