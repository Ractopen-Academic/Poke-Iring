import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_version.dart';
import '../../../../core/services/apk_download_service.dart';
import '../../../../core/services/app_cache_coordinator.dart';
import '../../../../core/services/data_purge_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../achievements/presentation/pages/achievements_page.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../map/presentation/widgets/offline_map_download_dialog.dart';
import '../../../map/presentation/widgets/tile_caching_sheet.dart';
import '../../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../../scanner/presentation/widgets/ai_vision_settings_sheet.dart';
import '../../../territory/data/services/territory_service_impl.dart';
import '../../../territory/domain/services/territory_service.dart';
import 'main_navigation_shell.dart';
import '../widgets/dashboard_coat_theme_card.dart';
import '../widgets/dashboard_profile_card.dart';
import '../widgets/dashboard_territory_card.dart';

/// Tabbed Hub for the Explorer Account: Overview & Settings.
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
  int _selectedTab = 0; // 0 = Overview, 1 = Settings
  int _devTapCount = 0;
  bool _isDeveloperUnlocked = false;

  bool _isLoggingOut = false;
  late final TerritoryService _territoryService;
  bool _isAutoDetectingTerritory = false;

  @override
  void initState() {
    super.initState();
    _territoryService =
        widget.territoryService ?? TerritoryServiceImpl.instance;
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
      MainNavigationShell.resetSession();
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dynamicSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.dynamicBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.pets, size: 22, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'About Poke: Iring',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A real-world feline exploration and discovery game for mobile explorers.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.dynamicTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _buildAboutMetaRow('Build Tag', AppVersion.releaseTag),
            const SizedBox(height: 6),
            _buildAboutMetaRow('Version', AppVersion.semanticVersion),
            const SizedBox(height: 6),
            _buildAboutMetaRow('Stage', AppVersion.stage),
            const SizedBox(height: 6),
            _buildAboutMetaRow('Build Date', AppVersion.buildDate),
            const SizedBox(height: 6),
            _buildAboutMetaRow('Architecture', 'Online-First • Zero Fallback'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showDownloadApkDialog();
            },
            icon: const Icon(Icons.android_rounded, size: 16),
            label: const Text(
              'Download APK',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDirectApkDownload([AndroidApkTarget? target]) async {
    final targetUrl = target?.downloadUrl ?? AppVersion.devApkDownloadUrl;
    final label = target != null ? '${target.label} ' : '';
    final opened = await ApkDownloadService.instance.downloadDevApk(
      customUrl: targetUrl,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(
          opened
              ? 'Downloading Poke: Iring ${label}APK (${AppVersion.releaseTag})...'
              : 'Direct APK download link copied to clipboard: $targetUrl',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showDownloadApkDialog() {
    var selectedTarget = AppVersion.apkTargets[1]; // Default to Android 14
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.dynamicSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.dynamicBorder),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.android_rounded,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Download Dev APK',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your Android version to download a dedicated 64-bit build compiled automatically by GitHub Actions.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.dynamicTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: AppVersion.apkTargets.map((target) {
                  final isSelected = selectedTarget.id == target.id;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: target.id == AppVersion.apkTargets.last.id
                            ? 0
                            : 6,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setDialogState(() => selectedTarget = target);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.dynamicChromeTrack,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.dynamicBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                target.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.dynamicTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                target.apiBadge,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white.withAlpha(220)
                                      : AppColors.dynamicTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _buildAboutMetaRow('Build Tag', AppVersion.releaseTag),
              const SizedBox(height: 6),
              _buildAboutMetaRow('Target ABI', selectedTarget.subtitle),
              const SizedBox(height: 6),
              _buildAboutMetaRow('Channel', 'GitHub Actions Dev Release'),
              const SizedBox(height: 6),
              _buildAboutMetaRow('Data Sync', 'Backend Authoritative'),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withAlpha(55)),
                ),
                child: SelectableText(
                  selectedTarget.downloadUrl,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ApkDownloadService.instance.copyTargetLink(
                  selectedTarget,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryDark,
                      content: Text(
                        '${selectedTarget.label} APK download URL copied to clipboard.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Copy Link',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.dynamicTextSecondary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _handleDirectApkDownload(selectedTarget);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(
                'Download ${selectedTarget.label}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.dynamicTextSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.id.isNotEmpty
        ? widget.user.id
        : widget.user.email;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 24.0;

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
            tooltip: 'About Poke: Iring',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showAboutDialog,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Tabbed Hub Segmented Pill Selector
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.dynamicSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dynamicBorder),
              ),
              child: Row(
                children: [
                  _buildSubTabButton(
                    index: 0,
                    title: 'Overview',
                    icon: Icons.person_pin_rounded,
                  ),
                  _buildSubTabButton(
                    index: 1,
                    title: 'Settings',
                    icon: Icons.tune_rounded,
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(scrollbars: false),
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildOverviewTab(userId, bottomPadding),
                    _buildSettingsTab(userId, bottomPadding),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppColors.dynamicTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.dynamicTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(String userId, double bottomPadding) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('dashboard_overview_scroll'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 8,
        left: 16,
        right: 16,
        bottom: bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardProfileCard(user: widget.user),
          const SizedBox(height: 12),
          DashboardTerritoryCard(
            userId: userId,
            territoryService: _territoryService,
            isAutoDetecting: _isAutoDetectingTerritory,
            onAutoSync: () => _runAutoTerritorySync(showSpinner: true),
          ),
          const SizedBox(height: 16),
          _buildHardwareSection(userId),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(String userId, double bottomPadding) {
    final showDevTools = widget.user.isAdmin || _isDeveloperUnlocked;

    return SingleChildScrollView(
      key: const PageStorageKey<String>('dashboard_settings_scroll'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: 8,
        left: 16,
        right: 16,
        bottom: bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCoatThemeCard(
            onThemeChanged: () {
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: 'Cache & Cloud Synchronization',
            children: [
              _SettingsTile(
                icon: Icons.download_for_offline_outlined,
                title: 'Download Offline Map Area',
                subtitle: 'Select crop rectangle to cache map for offline exploration',
                onTap: () async {
                  final t = await TerritoryServiceImpl.instance.getTerritory(
                    widget.user.id.isNotEmpty
                        ? widget.user.id
                        : widget.user.email,
                  );
                  final lat = t.latitude ?? 10.3140;
                  final lon = t.longitude ?? 123.9720;
                  if (!mounted) return;
                  OfflineMapDownloadDialog.show(
                    context,
                    initialCenter: LatLng(lat, lon),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.cloud_download_outlined,
                title: 'Precache Territory Map Tiles',
                subtitle: 'Pre-download map grid around your saved territory',
                onTap: () async {
                  final t = await TerritoryServiceImpl.instance.getTerritory(
                    widget.user.id.isNotEmpty
                        ? widget.user.id
                        : widget.user.email,
                  );
                  final lat = t.latitude ?? 10.3140;
                  final lon = t.longitude ?? 123.9720;
                  if (!mounted) return;
                  TileCachingSheet.show(
                    context,
                    currentCenter: LatLng(lat, lon),
                    currentZoom: 15.0,
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.sync_rounded,
                title: 'Force Cloud Recache',
                subtitle: 'Synchronize local catalogs with Firebase',
                onTap: _handleForceRecache,
              ),
              _SettingsTile(
                icon: Icons.cleaning_services_outlined,
                title: 'Purge Offline & Test Cache',
                subtitle: 'Clear persistent memory & reset test state',
                onTap: _handlePurgeTestData,
                showDivider: false,
              ),
            ],
          ),
          if (showDevTools) ...[
            const SizedBox(height: 18),
            _SettingsGroup(
              title: 'Developer & System Tools',
              children: [
                _SettingsTile(
                  icon: Icons.psychology_outlined,
                  title: 'AI Vision Engine',
                  subtitle: 'Configure vision classifier API keys',
                  onTap: () => AiVisionSettingsSheet.show(context),
                  showDivider: false,
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _SettingsGroup(
            title: 'Explorer Account',
            children: [
              _SettingsTile(
                icon: Icons.email_outlined,
                title: 'Registered Email',
                subtitle: widget.user.email,
                trailing: const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.android_rounded,
                title: 'Download Dev APK',
                subtitle:
                    'Android 13, 14 & 15+ builds (${AppVersion.releaseTag})',
                onTap: _showDownloadApkDialog,
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Poke: Iring',
                subtitle: 'Version specifications & architecture',
                onTap: _showAboutDialog,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
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
    );
  }

  Widget _buildHardwareSection(String userId) {
    return _SettingsGroup(
      title: 'Explorer Hardware & Tools',
      children: [
        if (widget.onOpenMap != null)
          _SettingsTile(
            icon: Icons.map_outlined,
            title: 'Tactical Feline Radar',
            subtitle: 'Open full-screen community cat live tracking map',
            onTap: widget.onOpenMap!,
            showDivider: true,
          ),
        _SettingsTile(
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
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildVersionFooter() {
    return Center(
      child: InkWell(
        key: const ValueKey('dashboard_dev_footer'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _devTapCount++;
          if (_devTapCount == 5) {
            setState(() => _isDeveloperUnlocked = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.primary,
                content: Text(
                  'Developer & System Diagnostics unlocked in Settings tab.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (_devTapCount > 1 && _devTapCount < 5) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 700),
                content: Text(
                  '${5 - _devTapCount} more taps to unlock developer tools',
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Text(
                'Poke: Iring ${AppVersion.badgeDisplay}',
                style: TextStyle(
                  fontSize: 11.5,
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
                  color: AppColors.dynamicTextSecondary.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.dynamicTextSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dynamicSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dynamicBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
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
                            fontWeight: FontWeight.w600,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.dynamicTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.dynamicTextSecondary.withAlpha(140),
                      ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.6,
            indent: 54,
            color: AppColors.dynamicBorder.withAlpha(100),
          ),
      ],
    );
  }
}
