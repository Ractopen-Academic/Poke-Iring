import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../showcase/presentation/widgets/explorer_showcase_sheet.dart';
import '../../../showcase/services/showcase_service.dart';

/// Card managing pinned Dex cards in public/private player showcase.
class DashboardShowcaseCard extends StatelessWidget {
  final AuthUser user;
  final bool isPublicShowcase;
  final ValueChanged<bool> onPrivacyToggled;

  const DashboardShowcaseCard({
    super.key,
    required this.user,
    required this.isPublicShowcase,
    required this.onPrivacyToggled,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.email.split('@').first;
    final userId = user.id.isNotEmpty ? user.id : user.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Explorer Showcase & Privacy',
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
                      Icons.auto_awesome_motion_outlined,
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
                          'My Explorer Showcase',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ShowcaseService.instance.pinnedCount} of 9 slots pinned from Dex',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final profile = await ShowcaseService.instance
                          .getProfileForUser(
                            userId: userId,
                            displayName: displayName,
                            avatarUrl: user.photoUrl,
                          );
                      if (context.mounted) {
                        ExplorerShowcaseSheet.show(context, profile);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: AppColors.dynamicBorder),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Public Profile Showcase',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPublicShowcase
                              ? 'Visible to other players on leaderboards'
                              : 'Hidden from other explorers',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isPublicShowcase,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      await ShowcaseService.instance.setPublicShowcaseEnabled(
                        val,
                      );
                      onPrivacyToggled(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
