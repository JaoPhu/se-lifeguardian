import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../statistics/domain/simulation_event.dart';

enum HealthStatus { normal, warning, emergency, none }

class HealthState {
  final int score;
  final HealthStatus status;
  final String currentActivity; // 'standing', 'walking', 'sitting', 'laying', 'falling'
  final List<SimulationEvent> events;
  final Map<String, double> dailyScores; // "YYYY-MM-DD" -> score

  HealthState ({
    required this.score,
    required this.status,
    required this.currentActivity,
    required this.events,
    required this.dailyScores,
  });

  factory HealthState.initial() {
    final now = DateTime.now();
    final mockScores = <String, double>{};
    // Initialize with some mock data for the week
    for (int i = 7; i >= 1; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      mockScores[dateStr] = 700.0 + (i * 20); // Variety in scores
    }

    return HealthState(
      score: 1000,
      status: HealthStatus.none,
      currentActivity: 'standing',
      events: [],
      dailyScores: mockScores,
    );
  }

  HealthState copyWith({
    int? score,
    HealthStatus? status,
    String? currentActivity,
    List<SimulationEvent>? events,
    Map<String, double>? dailyScores,
  }) {
    return HealthState(
      score: score ?? this.score,
      status: status ?? this.status,
      currentActivity: currentActivity ?? this.currentActivity,
      events: events ?? this.events,
      dailyScores: dailyScores ?? this.dailyScores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'status': status.index,
      'currentActivity': currentActivity,
      'events': events.map((e) => e.toJson()).toList(),
      'dailyScores': dailyScores,
    };
  }

  factory HealthState.fromJson(Map<String, dynamic> json) {
    return HealthState(
      score: json['score'] as int,
      status: HealthStatus.values[json['status'] as int? ?? 0],
      currentActivity: json['currentActivity'] as String? ?? 'standing',
      events: (json['events'] as List? ?? [])
          .map((e) => SimulationEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyScores: (json['dailyScores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ?? {},
    );
  }
}

class HealthStatusNotifier extends StateNotifier<HealthState> {
  Timer? _timer;

  HealthStatusNotifier() : super(HealthState.initial()) {
    _loadState();
    _startTimer();
  }

  static const _storageKey = 'health_state_v1';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        state = HealthState.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Error loading health state: $e");
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint("Error saving health state: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == HealthStatus.none) return; // Only score if active
      _updateScoreBasedOnActivity();
    });
  }

  void startMonitoring() {
    state = state.copyWith(status: HealthStatus.normal);
  }

  void stopMonitoring() {
    state = state.copyWith(status: HealthStatus.none);
    _saveState();
  }

  void updateActivity(String activity, {String? snapshotPath}) {
    if (state.currentActivity == activity && snapshotPath == null) return;

    final now = DateTime.now();
    final timestamp = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    // Create new event
    final newEvent = SimulationEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: activity,
      timestamp: timestamp,
      date: "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      isCritical: activity == 'falling' || activity == 'near_fall',
      snapshotUrl: snapshotPath,
      duration: "0.5 hr", // Default duration for preview
      description: _getActivityDescription(activity),
    );

    final updatedEvents = [newEvent, ...state.events];

    if (activity == 'falling' || activity == 'near_fall') {
      final penalty = activity == 'falling' ? 600 : 200;
      final newScore = (state.score - penalty).clamp(0, 1000);
      state = state.copyWith(
        score: newScore,
        currentActivity: activity,
        status: _getStatus(newScore),
        events: updatedEvents,
      );
    } else {
      state = state.copyWith(
        currentActivity: activity,
        events: updatedEvents,
        status: state.status == HealthStatus.none ? HealthStatus.normal : state.status,
      );
    }
    _saveState();
  }

  String _getActivityDescription(String type) {
    switch (type) {
      case 'sitting': return 'Common office posture. Take breaks often.';
      case 'slouching': return 'Poor posture detected. Straighten up!';
      case 'laying': return 'Subject is resting in a horizontal position.';
      case 'walking': return 'Active movement detected. Healthy state.';
      case 'standing': return 'Upright position. Standard activity.';
      case 'exercise': return 'Intense activity. Great for heart health!';
      case 'falling': return 'CRITICAL: Sudden impact detected. Check subject!';
      case 'near_fall': return 'WARNING: Unusual stumble or imbalance.';
      default: return 'Normal daily activity.';
    }
  }

  void _updateScoreBasedOnActivity() {
    double change = 0;
    
    switch (state.currentActivity) {
      case 'sitting':
        change = -50 / 3600; 
        break;
      case 'slouching':
        change = -150 / 3600; // Worse for posture/spine
        break;
      case 'laying':
        change = -75 / 3600;
        break;
      case 'walking':
        change = 25 / 3600;
        break;
      case 'standing':
        change = 5 / 3600;
        break;
      case 'exercise':
        change = 500 / 3600; // Direct health benefit
        break;
    }

    int newScore = (state.score + change).round().clamp(0, 1000);
    
    if (newScore != state.score) {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final updatedDailyScores = Map<String, double>.from(state.dailyScores);
      updatedDailyScores[dateStr] = newScore.toDouble();

      state = state.copyWith(
        score: newScore,
        status: _getStatus(newScore),
        dailyScores: updatedDailyScores,
      );
      _saveState();
    }
  }

  HealthStatus _getStatus(int score) {
    if (score < 500) return HealthStatus.emergency;
    if (score < 800) return HealthStatus.warning;
    return HealthStatus.normal;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final healthStatusProvider = StateNotifierProvider<HealthStatusNotifier, HealthState>((ref) {
  return HealthStatusNotifier();
});
