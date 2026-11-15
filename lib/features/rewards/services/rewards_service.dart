import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reward_item.dart';

class RewardsService {
  static final RewardsService instance = RewardsService._internal();
  RewardsService._internal() {
    _loadBalance();
  }

  static const String _prefUserPoints = 'pokeiring_user_points_balance';
  static const String _prefRedemptions = 'pokeiring_user_redemptions';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pointsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _redemptionsSub;
  String? _activeUserId;

  final ValueNotifier<int> pointsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<RewardRedemption>> redemptionsNotifier =
      ValueNotifier<List<RewardRedemption>>([]);

  Future<void> reload([String? userId]) => _loadBalance(userId: userId);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _pointsKeyFor(String? userId) => (userId != null && userId.isNotEmpty)
      ? '${_prefUserPoints}_$userId'
      : _prefUserPoints;

  String _redemptionsKeyFor(String? userId) =>
      (userId != null && userId.isNotEmpty)
      ? '${_prefRedemptions}_$userId'
      : _prefRedemptions;

  Future<void> _loadBalance({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveUser = userId ?? _activeUserId;
      final scopedPts = prefs.getInt(_pointsKeyFor(effectiveUser));
      final fallbackPts = prefs.getInt(_prefUserPoints);
      pointsNotifier.value = scopedPts ?? fallbackPts ?? 0;

      final raw =
          prefs.getStringList(_redemptionsKeyFor(effectiveUser)) ??
          prefs.getStringList(_prefRedemptions) ??
          [];
      redemptionsNotifier.value = raw
          .map((item) => RewardRedemption.fromJson(jsonDecode(item)))
          .toList();
    } catch (e) {
      debugPrint('Error loading rewards balance: $e');
    }
  }

  /// Listen and fetch current points and redemptions directly from Firestore.
  void syncUserPoints(String userId) {
    if (userId.isEmpty) return;

    if (_activeUserId != userId) {
      _activeUserId = userId;
      unawaited(_loadBalance(userId: userId));
    }

    if (!_isFirebaseAvailable) return;

    _pointsSub?.cancel();
    _redemptionsSub?.cancel();

    try {
      _pointsSub = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen(
            (doc) {
              if (doc.exists) {
                final pts =
                    (doc.data()?['totalPawPoints'] as num?)?.toInt() ?? 0;
                pointsNotifier.value = pts;
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setInt(_pointsKeyFor(userId), pts);
                });
              }
            },
            onError: (Object err) {
              debugPrint('Error in user points stream: $err');
            },
          );

      _redemptionsSub = FirebaseFirestore.instance
          .collection('redemptions')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen(
            (snap) {
              final list = snap.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return RewardRedemption.fromJson(data);
              }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              redemptionsNotifier.value = list;
              SharedPreferences.getInstance().then((prefs) {
                final rawList = list
                    .map((r) => jsonEncode(r.toJson()))
                    .toList();
                prefs.setStringList(_redemptionsKeyFor(userId), rawList);
              });
            },
            onError: (Object err) {
              debugPrint('Error in redemptions stream: $err');
            },
          );
    } catch (e) {
      debugPrint('Error syncing user points: $e');
    }
  }

  /// Add points to balance (authoritative Firestore increment when online)
  Future<void> addPoints(String userId, int points, String reason) async {
    if (points <= 0) return;

    if (_isFirebaseAvailable && userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'totalPawPoints': FieldValue.increment(points),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      } catch (e) {
        debugPrint('Error adding points in Firestore: $e');
      }
    }

    pointsNotifier.value += points;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pointsKeyFor(userId), pointsNotifier.value);
      await prefs.setInt(_prefUserPoints, pointsNotifier.value);
    } catch (e) {
      debugPrint('Error caching points locally: $e');
    }
  }

  /// Redeem an item (cat food or welfare donation) with backend-authoritative transaction check
  Future<bool> redeemReward({
    required String userId,
    required RewardItem item,
  }) async {
    if (pointsNotifier.value < item.costPawPoints) {
      return false;
    }

    final redemption = RewardRedemption(
      id: 'rdm_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      itemId: item.id,
      title: item.title,
      costPawPoints: item.costPawPoints,
      type: item.type,
      timestamp: DateTime.now(),
      status: 'confirmed',
    );

    if (_isFirebaseAvailable && userId.isNotEmpty) {
      try {
        final db = FirebaseFirestore.instance;
        final userRef = db.collection('users').doc(userId);
        final rdmRef = db.collection('redemptions').doc(redemption.id);

        final committedBalance = await db.runTransaction<int?>((tx) async {
          final userSnap = await tx.get(userRef);
          final serverPts =
              (userSnap.data()?['totalPawPoints'] as num?)?.toInt() ?? 0;
          if (serverPts < item.costPawPoints) {
            return null;
          }
          final nextBalance = serverPts - item.costPawPoints;
          tx.set(userRef, {
            'totalPawPoints': nextBalance,
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          tx.set(rdmRef, {
            ...redemption.toJson(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          return nextBalance;
        });

        if (committedBalance == null) {
          return false;
        }

        pointsNotifier.value = committedBalance;
        final updated = List<RewardRedemption>.from(redemptionsNotifier.value)
          ..removeWhere((r) => r.id == redemption.id)
          ..insert(0, redemption);
        redemptionsNotifier.value = updated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_pointsKeyFor(userId), committedBalance);
        await prefs.setInt(_prefUserPoints, committedBalance);
        return true;
      } catch (e) {
        debugPrint('Firestore transaction redeemReward failed: $e');
        return false;
      }
    }

    // Offline / unit-test fallback when Firebase is not initialized
    final newBalance = pointsNotifier.value - item.costPawPoints;
    pointsNotifier.value = newBalance;

    final updated = List<RewardRedemption>.from(redemptionsNotifier.value)
      ..insert(0, redemption);
    redemptionsNotifier.value = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pointsKeyFor(userId), newBalance);
      await prefs.setInt(_prefUserPoints, newBalance);
      final rawList = updated.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_redemptionsKeyFor(userId), rawList);
      await prefs.setStringList(_prefRedemptions, rawList);
    } catch (e) {
      debugPrint('Error persisting redemption locally: $e');
    }

    return true;
  }
}
