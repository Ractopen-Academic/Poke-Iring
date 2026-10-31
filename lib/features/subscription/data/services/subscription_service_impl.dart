import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/subscription_tier.dart';
import '../../domain/services/subscription_service.dart';

class SubscriptionServiceImpl implements SubscriptionService {
  static SubscriptionServiceImpl? _instance;
  static SubscriptionServiceImpl get instance =>
      _instance ??= SubscriptionServiceImpl();

  final FirebaseFirestore? firestore;

  final Map<String, StreamController<SubscriptionStatus>> _controllers = {};
  final Map<String, SubscriptionStatus> _cache = {};

  String _prefKey(String userId) => 'subscription_status_v1_$userId';

  SubscriptionServiceImpl({this.firestore});

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<SubscriptionStatus> watchSubscription(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<SubscriptionStatus>.broadcast(
        onListen: () {
          getSubscription(userId).then((status) {
            if (_controllers[userId]?.isClosed == false) {
              _controllers[userId]?.add(status);
            }
          });
        },
      );
    }
    return _controllers[userId]!.stream;
  }

  @override
  Future<SubscriptionStatus> getSubscription(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final raw = prefs.getString(_prefKey(userId));
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final status = SubscriptionStatus.fromMap(decoded);
        _cache.putIfAbsent(userId, () => status);
        return _cache[userId]!;
      }
    } catch (_) {}

    if (_isFirebaseAvailable) {
      try {
        final doc = await _db
            .collection('users')
            .doc(userId)
            .get()
            .timeout(const Duration(milliseconds: 1500));
        if (doc.exists) {
          final subData = doc.data()?['subscription'] as Map<String, dynamic>?;
          if (subData != null) {
            final status = SubscriptionStatus.fromMap(subData);
            _cache.putIfAbsent(userId, () => status);
            unawaited(_persistLocally(userId, status));
            return status;
          }
        }
      } catch (e) {
        debugPrint('Firestore fetch subscription error: $e');
      }
    }

    final defaultFree = SubscriptionStatus.free(userId);
    _cache.putIfAbsent(userId, () => defaultFree);
    return _cache[userId]!;
  }

  @override
  Future<SubscriptionStatus> upgradeToClub(
    String userId, {
    BillingInterval interval = BillingInterval.monthly,
  }) async {
    final now = DateTime.now();
    final duration = interval == BillingInterval.annual
        ? const Duration(days: 365)
        : const Duration(days: 30);

    final upgraded = SubscriptionStatus(
      userId: userId,
      tier: SubscriptionTier.felineClubMember,
      activeInterval: interval,
      activatedAt: now,
      expiresAt: now.add(duration),
      isAutoRenewing: true,
    );

    _cache[userId] = upgraded;
    unawaited(_persistLocally(userId, upgraded));
    unawaited(_syncToCloud(userId, upgraded));

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(upgraded);
    }

    return upgraded;
  }

  @override
  Future<SubscriptionStatus> cancelSubscription(String userId) async {
    final current = await getSubscription(userId);
    final cancelled = current.copyWith(
      tier: SubscriptionTier.free,
      isAutoRenewing: false,
    );

    _cache[userId] = cancelled;
    unawaited(_persistLocally(userId, cancelled));
    unawaited(_syncToCloud(userId, cancelled));

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(cancelled);
    }

    return cancelled;
  }

  Future<void> _persistLocally(String userId, SubscriptionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      await prefs.setString(_prefKey(userId), jsonEncode(status.toMap()));
    } catch (_) {}
  }

  Future<void> _syncToCloud(String userId, SubscriptionStatus status) async {
    if (!_isFirebaseAvailable) return;

    try {
      await _db.collection('users').doc(userId).set({
        'subscription': status.toMap(),
        'isClubMember': status.isClubMember,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync subscription error: $e');
    }
  }

  @visibleForTesting
  void resetCache() {
    _cache.clear();
  }
}
