import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
import '../../../../core/widgets/calico_ui_kit.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../../scanner/presentation/pages/cat_scanner_page.dart';
import '../../data/repositories/dex_repository_impl.dart';
import '../../domain/entities/feline_dex_species.dart';
import '../../domain/entities/iring_dex_entry.dart';
import '../../domain/repositories/dex_repository.dart';
import '../widgets/cat_detail_sheet.dart';
import '../widgets/dex_progress_header.dart';
import '../widgets/dex_sighting_card.dart';
import '../widgets/dex_species_card.dart';
import '../widgets/personal_sighting_heatmap.dart';

enum DexViewMode { catalog, album, heatmap }

enum DexFilterTier { all, puspin, rare, mythic }

class IringDexPage extends StatefulWidget {
  final AuthUser user;
  final DexRepository? repository;

  const IringDexPage({super.key, required this.user, this.repository});

  @override
  State<IringDexPage> createState() => _IringDexPageState();
}

class _IringDexPageState extends State<IringDexPage> {
  late final DexRepository _repository;
  DexViewMode _viewMode = DexViewMode.catalog;
  DexFilterTier _selectedFilter = DexFilterTier.all;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DexRepositoryImpl();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _effectiveUserId =>
      widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

  List<IringDexEntry> _filterEntries(List<IringDexEntry> entries) {
    return entries.where((entry) {
      // Filter by tier
      if (_selectedFilter == DexFilterTier.puspin) {
        if (!entry.species.name.toLowerCase().contains('puspin') &&
            !entry.species.name.toLowerCase().contains('domestic shorthair') &&
            !entry.species.name.toLowerCase().contains('ginger') &&
            !entry.species.name.toLowerCase().contains('midnight') &&
            !entry.species.name.toLowerCase().contains('cloud')) {
          return false;
        }
      } else if (_selectedFilter == DexFilterTier.rare) {
        if (entry.species.rarity != FelineRarityTier.rare &&
            entry.species.rarity != FelineRarityTier.veryRare) {
          return false;
        }
      } else if (_selectedFilter == DexFilterTier.mythic) {
        if (entry.species.rarity != FelineRarityTier.mythic) {
          return false;
        }
      }

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchName = entry.species.name.toLowerCase().contains(query);
        final matchCommon = entry.species.commonName.toLowerCase().contains(
              query,
            );
        final matchPattern = entry.species.coatPattern.toLowerCase().contains(
              query,
            );
        return matchName || matchCommon || matchPattern;
      }

      return true;
    }).toList();
  }

  List<CatSighting> _filterSightings(List<CatSighting> sightings) {
    if (_searchQuery.trim().isEmpty) return sightings;
    final query = _searchQuery.toLowerCase().trim();
    return sightings.where((s) {
      return s.breed.toLowerCase().contains(query) ||
          s.coatPattern.toLowerCase().contains(query) ||
          s.barangay.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query);
    }).toList();
  }

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CatScannerPage(user: widget.user, autoLaunchCamera: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    return Scaffold(
      backgroundColor: isGirly ? GirlyColors.background : AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search species or pattern...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text(
                'Iring-Dex',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
        backgroundColor:
            isGirly ? GirlyColors.background : AppColors.background,
        foregroundColor:
            isGirly ? GirlyColors.textPrimary : AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close Search' : 'Search Dex',
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Snap Cat',
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: _openCamera,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<IringDexEntry>>(
          stream: _repository.watchDexEntries(_effectiveUserId),
          builder: (context, dexSnapshot) {
            final entries = dexSnapshot.data ??
                FelineDexSpecies.canonicalSpecies
                    .map((s) => IringDexEntry.undiscovered(s))
                    .toList();

            return StreamBuilder<List<CatSighting>>(
              stream: _repository.watchUserSightings(_effectiveUserId),
              builder: (context, sightingsSnapshot) {
                final sightings = sightingsSnapshot.data ?? const [];

                final filteredEntries = _filterEntries(entries);
                final filteredSightings = _filterSightings(sightings);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DexProgressHeader(entries: entries),
                            const SizedBox(height: 16),
                            _buildSegmentedTab(
                              sightings.length,
                              entries.length,
                            ),
                            if (_viewMode != DexViewMode.heatmap) ...[
                              const SizedBox(height: 12),
                              _buildFilterChips(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_viewMode == DexViewMode.catalog)
                      _buildCatalogSliver(filteredEntries)
                    else if (_viewMode == DexViewMode.album)
                      _buildAlbumSliver(filteredSightings)
                    else
                      SliverToBoxAdapter(
                        child: PersonalSightingHeatmap(
                          sightings: sightings,
                          user: widget.user,
                          onOpenScanner: _openCamera,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegmentedTab(int sightingsCount, int totalSpecies) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isGirly ? GirlyColors.navBarBg : AppColors.calicoBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              (isGirly ? GirlyColors.primary : AppColors.primary).withAlpha(55),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: 'Species Catalog',
              subtitle: '$totalSpecies Total',
              isSelected: _viewMode == DexViewMode.catalog,
              onTap: () => setState(() => _viewMode = DexViewMode.catalog),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Sightings Album',
              subtitle: '$sightingsCount Photos',
              isSelected: _viewMode == DexViewMode.album,
              onTap: () => setState(() => _viewMode = DexViewMode.album),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Heatmap',
              subtitle: '$sightingsCount Spots',
              isSelected: _viewMode == DexViewMode.heatmap,
              onTap: () => setState(() => _viewMode = DexViewMode.heatmap),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(label: 'All Species', tier: DexFilterTier.all),
          const SizedBox(width: 8),
          _filterChip(label: 'Puspin Native', tier: DexFilterTier.puspin),
          const SizedBox(width: 8),
          _filterChip(label: 'Rare Breeds', tier: DexFilterTier.rare),
          const SizedBox(width: 8),
          _filterChip(label: 'Mythic Encounters', tier: DexFilterTier.mythic),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required DexFilterTier tier}) {
    final isSelected = _selectedFilter == tier;
    final isGirly = GirlyThemeProvider.isGirly(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = tier);
      },
      backgroundColor: isGirly ? GirlyColors.surface : Colors.white,
      selectedColor: isGirly ? GirlyColors.primaryDark : AppColors.calicoBlack,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isGirly ? GirlyColors.textPrimary : AppColors.textPrimary),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(
          color: isSelected
              ? (isGirly ? GirlyColors.primaryDark : AppColors.primary)
              : (isGirly ? GirlyColors.border : AppColors.border),
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildCatalogSliver(List<IringDexEntry> filtered) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CalicoSpotCard(
            padding: EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 44,
                  color: isGirly ? GirlyColors.primaryDark : AppColors.primary,
                ),
                SizedBox(height: 12),
                Text(
                  'No matching species found',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Try selecting a different filter category.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isGirly
                        ? GirlyColors.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final entry = filtered[index];
          return DexSpeciesCard(
            entry: entry,
            onTap: () => CatDetailSheet.show(context, entry),
          );
        }, childCount: filtered.length),
      ),
    );
  }

  Widget _buildAlbumSliver(List<CatSighting> sightings) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    if (sightings.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CalicoSpotCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isGirly
                        ? GirlyColors.creamSurface
                        : AppColors.calicoBlack,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isGirly ? GirlyColors.primary : AppColors.primary)
                          .withAlpha(110),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 34,
                    color:
                        isGirly ? GirlyColors.primaryDark : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Cat Sightings Yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isGirly
                        ? GirlyColors.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore your neighborhood, snap local felines with the AI vision camera, and watch your sightings album grow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isGirly
                        ? GirlyColors.textSecondary
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                CalicoPressable(
                  child: ElevatedButton.icon(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text(
                      'Spot a Cat Now',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isGirly ? GirlyColors.primaryDark : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final sighting = sightings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DexSightingCard(
              sighting: sighting,
              onTap: () {
                final species = FelineDexSpecies.canonicalSpecies.firstWhere(
                  (s) =>
                      s.coatPattern.toLowerCase() ==
                          sighting.coatPattern.toLowerCase() ||
                      s.name.toLowerCase().contains(
                            sighting.breed.toLowerCase(),
                          ),
                  orElse: () => FelineDexSpecies.canonicalSpecies.first,
                );
                final entry = IringDexEntry.fromSightings(
                  species: species,
                  matchedSightings: [sighting],
                );
                CatDetailSheet.show(context, entry);
              },
            ),
          );
        }, childCount: sightings.length),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGirly = GirlyThemeProvider.isGirly(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isGirly ? GirlyColors.surface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isGirly ? GirlyColors.primary : AppColors.primary)
                        .withAlpha(45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            CalicoAnimatedBar(
              isActive: isSelected,
              activeWidth: 16,
              activeColor: isGirly ? GirlyColors.primaryDark : null,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isGirly
                        ? GirlyColors.textPrimary
                        : AppColors.calicoBlack)
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? (isGirly
                        ? GirlyColors.primaryDark
                        : AppColors.primaryDark)
                    : (isGirly ? GirlyColors.navMuted : AppColors.calicoMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
