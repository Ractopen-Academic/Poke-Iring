import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExplorerHealthSnapshot {
  final int stepsToday;
  final double distanceKm;
  final double caloriesBurned;
  final int activeMinutes;
  final DateTime updatedAt;

  const ExplorerHealthSnapshot({
    required this.stepsToday,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.updatedAt,
  });

  factory ExplorerHealthSnapshot.empty() {
    final now = DateTime.now();
    return ExplorerHealthSnapshot(
      stepsToday: 0,
      distanceKm: 0,
      caloriesBurned: 0,
      activeMinutes: 0,
      updatedAt: now,
    );
  }
}

class ExplorerHealthService {
  ExplorerHealthService._();

  static final ExplorerHealthService instance = ExplorerHealthService._();

  StreamController<ExplorerHealthSnapshot>? _controller;
  StreamSubscription<StepCount>? _subscription;
  bool _started = false;

  ExplorerHealthSnapshot _latest = ExplorerHealthSnapshot.empty();

  ExplorerHealthSnapshot get latest => _latest;

  Stream<ExplorerHealthSnapshot> get stream =>
      _controller?.stream ?? const Stream.empty();

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;
    _controller ??= StreamController<ExplorerHealthSnapshot>.broadcast();

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayDateKey();
    final savedDate = prefs.getString('explorer_health_date');

    if (savedDate != todayKey) {
      await prefs.setString('explorer_health_date', todayKey);
      await prefs.setInt('explorer_health_total', 0);
    }

    _subscription = Pedometer.stepCountStream.listen((event) async {
      final int totalSteps = event.steps;
      final int baselineSteps = prefs.getInt('explorer_health_total') ?? 0;
      final int todaySteps;

      if (totalSteps >= baselineSteps) {
        todaySteps = totalSteps - baselineSteps;
      } else {
        todaySteps = 0;
      }

      final snapshot = ExplorerHealthSnapshot(
        stepsToday: todaySteps,
        distanceKm: todaySteps * 0.00075,
        caloriesBurned: todaySteps * 0.04,
        activeMinutes: (todaySteps / 120).floor(),
        updatedAt: DateTime.now(),
      );

      _latest = snapshot;
      _controller?.add(snapshot);

      await prefs.setInt('explorer_health_total', totalSteps);
      await prefs.setString('explorer_health_date', todayKey);
    });

    _latest = ExplorerHealthSnapshot(
      stepsToday: 0,
      distanceKm: 0,
      caloriesBurned: 0,
      activeMinutes: 0,
      updatedAt: DateTime.now(),
    );
    _controller?.add(_latest);
  }

  Future<void> stop() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    _controller?.close();
    _controller = null;
    _started = false;
  }

  String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
