import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/cat_sighting.dart';

class CatSightingDetailSheet extends StatefulWidget {
  final CatSighting sighting;
  final String currentUserId;
  final VoidCallback onBoop;

  const CatSightingDetailSheet({
    super.key,
    required this.sighting,
    required this.currentUserId,
    required this.onBoop,
  });

  static Future<void> show({
    required BuildContext context,
    required CatSighting sighting,
    required String currentUserId,
    required VoidCallback onBoop,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CatSightingDetailSheet(
        sighting: sighting,
        currentUserId: currentUserId,
        onBoop: onBoop,
      ),
    );
  }

  @override
  State<CatSightingDetailSheet> createState() => _CatSightingDetailSheetState();
}

class _CatSightingDetailSheetState extends State<CatSightingDetailSheet> {
  late int _boopsCount;
  late bool _hasBooped;

  @override
  void initState() {
    super.initState();
    _boopsCount = widget.sighting.boopsCount;
    _hasBooped = widget.sighting.boopedBy.contains(widget.currentUserId);
  }

  void _handleBoop() {
    if (_hasBooped) return;
    setState(() {
      _boopsCount++;
      _hasBooped = true;
    });
    widget.onBoop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(
          'Booped! +5 community points awarded to ${widget.sighting.authorName}.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(25),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.sighting.stickerUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.sighting.stickerUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.pets,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.pets,
                          color: AppColors.primary,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sighting.breed,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Spotted by ${widget.sighting.authorName} • +${widget.sighting.pawPoints} pts',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.sighting.barangay}, ${widget.sighting.city}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.sighting.quirk.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${widget.sighting.quirk}"',
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _hasBooped ? null : _handleBoop,
            icon: Icon(
              _hasBooped ? Icons.favorite : Icons.favorite_border_rounded,
              size: 20,
            ),
            label: Text(
              _hasBooped
                  ? 'Booped ($_boopsCount)'
                  : 'Boop this Cat! ($_boopsCount)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
