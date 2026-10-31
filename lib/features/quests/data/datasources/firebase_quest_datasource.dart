import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quest_template.dart';

class FirebaseQuestDataSource {
  static final FirebaseQuestDataSource instance =
      FirebaseQuestDataSource._internal();

  FirebaseFirestore? _firestore;
  final StreamController<List<QuestTemplate>> _poolController =
      StreamController<List<QuestTemplate>>.broadcast();

  List<QuestTemplate>? _cachedTemplates;

  static const String _collectionName = 'quest_templates';
  static const String _localCacheKey = 'pokeiring_quest_templates_cache_v1';

  factory FirebaseQuestDataSource({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return FirebaseQuestDataSource._internal(firestore);
    }
    return instance;
  }

  FirebaseQuestDataSource._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Stream<List<QuestTemplate>> watchQuestPool() {
    _startWatchingPool();
    return _poolController.stream;
  }

  void _startWatchingPool() {
    if (_isFirebaseAvailable) {
      try {
        _db
            .collection(_collectionName)
            .snapshots()
            .listen(
              (snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  final templates = snapshot.docs.map((doc) {
                    final data = doc.data();
                    return QuestTemplate.fromMap({...data, 'id': doc.id});
                  }).toList();

                  _cachedTemplates = templates;
                  _persistLocalCache(templates);
                  if (!_poolController.isClosed) {
                    _poolController.add(templates);
                  }
                } else {
                  // Collection is empty, seed it
                  seedDefaultPoolIfEmpty();
                }
              },
              onError: (err) {
                debugPrint('Firestore quest pool stream error: $err');
                _emitFallbackPool();
              },
            );
        return;
      } catch (e) {
        debugPrint('Failed to attach Firestore quest stream: $e');
      }
    }

    _emitFallbackPool();
  }

  Future<void> _emitFallbackPool() async {
    final pool = await getQuestPool();
    if (!_poolController.isClosed) {
      _poolController.add(pool);
    }
  }

  Future<List<QuestTemplate>> getQuestPool() async {
    if (_cachedTemplates != null && _cachedTemplates!.isNotEmpty) {
      return _cachedTemplates!;
    }

    // Try reading from Firestore first if available
    if (_isFirebaseAvailable) {
      try {
        final snap = await _db.collection(_collectionName).get();
        if (snap.docs.isNotEmpty) {
          final templates = snap.docs.map((doc) {
            final data = doc.data();
            return QuestTemplate.fromMap({...data, 'id': doc.id});
          }).toList();

          _cachedTemplates = templates;
          _persistLocalCache(templates);
          return templates;
        } else {
          await seedDefaultPoolIfEmpty();
        }
      } catch (e) {
        debugPrint(
          'Firestore quest fetch failed: $e. Falling back to local cache.',
        );
      }
    }

    // Read from local SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_localCacheKey);
      if (rawList != null && rawList.isNotEmpty) {
        final templates = rawList.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return QuestTemplate.fromMap(map);
        }).toList();

        _cachedTemplates = templates;
        return templates;
      }
    } catch (_) {}

    // Fall back to built-in default catalog
    final defaults = QuestTemplate.defaultCatalog();
    _cachedTemplates = defaults;
    _persistLocalCache(defaults);
    return defaults;
  }

  Future<void> seedDefaultPoolIfEmpty({bool force = false}) async {
    final defaults = QuestTemplate.defaultCatalog();
    if (force) {
      _cachedTemplates = defaults;
      await _persistLocalCache(defaults);
      if (_isFirebaseAvailable) {
        try {
          final batch = _db.batch();
          for (final tpl in defaults) {
            final ref = _db.collection(_collectionName).doc(tpl.id);
            batch.set(ref, tpl.toMap());
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Force re-seeding Firestore quest pool error: $e');
        }
      }
      if (!_poolController.isClosed) {
        _poolController.add(defaults);
      }
      return;
    }

    _cachedTemplates = defaults;
    await _persistLocalCache(defaults);

    if (_isFirebaseAvailable) {
      try {
        final snap = await _db.collection(_collectionName).limit(1).get();
        if (snap.docs.isEmpty) {
          final batch = _db.batch();
          for (final tpl in defaults) {
            final ref = _db.collection(_collectionName).doc(tpl.id);
            batch.set(ref, tpl.toMap());
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Seeding Firestore quest pool skipped: $e');
      }
    }

    if (!_poolController.isClosed) {
      _poolController.add(defaults);
    }
  }

  Future<void> saveTemplate(QuestTemplate template) async {
    final current = await getQuestPool();
    final updated = [template, ...current.where((t) => t.id != template.id)];
    _cachedTemplates = updated;
    await _persistLocalCache(updated);

    if (_isFirebaseAvailable) {
      try {
        await _db
            .collection(_collectionName)
            .doc(template.id)
            .set(template.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore save template error: $e');
      }
    }

    if (!_poolController.isClosed) {
      _poolController.add(updated);
    }
  }

  Future<void> toggleTemplateActive(String templateId, bool isActive) async {
    final current = await getQuestPool();
    final index = current.indexWhere((t) => t.id == templateId);
    if (index != -1) {
      final updatedTpl = current[index].copyWith(isActive: isActive);
      final updatedList = List<QuestTemplate>.from(current);
      updatedList[index] = updatedTpl;

      _cachedTemplates = updatedList;
      await _persistLocalCache(updatedList);

      if (_isFirebaseAvailable) {
        try {
          await _db.collection(_collectionName).doc(templateId).update({
            'isActive': isActive,
          });
        } catch (e) {
          debugPrint('Firestore toggle template error: $e');
        }
      }

      if (!_poolController.isClosed) {
        _poolController.add(updatedList);
      }
    }
  }

  Future<void> _persistLocalCache(List<QuestTemplate> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = templates.map((t) => jsonEncode(t.toMap())).toList();
      await prefs.setStringList(_localCacheKey, list);
    } catch (_) {}
  }
}
