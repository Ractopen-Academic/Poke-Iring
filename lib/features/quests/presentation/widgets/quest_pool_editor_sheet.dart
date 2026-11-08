import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/firebase_quest_datasource.dart';
import '../../domain/entities/paw_quest.dart';
import '../../domain/entities/quest_template.dart';

class QuestPoolEditorSheet extends StatefulWidget {
  final FirebaseQuestDataSource? dataSource;

  const QuestPoolEditorSheet({super.key, this.dataSource});

  static Future<void> show(
    BuildContext context, {
    FirebaseQuestDataSource? dataSource,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuestPoolEditorSheet(dataSource: dataSource),
    );
  }

  @override
  State<QuestPoolEditorSheet> createState() => _QuestPoolEditorSheetState();
}

class _QuestPoolEditorSheetState extends State<QuestPoolEditorSheet> {
  late final FirebaseQuestDataSource _dataSource;
  QuestCategory? _filterCategory;
  List<QuestTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.dataSource ?? FirebaseQuestDataSource.instance;
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final pool = await _dataSource.getQuestPool();
    if (mounted) {
      setState(() {
        _templates = pool;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTemplate(String id, bool active) async {
    final updated = _templates.map((t) {
      if (t.id == id) {
        return t.copyWith(isActive: active);
      }
      return t;
    }).toList();

    setState(() {
      _templates = updated;
    });

    await _dataSource.toggleTemplateActive(id, active);
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dynamicSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.dynamicBorder),
        ),
        title: Text(
          'Reset Quest Pool?',
          style: TextStyle(
            color: AppColors.dynamicTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will restore the 16 standard built-in quest templates in both local storage and Cloud Firestore.',
          style: TextStyle(color: AppColors.dynamicTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.dynamicTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await _dataSource.seedDefaultPoolIfEmpty(force: true);
      final refreshed = await _dataSource.getQuestPool();
      if (mounted) {
        setState(() {
          _templates = refreshed;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Quest pool successfully reset to default catalog.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCategory == null
        ? _templates
        : _templates.where((t) => t.category == _filterCategory).toList();

    final activeCount = _templates.where((t) => t.isActive).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.dynamicBorder, width: 1.2),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dynamicBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quest Pool Manager',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeCount of ${_templates.length} templates active in rotation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Reset to default catalog',
                icon: Icon(
                  Icons.restart_alt_rounded,
                  color: AppColors.dynamicTextSecondary,
                ),
                onPressed: _resetToDefaults,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter tabs
          Row(
            children: [
              _FilterChip(
                label: 'All (${_templates.length})',
                isSelected: _filterCategory == null,
                onTap: () => setState(() => _filterCategory = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label:
                    'Daily (${_templates.where((t) => t.category == QuestCategory.daily).length})',
                isSelected: _filterCategory == QuestCategory.daily,
                onTap: () =>
                    setState(() => _filterCategory = QuestCategory.daily),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label:
                    'Weekly (${_templates.where((t) => t.category == QuestCategory.weekly).length})',
                isSelected: _filterCategory == QuestCategory.weekly,
                onTap: () =>
                    setState(() => _filterCategory = QuestCategory.weekly),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable list of templates
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      'No quest templates found in this category.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withAlpha(180),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final template = filtered[index];
                      return _QuestTemplateCard(
                        template: template,
                        onToggleActive: (val) =>
                            _toggleTemplate(template.id, val),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.dynamicChromeTrack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dynamicBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.dynamicTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _QuestTemplateCard extends StatelessWidget {
  final QuestTemplate template;
  final ValueChanged<bool> onToggleActive;

  const _QuestTemplateCard({
    required this.template,
    required this.onToggleActive,
  });

  IconData _getTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.steps:
        return Icons.directions_walk_rounded;
      case QuestType.distance:
        return Icons.straighten_rounded;
      case QuestType.scanCat:
      case QuestType.scanBreed:
        return Icons.camera_alt_rounded;
      case QuestType.boopSightings:
        return Icons.touch_app_rounded;
      case QuestType.goldenHour:
        return Icons.wb_twilight_rounded;
    }
  }

  String _formatTarget(QuestTemplate tpl) {
    switch (tpl.type) {
      case QuestType.steps:
        return '${tpl.targetValue.toInt()} steps';
      case QuestType.distance:
        return '${tpl.targetValue.toStringAsFixed(1)} km';
      case QuestType.scanBreed:
        return tpl.targetBreed != null
            ? '${tpl.targetValue.toInt()} ${tpl.targetBreed}'
            : '${tpl.targetValue.toInt()} scans';
      case QuestType.scanCat:
        return '${tpl.targetValue.toInt()} scans';
      case QuestType.boopSightings:
        return '${tpl.targetValue.toInt()} boops';
      case QuestType.goldenHour:
        return '${tpl.targetValue.toInt()} sunset spot';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDaily = template.category == QuestCategory.daily;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: template.isActive
            ? AppColors.dynamicChromeTrack
            : AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: template.isActive
              ? AppColors.dynamicBorder
              : AppColors.dynamicBorder.withAlpha(90),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: template.isActive
                  ? (isDaily
                        ? const Color(0xFF2563EB).withAlpha(35)
                        : const Color(0xFF7C3AED).withAlpha(35))
                  : AppColors.dynamicSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(template.type),
              size: 20,
              color: template.isActive
                  ? (isDaily
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFFA78BFA))
                  : AppColors.dynamicTextSecondary.withAlpha(120),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        template.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: template.isActive
                              ? AppColors.dynamicTextPrimary
                              : AppColors.dynamicTextSecondary.withAlpha(180),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDaily
                            ? const Color(0xFF1E3A8A).withAlpha(60)
                            : const Color(0xFF581C87).withAlpha(60),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDaily ? 'DAILY' : 'WEEKLY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDaily
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFC4B5FD),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.dynamicTextSecondary.withAlpha(200),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Goal: ${_formatTarget(template)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(60),
                        ),
                      ),
                      child: Text(
                        '+${template.rewardPawPoints} pts',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: template.isActive,
            activeTrackColor: AppColors.primary,
            onChanged: onToggleActive,
          ),
        ],
      ),
    );
  }
}
