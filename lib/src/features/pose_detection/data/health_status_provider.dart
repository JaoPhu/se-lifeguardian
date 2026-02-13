import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../statistics/domain/simulation_event.dart';
import '../../events/data/event_repository.dart';
import '../../events/data/cloud_verification_service.dart';

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
  final EventRepository _eventRepository;
  Timer? _timer;

  HealthStatusNotifier(this._eventRepository) : super(HealthState.initial()) {
    _loadState();
    _startTimer();
  }

  static const _storageKey = 'health_state_v2';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        state = HealthState.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
      }

      // 2. Fetch latest events and status from Firestore (Override local if online)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Fetch events
          final eventsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('events')
              .orderBy('startTimeMs', descending: true)
              .limit(50)
              .get();

          final remoteEvents = eventsSnapshot.docs
              .map((doc) => SimulationEvent.fromJson(doc.data()))
              .toList();

          // Fetch current status/score
          final statusDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (statusDoc.exists) {
            final data = statusDoc.data()!;
            state = state.copyWith(
              score: (data['health_score'] as num?)?.toInt() ?? state.score,
              status: HealthStatus.values[(data['health_status'] as int?) ?? state.status.index],
              events: remoteEvents.isNotEmpty ? remoteEvents : state.events,
            );
          } else if (remoteEvents.isNotEmpty) {
            state = state.copyWith(events: remoteEvents);
          }
        } catch (e) {
          debugPrint("Firestore load failed, using local: $e");
        }
      }
    } catch (e) {
      debugPrint("Error loading health state: $e");
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(state.toJson()));
      
      // Sync basic status to Firestore root user doc for quick access
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'health_score': state.score,
          'health_status': state.status.index,
          'last_activity': state.currentActivity,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
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

  void reset() {
    state = HealthState.initial();
    _saveState();
  }

  Future<void> clearAllData({String? cameraId}) async {
    // 1. Physically delete matching snapshot files
    final List<SimulationEvent> remainingEvents = [];
    
    for (var event in state.events) {
      if (cameraId == null || event.cameraId == cameraId) {
        if (event.snapshotUrl != null) {
          try {
            final file = File(event.snapshotUrl!);
            if (await file.exists()) {
              await file.delete();
              debugPrint("Deleted snapshot: ${event.snapshotUrl}");
            }
          } catch (e) {
            debugPrint("Error deleting snapshot: $e");
          }
        }
      } else {
        remainingEvents.add(event);
      }
    }

    // 2. Clear cloud events if cameraId is provided
    if (cameraId != null) {
      await _eventRepository.deleteEventsForCamera(cameraId);
    }
    
    // 3. Update state to only include non-deleted events
    if (cameraId == null) {
      state = HealthState.initial();
    } else {
      state = state.copyWith(events: remainingEvents);
    }
    await _saveState();
  }

  // Activity Buffering State
  String? _pendingActivity;
  int _bufferCount = 0;
  static const int _requiredFrames = 45; // ~1.5 seconds at 30fps

  void updateActivity(String activity, {String? snapshotPath, String? cameraId}) {
    // Immediate Critical Events Check
    if (activity == 'falling' || activity == 'near_fall') {
      _processActivityChange(activity, snapshotPath, cameraId: cameraId);
      return;
    }

    // Debounce Logic for Non-Critical Activities
    if (_pendingActivity == activity) {
      _bufferCount++;
    } else {
      _pendingActivity = activity;
      _bufferCount = 0;
    }

    // Only update if activity persists for 1.5s
    if (_bufferCount >= _requiredFrames) {
      if (state.currentActivity != activity) {
        _processActivityChange(activity, snapshotPath, cameraId: cameraId);
      }
    }
  }

  void _processActivityChange(String activity, String? snapshotPath, {String? cameraId}) {
    if (state.currentActivity == activity && snapshotPath == null) return;

    final now = DateTime.now();
    final timestamp = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // 1. Close the previous event if it exists
    final List<SimulationEvent> updatedEvents = List.from(state.events);
    
    // Find the most recent event (which should be the one we are transitioning FROM)
    // We assume the first event in the list is the most recent one.
    if (updatedEvents.isNotEmpty) {
      final lastEvent = updatedEvents.first;
      
      // If the last event is "open" (no duration or we just want to update it based on time elapsed)
      // Actually, we should check if it corresponds to `state.currentActivity`.
      // But since we just want to "close" the timeline segment for the previous activity:
      
      if (lastEvent.startTimeMs != null) {
        final durationSec = (now.millisecondsSinceEpoch - lastEvent.startTimeMs!) ~/ 1000;
        final durationHrs = (durationSec / 3600).toStringAsFixed(2); // precise string for UI match
        
        updatedEvents[0] = lastEvent.copyWith(
          durationSeconds: durationSec,
          duration: "$durationHrs hr", // Update legacy string for compatibility
        );
      }
    }

    // 2. Create new event
    final newEvent = SimulationEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cameraId: cameraId,
      type: activity,
      timestamp: timestamp,
      date: dateStr,
      isCritical: activity == 'falling' || activity == 'near_fall',
      snapshotUrl: snapshotPath,
      startTimeMs: now.millisecondsSinceEpoch, // Start tracking time
      durationSeconds: 0, // Initial duration
      duration: "0.00 hr", 
      description: _getActivityDescription(activity),
    );

    updatedEvents.insert(0, newEvent);

    if (activity == 'falling' || activity == 'near_fall') {
      final penalty = activity == 'falling' ? 600 : 200;
      final newScore = (state.score - penalty).clamp(0, 1000);
      state = state.copyWith(
        score: newScore,
        currentActivity: activity,
        status: _getStatus(newScore),
        events: updatedEvents,
      );
      
      // Trigger Cloud Verification and Sync
      _syncAndVerify(newEvent);
    } else {
      state = state.copyWith(
        currentActivity: activity,
        events: updatedEvents,
        status: state.status == HealthStatus.none ? HealthStatus.normal : state.status,
      );
      // Sync basic activity change to Firestore
      _eventRepository.syncEvent(newEvent);
    }
    _saveState();
  }

  Future<void> _syncAndVerify(SimulationEvent event) async {
    SimulationEvent currentEvent = event;
    
    // 1. Sync to Firestore (Initial)
    await _eventRepository.syncEvent(currentEvent);

    // 2. Upload Snapshot to Storage if available
    if (currentEvent.snapshotUrl != null) {
      final remoteUrl = await _eventRepository.uploadSnapshot(currentEvent.snapshotUrl!, currentEvent.id);
      if (remoteUrl != null) {
        currentEvent = currentEvent.copyWith(remoteImageUrl: remoteUrl);
        // Update local state with remote URL
        final updatedEvents = state.events.map((e) => e.id == event.id ? currentEvent : e).toList();
        state = state.copyWith(events: updatedEvents);
        // Sync updated event with remote image URL
        await _eventRepository.syncEvent(currentEvent);
      }
    }

    // 3. Trigger Cloud Verification
    if (currentEvent.snapshotUrl != null) {
      _verifyEvent(currentEvent);
    }
  }
  
  // Cloud Verification Integration
  final _verificationService = CloudVerificationService();

  Future<void> _verifyEvent(SimulationEvent event) async {
    try {
      if (event.snapshotUrl == null) return;
      
      debugPrint("Uploading event ${event.id} for cloud verification...");
      final result = await _verificationService.verifyEvent(event.snapshotUrl!);
      
      final isVerified = result['verified'] as bool;
      final confidence = result['confidence'] as double;
      
      if (isVerified) {
        debugPrint("Event ${event.id} verified with confidence: $confidence");
        
        // Update event in list
        final updatedEvents = state.events.map((e) {
          if (e.id == event.id) {
            final updated = e.copyWith(
              isVerified: true,
              confidence: confidence,
              description: "${e.description} (Verified)",
            );
            // Sync verified status to Firestore
            _eventRepository.syncEvent(updated);
            return updated;
          }
          return e;
        }).toList();
        
        state = state.copyWith(events: updatedEvents);
        _saveState();
      }
    } catch (e) {
      debugPrint("Verification failed: $e");
    }
  }

  String _getActivityDescription(String type) {
    switch (type) {
      case 'sitting': return 'Common office posture. Take breaks often.';
      case 'slouching': return 'Subject is slumping or in a vulnerable position.';
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

    final int newScore = (state.score + change).round().clamp(0, 1000);
    
    // Update active event duration
    final List<SimulationEvent> updatedEvents = List.from(state.events);
    if (updatedEvents.isNotEmpty) {
      final activeEvent = updatedEvents.first;
      if (activeEvent.startTimeMs != null && activeEvent.type == state.currentActivity) {
        final durationSec = (DateTime.now().millisecondsSinceEpoch - activeEvent.startTimeMs!) ~/ 1000;
        // Only update if changes to avoid rebuild spam if not needed? 
        // Actually we need rebuilds for UI counters if displayed.
        final durationHrs = (durationSec / 3600).toStringAsFixed(2);
        
        updatedEvents[0] = activeEvent.copyWith(
          durationSeconds: durationSec,
          duration: "$durationHrs hr",
        );
      }
    }

    final bool hasEvents = updatedEvents.isNotEmpty && state.events.isNotEmpty;
    final bool durationChanged = hasEvents && updatedEvents.first.durationSeconds != state.events.first.durationSeconds;

    if (newScore != state.score || durationChanged) {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final updatedDailyScores = Map<String, double>.from(state.dailyScores);
      updatedDailyScores[dateStr] = newScore.toDouble();

      state = state.copyWith(
        score: newScore,
        status: _getStatus(newScore),
        dailyScores: updatedDailyScores,
        events: updatedEvents,
      );
      // We might not want to save to disk EVERY second for duration updates to avoid IO thrashing?
      // But for prototype/demo it's fine.
      if (newScore != state.score) { // Only save if score changed or periodically?
         _saveState();
      }
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
  final eventRepo = ref.watch(eventRepositoryProvider);
  return HealthStatusNotifier(eventRepo);
});
