import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../../rewards/services/rewards_service.dart';

class ReyalOrPakeGamePage extends StatefulWidget {
  final AuthUser user;

  const ReyalOrPakeGamePage({super.key, required this.user});

  static Future<void> navigate(BuildContext context, {required AuthUser user}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReyalOrPakeGamePage(user: user),
      ),
    );
  }

  @override
  State<ReyalOrPakeGamePage> createState() => _ReyalOrPakeGamePageState();
}

class _ReyalOrPakeGamePageState extends State<ReyalOrPakeGamePage> {
  final FirebaseSightingsDataSource _datasource =
      FirebaseSightingsDataSource.instance;
  final PageController _pageController = PageController(viewportFraction: 0.92);

  final Set<String> _votedSightingIds = {};
  final Set<String> _votedImageUrls = {};
  final Set<String> _votedFingerprints = {};
  int _sessionEarnedPoints = 0;

  // Multi-attribute audit quiz state
  String? _selectedBreed;
  String? _selectedPattern;
  String? _selectedColor;
  bool _isInspectingDetails = false;

  static const List<String> _breedOptions = [
    'Uncategorized',
    'Domestic Shorthair (Puspin)',
    'Siamese',
    'Persian',
    'British Shorthair',
    'Bengal',
    'Scottish Fold',
    'Other',
  ];

  static const List<String> _patternOptions = [
    'Tabby',
    'Calico',
    'Tuxedo',
    'Tortoiseshell',
    'Solid',
    'Bicolor',
    'Colorpoint',
  ];

  static const List<String> _colorOptions = [
    'Orange / Marmalade',
    'Black / Obsidian',
    'White / Cream',
    'Tricolor',
    'Gray / Blue',
    'Brown',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _submitPakeVote(CatSighting sighting) async {
    final userId =
        widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

    setState(() {
      _votedSightingIds.add(sighting.id);
      if (sighting.photoUrl.isNotEmpty) _votedImageUrls.add(sighting.photoUrl);
      if (sighting.imageFingerprint.isNotEmpty) {
        _votedFingerprints.add(sighting.imageFingerprint);
      }
      _sessionEarnedPoints += 5;
    });

    try {
      final earned = await _datasource.voteSightingAudit(
        sightingId: sighting.id,
        userId: userId,
        isCat: false,
      );

      await RewardsService.instance.addPoints(
        userId,
        earned,
        'Reyal or Pake: Flagged Pake',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$earned Paw Points! Voted Pake (Fake/Not a Cat).'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        _advanceToNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _submitReyalAudit(CatSighting sighting) async {
    final userId =
        widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

    final breedGuess = _selectedBreed ?? 'Uncategorized';
    final patternGuess = _selectedPattern ?? '';
    final colorGuess = _selectedColor ?? '';

    try {
      final earned = await _datasource.voteSightingAudit(
        sightingId: sighting.id,
        userId: userId,
        isCat: true,
        guessedBreed: breedGuess,
        guessedPattern: patternGuess,
        guessedColor: colorGuess,
      );

      setState(() {
        _votedSightingIds.add(sighting.id);
        if (sighting.photoUrl.isNotEmpty) _votedImageUrls.add(sighting.photoUrl);
        if (sighting.imageFingerprint.isNotEmpty) {
          _votedFingerprints.add(sighting.imageFingerprint);
        }
        _sessionEarnedPoints += earned;
        _isInspectingDetails = false;
        _selectedBreed = null;
        _selectedPattern = null;
        _selectedColor = null;
      });

      await RewardsService.instance.addPoints(
        userId,
        earned,
        'Reyal or Pake: Reyal Audit Match',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              earned >= 18
                  ? 'FLAWLESS MATCH! +$earned Paw Points awarded.'
                  : '+$earned Paw Points! Verification recorded.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: earned >= 15 ? Colors.green.shade800 : AppColors.primary,
          ),
        );
        _advanceToNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _advanceToNext() {
    setState(() {
      _isInspectingDetails = false;
      _selectedBreed = null;
      _selectedPattern = null;
      _selectedColor = null;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Reyal or Pake?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                color: AppColors.dynamicTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Stage 2 Human Verification Arena',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.dynamicTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '+$_sessionEarnedPoints pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI checked first, now you confirm! Vote Reyal for real cats or Pake for fake/non-cats to earn +15 Paw Points each.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<CatSighting>>(
                stream: _datasource.watchNearbySightings(
                  latitude: 10.3155,
                  longitude: 123.9730,
                  radiusKm: 20.0,
                ),
                builder: (context, snapshot) {
                  final allSightings = snapshot.data ?? [];
                  final filtered = allSightings.where((s) {
                    if (s.photoUrl.isEmpty) return false;
                    if (s.isPastCommunityLifespan) return false;
                    if (s.userId == userId) return false;
                    if (s.verifiedByUsers.contains(userId) ||
                        s.rejectedByUsers.contains(userId)) {
                      return false;
                    }
                    if (_votedSightingIds.contains(s.id) ||
                        _votedImageUrls.contains(s.photoUrl)) {
                      return false;
                    }
                    if (s.imageFingerprint.isNotEmpty &&
                        _votedFingerprints.contains(s.imageFingerprint)) {
                      return false;
                    }
                    return true;
                  }).toList();

                  // Deduplicate by photoUrl/fingerprint so identical images are not repeated
                  final seenImages = <String>{};
                  final candidates = <CatSighting>[];
                  for (final s in filtered) {
                    final key = s.imageFingerprint.isNotEmpty
                        ? s.imageFingerprint
                        : s.photoUrl;
                    if (!seenImages.contains(key)) {
                      seenImages.add(key);
                      candidates.add(s);
                    }
                  }

                  if (candidates.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 48,
                              color: AppColors.primary.withAlpha(120),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No community sightings to audit right now.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dynamicTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Take a cat photo with your camera to submit new entries!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.dynamicTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return PageView.builder(
                    controller: _pageController,
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final sighting = candidates[index];
                      final alreadyVoted =
                          _votedSightingIds.contains(sighting.id) ||
                              sighting.verifiedByUsers.contains(userId) ||
                              sighting.rejectedByUsers.contains(userId);

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.dynamicSurface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(45),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                            child: sighting.photoUrl
                                                    .startsWith('data:image')
                                                ? Image.memory(
                                                    Uri.parse(sighting.photoUrl)
                                                        .data!
                                                        .contentAsBytes(),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) =>
                                                        _errorPlaceholder(),
                                                  )
                                                : Image.network(
                                                    sighting.photoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) =>
                                                        _errorPlaceholder(),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 14,
                                          left: 14,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withAlpha(165),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.auto_awesome,
                                                  color: Colors.amber,
                                                  size: 13,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'AI Stage 1: ${(sighting.aiConfidence * 100).round()}% match',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 14,
                                          right: 14,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withAlpha(165),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${index + 1} / ${candidates.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sighting.breed,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors
                                                          .dynamicTextPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${sighting.coatPattern} · Spotted by ${sighting.authorName}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .dynamicTextSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${sighting.humanUpvotes} Reyal',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        if (alreadyVoted)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.dynamicChromeTrack,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'You already verified this photo',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors
                                                    .dynamicTextSecondary,
                                              ),
                                            ),
                                          )
                                        else if (_isInspectingDetails)
                                          _buildAttributeAuditSection(sighting)
                                        else
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.red.shade600,
                                                    side: BorderSide(
                                                      color:
                                                          Colors.red.shade400,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () => _submitPakeVote(
                                                    sighting,
                                                  ),
                                                  icon: const Icon(
                                                      Icons.close_rounded,
                                                      size: 18),
                                                  label: const Text(
                                                    'Pake (+5 pts)',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        Colors.green.shade700,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _isInspectingDetails = true;
                                                      _selectedBreed = 'Uncategorized';
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.verified_rounded,
                                                      size: 18),
                                                  label: const Text(
                                                    'Reyal (Inspect)',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeAuditSection(CatSighting sighting) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audit Feline Attributes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
              Text(
                'Up to +20 pts',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Breed Selection Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedBreed ?? 'Uncategorized',
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Breed Category',
              labelStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _breedOptions.map((b) {
              return DropdownMenuItem<String>(
                value: b,
                child: Text(b, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedBreed = val),
          ),
          const SizedBox(height: 8),

          // Pattern Selection Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedPattern,
            hint: const Text('Coat Pattern (optional +5 pts)', style: TextStyle(fontSize: 12)),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Coat Pattern',
              labelStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _patternOptions.map((p) {
              return DropdownMenuItem<String>(
                value: p,
                child: Text(p, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedPattern = val),
          ),
          const SizedBox(height: 8),

          // Color Selection Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedColor,
            hint: const Text('Dominant Color (optional +3 pts)', style: TextStyle(fontSize: 12)),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Dominant Color',
              labelStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _colorOptions.map((c) {
              return DropdownMenuItem<String>(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedColor = val),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _isInspectingDetails = false),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _submitReyalAudit(sighting),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Submit Audit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: AppColors.primary.withAlpha(30),
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        size: 54,
        color: AppColors.primary,
      ),
    );
  }
}
