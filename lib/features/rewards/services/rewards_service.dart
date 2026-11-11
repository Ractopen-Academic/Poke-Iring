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

  final ValueNotifier<int> pointsNotifier = ValueNotifier<int>(250);
  final ValueNotifier<List<RewardRedemption>> redemptionsNotifier =
      ValueNotifier<List<RewardRedemption>>([]);

  Future<void> reload() => _loadBalance();

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      pointsNotifier.value = prefs.getInt(_prefUserPoints) ?? 250;
      final raw = prefs.getStringList(_prefRedemptions) ?? [];
      redemptionsNotifier.value = raw
          .map((item) => RewardRedemption.fromJson(jsonDecode(item)))
          .toList();
    } catch (e) {
      debugPrint('Error loading rewards balance: $e');
    }
  }

  /// Listen or fetch current points from Firestore
  void syncUserPoints(String userId) {
    if (!_isFirebaseAvailable || userId.isEmpty) return;

    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final pts = (doc.data()?['totalPawPoints'] as num?)?.toInt() ?? 0;
          pointsNotifier.value = pts;
          SharedPreferences.getInstance().then((prefs) {
            prefs.setInt(_prefUserPoints, pts);
          });
        }
      });
    } catch (e) {
      debugPrint('Error syncing user points: $e');
    }
  }

  /// Add points to balance (e.g. from human verification review game)
  Future<void> addPoints(String userId, int points, String reason) async {
    pointsNotifier.value += points;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefUserPoints, pointsNotifier.value);

      if (_isFirebaseAvailable && userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'totalPawPoints': FieldValue.increment(points),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error adding points: $e');
    }
  }

  /// Redeem an item (cat food or welfare donation)
  Future<bool> redeemReward({
    required String userId,
    required RewardItem item,
  }) async {
    if (pointsNotifier.value < item.costPawPoints) {
      return false;
    }

    final newBalance = pointsNotifier.value - item.costPawPoints;
    pointsNotifier.value = newBalance;

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

    final updated = List<RewardRedemption>.from(redemptionsNotifier.value)
      ..insert(0, redemption);
    redemptionsNotifier.value = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefUserPoints, newBalance);
      final rawList =
          updated.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_prefRedemptions, rawList);

      if (_isFirebaseAvailable && userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'totalPawPoints': FieldValue.increment(-item.costPawPoints),
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance.collection('redemptions').doc(redemption.id).set({
          ...redemption.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error persisting redemption: $e');
    }

    return true;
  }
}
