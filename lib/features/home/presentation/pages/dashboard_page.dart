import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../core/services/app_cache_coordinator.dart';
import '../../../../core/services/data_purge_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../achievements/presentation/pages/achievements_page.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../../scanner/presentation/widgets/ai_vision_settings_sheet.dart';
import '../../../showcase/services/showcase_service.dart';
import '../../../subscription/data/services/subscription_service_impl.dart';
import '../../../territory/data/services/territory_service_impl.dart';
import '../../../territory/domain/services/territory_service.dart';
import '../../../vault/data/services/photo_vault_service_impl.dart';
import '../../../vault/presentation/pages/raw_photo_vault_page.dart';
import '../widgets/dashboard_coat_theme_card.dart';
import '../widgets/dashboard_feline_club_card.dart';
import '../widgets/dashboard_profile_card.dart';
import '../widgets/dashboard_showcase_card.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/dashboard_territory_card.dart';

class DashboardPage extends StatefulWidget {
  final AuthUser user;
  final AuthRepository authRepository;
  final TerritoryService? territoryService;
  final VoidCallback? onOpenMap;

  const DashboardPage({
    super.key,
    required this.user,
    required this.authRepository,
    this.territoryService,
    this.onOpenMap,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoggingOut = false;
  late final TerritoryService _territoryService;
  bool _isAutoDetectingTerritory = false;
  bool _isPublicShowcase = true;

  @override
  void initState() {
    super.initState();
    _territoryService =
        widget.territoryService ?? TerritoryServiceImpl.instance;
    _loadShowcasePrivacy();
  }

  void _loadShowcasePrivacy() {
    final enabled = ShowcaseService.instance.isPublicShowcaseEnabled;
    if (mounted) setState(() => _isPublicShowcase = enabled);
  }

  Future<void> _runAutoTerritorySync({bool showSpinner = false}) async {
    if (_isAutoDetectingTerritory) return;
    if (showSpinner) setState(() => _isAutoDetectingTerritory = true);

    try {
      final updated = await _territoryService.autoDetectAndSync(
        widget.user.id.isNotEmpty ? widget.user.id : widget.user.email,
      );

      if (mounted && updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Territory synchronized to ${updated.barangay}, ${updated.city}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Failed to auto-detect territory: $e'),
          ),
        );
      }
    } finally {
      if (mounted && showSpinner) {
        setState(() => _isAutoDetectingTerritory = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoggingOut = true);
    try {
      await widget.authRepository.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Failed to sign out: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
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

  Future<void> _handleForceRecache() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryDark,
        content: Text(
          'Synchronizing cloud catalog...',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        duration: Duration(milliseconds: 900),
      ),
    );

    final report = await AppCacheCoordinator.instance.forceRecacheAll(
      userId: widget.user.id.isNotEmpty ? widget.user.id : widget.user.email,
    );

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            report.statusSummary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.id.isNotEmpty
        ? widget.user.id
        : widget.user.email;

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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardProfileCard(user: widget.user),
              const SizedBox(height: 14),
              DashboardTerritoryCard(
                userId: userId,
                territoryService: _territoryService,
                isAutoDetecting: _isAutoDetectingTerritory,
                onAutoSync: () => _runAutoTerritorySync(showSpinner: true),
              ),
              const SizedBox(height: 12),
              DashboardFelineClubCard(userId: userId),
              const SizedBox(height: 18),
              DashboardStatsCard(userId: userId),
              const SizedBox(height: 24),
              DashboardCoatThemeCard(
                onThemeChanged: () {
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 24),
              _buildHardwareSection(userId),
              const SizedBox(height: 24),
              DashboardShowcaseCard(
                user: widget.user,
                isPublicShowcase: _isPublicShowcase,
                onPrivacyToggled: (val) {
                  if (mounted) setState(() => _isPublicShowcase = val);
                },
              ),
              if (widget.user.isAdmin) ...[
                const SizedBox(height: 24),
                _buildAdminSection(),
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
              _buildVersionFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Explorer Hardware & Tools',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.onOpenMap != null) ...[
          _ModuleTile(
            icon: Icons.map_outlined,
            title: 'Tactical Feline Radar',
            subtitle: 'Open full-screen community cat live tracking map',
            onTap: widget.onOpenMap!,
          ),
          const SizedBox(height: 10),
        ],
        _ModuleTile(
          icon: Icons.photo_library_outlined,
          title: 'RAW Photo Vault',
          subtitle: 'Uncompressed master cat photographs',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RawPhotoVaultPage(userId: userId),
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
                builder: (context) => AchievementsPage(userId: userId),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Administrator Controls',
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
          icon: Icons.sync_rounded,
          title: 'Force Cloud Recache',
          subtitle: 'Synchronize and bust local caches across all catalogs',
          onTap: _handleForceRecache,
        ),
        const SizedBox(height: 10),
        _ModuleTile(
          icon: Icons.cleaning_services_outlined,
          title: 'Purge Offline & Test Cache',
          subtitle: 'Clear local persistent caches and sync fresh with Firebase',
          onTap: _handlePurgeTestData,
        ),
      ],
    );
  }

  Widget _buildVersionFooter() {
    return Center(
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
              fontSize: 10,
              color: AppColors.dynamicTextSecondary.withAlpha(160),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dynamicTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.dynamicTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.dynamicTextSecondary.withAlpha(120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
