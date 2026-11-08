import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../core/services/data_purge_service.dart';
import '../../../../core/theme/calico_theme_controller.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../../achievements/data/repositories/achievements_repository_impl.dart';
import '../../../achievements/domain/entities/achievement_tier.dart';
import '../../../achievements/domain/entities/explorer_title.dart';
import '../../../achievements/presentation/pages/achievements_page.dart';
import '../../../achievements/presentation/widgets/equipped_title_badge.dart';
import '../../../achievements/presentation/widgets/title_selection_sheet.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../health/services/explorer_health_service.dart';
import '../../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../../scanner/presentation/widgets/ai_vision_settings_sheet.dart';
import '../../../seasons/data/services/season_service_impl.dart';
import '../../../showcase/presentation/widgets/explorer_showcase_sheet.dart';
import '../../../showcase/services/showcase_service.dart';
import '../../../subscription/data/services/subscription_service_impl.dart';
import '../../../subscription/domain/entities/subscription_tier.dart';
import '../../../subscription/presentation/widgets/feline_club_paywall_sheet.dart';
import '../../../territory/data/services/territory_service_impl.dart';
import '../../../events/presentation/widgets/active_events_carousel.dart';
import '../../../events/presentation/widgets/profile_border_avatar.dart';
import '../../../territory/domain/entities/explorer_territory.dart';
import '../../../territory/domain/services/territory_service.dart';
import '../../../territory/presentation/widgets/territory_selection_sheet.dart';
import '../../../vault/data/services/photo_vault_service_impl.dart';
import '../../../vault/presentation/pages/raw_photo_vault_page.dart';

class DashboardPage extends StatefulWidget {
  final AuthUser user;
  final AuthRepository authRepository;
  final VoidCallback? onOpenMap;
  final TerritoryService? territoryService;

  const DashboardPage({
    super.key,
    required this.user,
    required this.authRepository,
    this.onOpenMap,
    this.territoryService,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoggingOut = false;
  bool _isPublicShowcase = true;
  bool _isAutoDetectingTerritory = false;

  TerritoryService get _territoryService =>
      widget.territoryService ?? TerritoryServiceImpl.instance;

  @override
  void initState() {
    super.initState();
    ExplorerHealthService.instance.start();
    _isPublicShowcase = ShowcaseService.instance.isPublicShowcaseEnabled;
    _runAutoTerritorySync(showSpinner: false);
  }

  Future<void> _runAutoTerritorySync({bool showSpinner = false}) async {
    final userId = widget.user.id.isNotEmpty
        ? widget.user.id
        : widget.user.email;
    if (userId.isEmpty) return;

    if (showSpinner && mounted) {
      setState(() => _isAutoDetectingTerritory = true);
    }
    try {
      await _territoryService.autoDetectAndSync(userId);
    } catch (_) {}
    if (showSpinner && mounted) {
      setState(() => _isAutoDetectingTerritory = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.authRepository.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _handlePurgeTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dynamicSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.dynamicBorder),
        ),
        title: Text(
          'Purge Test & Persistent Data?',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will wipe all local test sightings, mock stories, test photo vault entries, and persistent cache keys.\n\nMock seed injection will be disabled so you can deploy cleanly with zero test residues.',
          style: TextStyle(color: AppColors.dynamicTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.dynamicTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: const Text('Purge Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final report = await DataPurgeService.purgeAllTestDataAndCache(
      disableTestSeeds: true,
    );
    FirebaseSightingsDataSource.instance.clearTestData();
    PhotoVaultServiceImpl.instance.clearTestData();
    SubscriptionServiceImpl.instance.clearTestData();

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'Clean slate activated: cleared ${report.clearedKeysCount} persistent cache keys. Ready for deployment.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        : widget.user.email.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          'Explorer Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _isLoggingOut ? null : _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dynamicBorder),
                ),
                child: Row(
                  children: [
                    ProfileBorderAvatar(
                      userId: widget.user.id.isNotEmpty
                          ? widget.user.id
                          : widget.user.email,
                      radius: 28,
                      child: FelineAvatar(
                        photoUrl: widget.user.photoUrl,
                        seed: displayName,
                        radius: 28,
                        showBorder: true,
                        borderColor: AppColors.primary.withAlpha(50),
                        borderWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dynamicTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.dynamicTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<ExplorerTitle?>(
                            stream: AchievementsRepositoryImpl.instance
                                .watchEquippedTitle(
                                  widget.user.id.isNotEmpty
                                      ? widget.user.id
                                      : widget.user.email,
                                ),
                            builder: (context, snapshot) {
                              final equipped =
                                  snapshot.data ??
                                  const ExplorerTitle(
                                    id: 'title_novice_scout',
                                    name: 'Novice Scout',
                                    description: 'Default title',
                                    rarity: TitleRarity.common,
                                    tier: AchievementTier.bronze,
                                  );
                              return EquippedTitleBadge(
                                title: equipped,
                                onTap: () => TitleSelectionSheet.show(
                                  context,
                                  userId: widget.user.id.isNotEmpty
                                      ? widget.user.id
                                      : widget.user.email,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              StreamBuilder<ExplorerTerritory>(
                stream: _territoryService.watchTerritory(
                  widget.user.id.isNotEmpty
                      ? widget.user.id
                      : widget.user.email,
                ),
                initialData: ExplorerTerritory.defaultTerritory,
                builder: (context, snapshot) {
                  final territory =
                      snapshot.data ?? ExplorerTerritory.defaultTerritory;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                                userId: widget.user.id.isNotEmpty
                                    ? widget.user.id
                                    : widget.user.email,
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
                          onPressed: _isAutoDetectingTerritory
                              ? null
                              : () => _runAutoTerritorySync(showSpinner: true),
                          icon: _isAutoDetectingTerritory
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
                            _isAutoDetectingTerritory
                                ? 'Syncing...'
                                : 'Auto-Sync',
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
              ),
              const SizedBox(height: 12),
              StreamBuilder<SubscriptionStatus>(
                stream: SubscriptionServiceImpl.instance.watchSubscription(
                  widget.user.id.isNotEmpty
                      ? widget.user.id
                      : widget.user.email,
                ),
                initialData: SubscriptionStatus.free(
                  widget.user.id.isNotEmpty
                      ? widget.user.id
                      : widget.user.email,
                ),
                builder: (context, snapshot) {
                  final status =
                      snapshot.data ??
                      SubscriptionStatus.free(
                        widget.user.id.isNotEmpty
                            ? widget.user.id
                            : widget.user.email,
                      );
                  final isClub = status.isClubMember;
                  final isLight = CalicoThemeController.instance.isCalicoLight;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isClub
                          ? (isLight
                                ? const Color(0xFFFFF8E1)
                                : const Color(0xFF2C2216))
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
                            color: isClub
                                ? const Color(0xFFE65100)
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isClub
                                    ? 'Feline Club Member'
                                    : 'Feline Club Membership',
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
                            FelineClubPaywallSheet.show(
                              context,
                              userId: widget.user.id.isNotEmpty
                                  ? widget.user.id
                                  : widget.user.email,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: isClub
                                  ? const Color(0xFFFF8F00)
                                  : AppColors.primary,
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
                              color: isClub
                                  ? const Color(0xFFE65100)
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              ActiveEventsCarousel(
                userId: widget.user.id.isNotEmpty
                    ? widget.user.id
                    : widget.user.email,
                userDisplayName: displayName,
                userPhotoUrl: widget.user.photoUrl,
              ),
              const SizedBox(height: 18),
              Text(
                'Explorer Stats',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<ExplorerHealthSnapshot>(
                stream: ExplorerHealthService.instance.stream,
                initialData: ExplorerHealthService.instance.latest,
                builder: (context, snapshot) {
                  final health =
                      snapshot.data ?? ExplorerHealthSnapshot.empty();
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Steps',
                          value: '${health.stepsToday}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Distance',
                          value: '${health.distanceKm.toStringAsFixed(2)} km',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Calories',
                          value:
                              '${health.caloriesBurned.toStringAsFixed(0)} kcal',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<int>(
                stream: SeasonServiceImpl.instance.watchMythicPrestige(
                  widget.user.id.isNotEmpty
                      ? widget.user.id
                      : widget.user.email,
                ),
                initialData: 0,
                builder: (context, snapshot) {
                  final prestige = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFB300).withAlpha(120),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 22,
                          color: Color(0xFFFFA000),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lifetime Mythic Prestige',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      CalicoThemeController
                                          .instance
                                          .isCalicoLight
                                      ? const Color(0xFFE65100)
                                      : const Color(0xFFFFD54F),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$prestige Points',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dynamicTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Archived prestige',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
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
                            await CalicoThemeController.instance.setMode(
                              newMode,
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Explorer Hardware & Tools',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _ModuleTile(
                icon: Icons.photo_library_outlined,
                title: 'RAW Photo Vault',
                subtitle: 'Uncompressed master cat photographs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RawPhotoVaultPage(
                        userId: widget.user.id.isNotEmpty
                            ? widget.user.id
                            : widget.user.email,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModuleTile(
                icon: Icons.military_tech_outlined,
                title: 'Achievements & Titles',
                subtitle: '100 tiered bronze, silver & gold milestones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AchievementsPage(
                        userId: widget.user.id.isNotEmpty
                            ? widget.user.id
                            : widget.user.email,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
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
                                  userId: widget.user.id.isNotEmpty
                                      ? widget.user.id
                                      : widget.user.email,
                                  displayName: displayName,
                                  avatarUrl: widget.user.photoUrl,
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
                    const Divider(height: 24, color: AppColors.border),
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
                                _isPublicShowcase
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
                          value: _isPublicShowcase,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) async {
                            await ShowcaseService.instance
                                .setPublicShowcaseEnabled(val);
                            if (mounted) {
                              setState(() => _isPublicShowcase = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.user.isAdmin) ...[
                const SizedBox(height: 24),
                Text(
                  'Admin Management',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _ModuleTile(
                  icon: Icons.psychology_outlined,
                  title: 'AI Vision Engine (Admin)',
                  subtitle: 'Configure vision classifier API keys',
                  onTap: () => AiVisionSettingsSheet.show(context),
                ),
                const SizedBox(height: 10),
                _ModuleTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Purge Offline & Test Cache',
                  subtitle: 'Clear local persistent caches and sync fresh with Firebase',
                  onTap: _handlePurgeTestData,
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: 'Sign Out',
                isOutlined: true,
                isLoading: _isLoggingOut,
                icon: Icon(
                  Icons.logout,
                  size: 18,
                  color: AppColors.dynamicTextPrimary,
                ),
                onPressed: _handleSignOut,
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Poke: Iring ${AppVersion.badgeDisplay}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dynamicTextSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppVersion.buildSubtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.dynamicTextSecondary.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.dynamicTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dynamicSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.dynamicBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.dynamicTextSecondary),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.dynamicTextSecondary,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
