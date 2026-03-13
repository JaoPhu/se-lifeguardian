import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../statistics/domain/simulation_event.dart';
import '../../events/data/event_repository.dart';
import '../../events/data/cloud_verification_service.dart';
import '../../group/providers/group_providers.dart';
import '../../notification/data/notification_repository.dart';
import '../../notification/domain/notification_model.dart';
import '../../notification/data/notification_service.dart';
import '../../history/data/history_repository_provider.dart';

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
    return HealthState(
      score: 1000,
      status: HealthStatus.none,
      currentActivity: 'standing',
      events: [],
      dailyScores: {},
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
  final NotificationRepository _notificationRepository;
  final Ref _ref;
  final String? cameraId;
  Timer? _timer;
  Future<void>? _processingLock;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _userDocSubscription;

  HealthStatusNotifier(this._eventRepository, this._notificationRepository, this._ref, {this.cameraId}) : super(HealthState.initial()) {
    if (cameraId != null) {
      _startTimer();
    }
  }

  static const _storageKey = 'health_state_v2';

  Future<void> loadState(String targetUid) async {
    try {
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;
      // Prefix storage key with cameraId to segregate data if provided
      final cameraKey = cameraId != null ? '_$cameraId' : '';
      final storageKey = '$_storageKey${cameraKey}_$uid';
      
      final prefs = await SharedPreferences.getInstance();
      // Ensure local cache is namespaced by targetUid so users don't see each other's data
      final jsonStr = prefs.getString(storageKey);
      if (jsonStr != null) {
        state = HealthState.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
      } else {
        // Reset to initial if no cache exists for this user
        state = HealthState.initial();
      }

      // 2. Setup Real-time Listeners (Override local if online)
      if (targetUid.isNotEmpty) {
        _setupRealtimeListeners(targetUid);
      }
    } catch (e) {
      debugPrint("Error loading health state: $e");
    }
  }

  void _setupRealtimeListeners(String targetUid) {
    _eventsSubscription?.cancel();
    _userDocSubscription?.cancel();

    // 1. Listen to Events
    Query eventsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('events')
        .orderBy('startTimeMs', descending: true)
        .limit(50);

    if (cameraId != null) {
      eventsQuery = eventsQuery.where('cameraId', isEqualTo: cameraId);
    }

    _eventsSubscription = eventsQuery.snapshots().listen((snapshot) {
      final remoteEvents = snapshot.docs
          .map((doc) => SimulationEvent.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      if (remoteEvents.isNotEmpty) {
        // If global view (cameraId == null), derive EVERYTHING from events to ensure truth
        if (cameraId == null) {
          final latestEvent = remoteEvents.first;
          HealthStatus derivedStatus = HealthStatus.normal;
          int derivedScore = 1000;

          // If any event in the last 10 minutes is critical, status is emergency
          final tenMinsAgo = DateTime.now().millisecondsSinceEpoch - (10 * 60 * 1000);
          final hasRecentCritical = remoteEvents.take(10).any((e) =>
              (e.isCritical || e.type.toLowerCase().contains('fall')) &&
              (e.startTimeMs ?? 0) > tenMinsAgo);

          if (hasRecentCritical) {
            derivedStatus = HealthStatus.emergency;
            derivedScore = 400;
          } else {
            final isCritical = latestEvent.isCritical || latestEvent.type.toLowerCase().contains('fall');
            derivedStatus = isCritical ? HealthStatus.emergency : HealthStatus.normal;
            derivedScore = isCritical ? 400 : 1000;
          }

          state = state.copyWith(
            events: remoteEvents,
            status: derivedStatus,
            score: derivedScore,
            currentActivity: latestEvent.type,
          );
        } else {
          state = state.copyWith(events: remoteEvents);
        }
      } else {
        // No events found for this target user/camera
        state = state.copyWith(
          events: [],
          status: HealthStatus.none,
          score: 1000,
          currentActivity: '', // Clear activity if no events
        );
      }
    }, onError: (e) => debugPrint("Events listener failed: $e"));

    // 2. Listen to User Status (Score/Status)
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        
        final rawStatus = data['health_status'] as int?;
        HealthStatus derivedStatus = state.status;
        if (rawStatus != null) {
          derivedStatus = HealthStatus.values[rawStatus];
        }
        
        // Force 'none' if we have no events to support the "null" status requirement
        if (state.events.isEmpty) {
          derivedStatus = HealthStatus.none;
        }

        state = state.copyWith(
          score: (data['health_score'] as num?)?.toInt() ?? state.score,
          status: derivedStatus,
          currentActivity: data['last_activity'] as String? ?? state.currentActivity,
        );
      }
    }, onError: (e) => debugPrint("Status listener failed: $e"));
  }

  Future<void> _saveState() async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      if (targetUid.isEmpty) return; // Don't save if no user is active

      final prefs = await SharedPreferences.getInstance();
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;
      final cameraKey = cameraId != null ? '_$cameraId' : '';
      final storageKey = '$_storageKey${cameraKey}_$uid';
      
      await prefs.setString(storageKey, json.encode(state.toJson()));
      
      // Sync basic status to Firestore root user doc for quick access
        // Warning: This write will only succeed if Security Rules allow it,
        // or if targetUid is the user's own UID. For guest patients, this will fail silently.
        await FirebaseFirestore.instance.collection('users').doc(targetUid).set({
          'health_score': state.score,
          'health_status': state.status.index,
          'last_activity': state.currentActivity,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving health state: $e");
    }
  }

  // Internal clock for simulation support
  DateTime _currentTime = DateTime.now();
  DateTime? _lastScoreUpdateTime;
  DateTime? _lastDurationSyncTime;
  bool _isSimulation = false;

  void updateSimulationClock(DateTime time) {
    if (!_isSimulation || _lastScoreUpdateTime == null) {
      _isSimulation = true;
      _lastScoreUpdateTime = time;
      _lastDurationSyncTime = time;
    }
    
    _currentTime = time;
    
    // Update current event duration in real-time if 1s has passed
    if (state.events.isNotEmpty) {
      final lastEvent = state.events.first;
      if (lastEvent.startTimeMs != null) {
        final nowMs = _currentTime.millisecondsSinceEpoch;
        final startMs = lastEvent.startTimeMs!;
        
        // Only update if time is moving forward
        if (nowMs > startMs) {
          final durationSec = (nowMs - startMs) ~/ 1000;
          
          // Update local state frequently for smooth UI
          final updatedEvents = List<SimulationEvent>.from(state.events);
          updatedEvents[0] = lastEvent.copyWith(
            durationSeconds: durationSec,
            duration: _formatDurationLabel(durationSec),
          );
          
          state = state.copyWith(events: updatedEvents);
          
          // Sync to Firestore periodically (e.g., every 5 simulation seconds) to avoid spamming
          if (durationSec % 5 == 0) {
            _eventRepository.syncEvent(updatedEvents[0]);
          }
        }
      }
    }
    
    // Only update health score if at least 1 simulation second has passed
    final elapsedSec = _currentTime.difference(_lastScoreUpdateTime!).inSeconds;
    if (elapsedSec >= 1) {
       for (int i = 0; i < elapsedSec; i++) {
         _updateScoreBasedOnActivity();
       }
       _lastScoreUpdateTime = _lastScoreUpdateTime!.add(Duration(seconds: elapsedSec));
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint("Error fetching location: $e");
      return null;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == HealthStatus.none) return; 
      
      // If NOT in simulation mode, drive the clock with real time
      if (!_isSimulation) {
         _currentTime = DateTime.now();
         _updateScoreBasedOnActivity();
      }
      // If in simulation mode, updateSimulationClock drives the updates
    });
  }

  void startMonitoring() {
    _currentTime = DateTime.now();
    state = state.copyWith(status: HealthStatus.normal);
  }

  void stopMonitoring() {
    state = state.copyWith(status: HealthStatus.none);
    _saveState();
  }

  void reset() {
    // Reset status/score but KEEP events history
    state = HealthState.initial().copyWith(
      events: state.events, 
    );
    _isSimulation = false;
    _currentTime = DateTime.now();
    _saveState();
  }

  Future<void> clearAllData({String? cameraId}) async {
    // 1. Physically delete matching snapshot files (Local files only)
    final List<SimulationEvent> remainingEvents = [];
    
    for (var event in state.events) {
      if (cameraId == null || event.cameraId == cameraId) {
        if (event.snapshotUrl != null) {
          try {
            final file = File(event.snapshotUrl!);
            if (await file.exists()) {
              await file.delete();
              debugPrint("Deleted local snapshot: ${event.snapshotUrl}");
            }
          } catch (e) {
            debugPrint("Error deleting snapshot: $e");
          }
        }
      } else {
        remainingEvents.add(event);
      }
    }

      // 2. Clear cloud events
      if (cameraId != null) {
        await _eventRepository.deleteEventsForCamera(cameraId);
      } else {
        // Global cleanup: UI Wipe + Cloud Wipe + Local Cache Wipe
        await _eventRepository.deleteAllDataForUser();
        
        // Clear ALL local SharedPreferences keys for this specific user (including camera-specific ones)
        try {
          final targetUid = _ref.read(resolvedTargetUidProvider);
          if (targetUid.isNotEmpty) {
             final prefs = await SharedPreferences.getInstance();
             final allKeys = prefs.getKeys();
             
             // Key pattern: health_state_v2[_cameraId]_targetUid
             for (final k in allKeys) {
               if (k.startsWith(_storageKey) && k.endsWith(targetUid)) {
                 await prefs.remove(k);
                 debugPrint("SharedPreferences cleared key: $k");
               }
             }
             debugPrint("All SharedPreferences for $targetUid cleared.");
          }
        } catch (e) {
          debugPrint("Error clearing SharedPreferences: $e");
        }

        // 2.1 Invalidate history/statistics providers to force UI refresh
        _ref.invalidate(dailyStatsProvider);
        _ref.invalidate(weeklyStatsProvider);
        _ref.invalidate(dailyEventsProvider);
      }
    
    // 3. Update active state
    if (cameraId == null) {
      // reset() also saves to state, but we want to be explicit here
      state = HealthState.initial();
      _currentTime = DateTime.now();
      _isSimulation = false;
    } else {
      // Local cleanup for specific camera
      state = state.copyWith(
        events: remainingEvents,
        status: HealthStatus.none, // ✅ Reset status when a camera is deleted/cleared
        score: 1000,              // ✅ Reset score
      );
      await _saveState();
    }
  }

  void updateActivity(String activity, {String? snapshotPath, String? cameraId, DateTime? customTime, bool forceSync = false}) {
    // If customTime is provided, sync our internal clock
    if (customTime != null) {
      _currentTime = customTime;
    }
    
    // Process the activity change immediately.
    // forceSync allows updating the current event's duration even if activity name hasn't changed.
    if (state.currentActivity != activity || snapshotPath != null || forceSync) {
      unawaited(_processActivityChange(activity, snapshotPath, cameraId: cameraId, customTime: customTime, forceSync: forceSync));
    }
  }

  Future<void> _processActivityChange(String activity, String? snapshotPath, {String? cameraId, DateTime? customTime, bool forceSync = false}) async {
    // 0. Ensure Atomic Processing (Lock)
    // This prevents one process from reading outdated state while another is writing it.
    while (_processingLock != null) {
      await _processingLock;
    }
    
    final Completer<void> completer = Completer<void>();
    _processingLock = completer.future;

    try {
      // If we're just forcing a sync of the current activity duration, don't return early
      // Also ALLOW record if events is currently empty (initial state)
      if (state.currentActivity == activity && snapshotPath == null && !forceSync && state.events.isNotEmpty) return;

      // --- STICKY FALL LOGIC ---
      // If the current activity is 'falling' and it's very recent (< 2 seconds),
      // don't let it be superseded by ANY other activity immediately.
      // This ensures the fall event is recorded and not "eaten" by a quick walk-away or rest.
      if (state.currentActivity == 'falling' && activity != 'falling') {
        if (state.events.isNotEmpty) {
           final lastEvent = state.events.first;
           if (lastEvent.type == 'falling' && lastEvent.startTimeMs != null) {
              final now = customTime ?? _currentTime;
              final elapsedMs = now.millisecondsSinceEpoch - lastEvent.startTimeMs!;
              if (elapsedMs < 2000) {
                 debugPrint("Sticky Fall active: ignoring transition to $activity for now (elapsed: ${elapsedMs}ms).");
                 return;
              }
           }
        }
      }

    final now = customTime ?? _currentTime;
    final timestamp = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Fetch GPS for ALL events if possible, or specifically for critical ones
    final position = await _getCurrentLocation();

    // 1. Close the previous event (or current if forceSync)
    final List<SimulationEvent> updatedEvents = List.from(state.events);
    
    if (updatedEvents.isNotEmpty) {
      final lastEvent = updatedEvents.first;
      
      if (lastEvent.startTimeMs != null) {
        final nowMs = now.millisecondsSinceEpoch;
        final startMs = lastEvent.startTimeMs!;
        
        // FUTURE GUARD: If the existing event is from the "future" (stale simulation), 
        // don't try to calculate a negative duration. Just start fresh.
        if (nowMs >= startMs) {
          final durationSec = (nowMs - startMs) ~/ 1000;
          
          // Update score for simulation jumps
          if (_isSimulation) {
            _applyScoreChange(lastEvent.type, durationSec);
          }

          updatedEvents[0] = lastEvent.copyWith(
            durationSeconds: durationSec,
            duration: _formatDurationLabel(durationSec),
          );
          
          await _eventRepository.syncEvent(updatedEvents[0]);
        } else {
          debugPrint("Discarding negative duration: last event started in future (${startMs - nowMs}ms ahead).");
          // Optionally close it with 0 duration
           updatedEvents[0] = lastEvent.copyWith(
            durationSeconds: 0,
            duration: _formatDurationLabel(0),
          );
          await _eventRepository.syncEvent(updatedEvents[0]);
        }
      }
    }

    // If we were just forcing a sync of the current event, we stop here (ONLY if we actually have an event to sync)
    if (forceSync && state.currentActivity == activity && updatedEvents.isNotEmpty) {
      state = state.copyWith(events: updatedEvents);
      _saveState();
      // Sync the final version of the current event to cloud
      unawaited(_eventRepository.syncEvent(updatedEvents.first));
      return;
    }

    // 2. Create new event (only if activity changed)
    final newEvent = SimulationEvent(
      id: _currentTime.millisecondsSinceEpoch.toString(),
      cameraId: cameraId ?? this.cameraId,
      type: activity,
      timestamp: timestamp,
      date: dateStr,
      isCritical: activity == 'falling' || activity == 'near_fall',
      snapshotUrl: snapshotPath,
      startTimeMs: _currentTime.millisecondsSinceEpoch, // Start tracking time
      durationSeconds: 0, // Initial duration
      duration: "0s", 
      description: _getActivityDescription(activity),
      latitude: position?.latitude,
      longitude: position?.longitude,
    );

      await _processNewEvent(newEvent, activity, updatedEvents, position: position);
    } finally {
      completer.complete();
      _processingLock = null;
    }
  }

  Future<void> _processNewEvent(SimulationEvent newEvent, String activity, List<SimulationEvent> updatedEvents, {Position? position}) async {
    if (activity == 'falling' || activity == 'near_fall') {
      _applyScoreChange(activity, 0); // Applies penalty and updates dailyScores
      state = state.copyWith(
        currentActivity: activity,
        events: [newEvent, ...updatedEvents],
      );
      
      // Universal logic for all events: Sync to cloud and upload snapshot if available
      await _syncAndUploadSnapshot(newEvent);

      // Additional logic for critical events
      _triggerCriticalNotification(activity, newEvent, position: position);
    } else {
      state = state.copyWith(
        currentActivity: activity,
        events: [newEvent, ...updatedEvents],
        status: state.status == HealthStatus.none ? HealthStatus.normal : state.status,
      );
      // Still sync regular events
      await _syncAndUploadSnapshot(newEvent);
    }

    // NEW: Immediate Exercise Notification
    if (activity == 'exercise') {
      _triggerExerciseNotification(newEvent);
    }

    _saveState();
  }

  Future<void> _syncAndUploadSnapshot(SimulationEvent event) async {
    SimulationEvent currentEvent = event;
    
    // 1. Sync to Firestore (Initial metadata)
    await _eventRepository.syncEvent(currentEvent);

    // 2. Upload Snapshot to Storage if available
    if (currentEvent.snapshotUrl != null) {
      final remoteUrl = await _eventRepository.uploadSnapshot(currentEvent.snapshotUrl!, currentEvent.id);
      if (remoteUrl != null) {
        currentEvent = currentEvent.copyWith(remoteImageUrl: remoteUrl);
        
        // Update local state with remote URL to prevent re-upload and allow instant UI update
        if (mounted) {
          final updatedEvents = state.events.map((e) => e.id == event.id ? currentEvent : e).toList();
          state = state.copyWith(events: updatedEvents);
        }
        
        // Sync updated event with remote image URL
        await _eventRepository.syncEvent(currentEvent);
      }
    }

    // 3. Trigger Cloud Verification (CRITICAL ONLY)
    if (currentEvent.snapshotUrl != null && (currentEvent.isCritical == true)) {
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
        change = 30; // Recovery (+30 pts/sec)
        break;
      case 'slouching':
        change = -60; // Warning (-60 pts/sec) - Reaches 799 in ~3.4s
        break;
      case 'laying':
        change = -10; // Slow deduction (-10 pts/sec)
        break;
      case 'walking':
        change = 30; // Recovery (+30 pts/sec)
        break;
      case 'standing':
        change = 30; // Recovery (+30 pts/sec)
        break;
      case 'exercise':
        change = 60; // Fast recovery (+60 pts/sec)
        break;
      case 'occluded':
        change = -10; // Occluded deduction
        break;
    }

    if (change <= 0 && state.score < 1000 && state.status == HealthStatus.normal) {
      if (change == 0) change = 10; // Passive recovery if normal and no active deduction
    }

    final int newScore = (state.score + change).round().clamp(0, 1000);
    
    // --- TICK LOGIC: Update active event duration ---
    final List<SimulationEvent> updatedEvents = List.from(state.events);
    if (updatedEvents.isNotEmpty) {
      final activeEvent = updatedEvents.first;
      if (activeEvent.startTimeMs != null && activeEvent.type == state.currentActivity) {
        final startDateTime = DateTime.fromMillisecondsSinceEpoch(activeEvent.startTimeMs!);
        
        // Handle Session Splitting (midnight crossing)
        if (startDateTime.day != _currentTime.day || startDateTime.month != _currentTime.month || startDateTime.year != _currentTime.year) {
           // We crossed midnight! Cap current event to 23:59:59 of start day
           final endOfDay = DateTime(startDateTime.year, startDateTime.month, startDateTime.day, 23, 59, 59, 999);
           final capDurationSec = (endOfDay.millisecondsSinceEpoch - activeEvent.startTimeMs!) ~/ 1000;
           
           // Update and save the OLD event
           final cappedEvent = activeEvent.copyWith(
             durationSeconds: capDurationSec,
             duration: _formatDurationLabel(capDurationSec),
           );
           updatedEvents[0] = cappedEvent;
           _eventRepository.syncEvent(cappedEvent);
           
           // Create a NEW event starting precisely at midnight of the new day
           final midnightNewDay = DateTime(_currentTime.year, _currentTime.month, _currentTime.day, 0, 0, 0);
           final newDurationSec = (_currentTime.millisecondsSinceEpoch - midnightNewDay.millisecondsSinceEpoch) ~/ 1000;
           
           final timestamp = "${midnightNewDay.hour.toString().padLeft(2, '0')}:${midnightNewDay.minute.toString().padLeft(2, '0')}";
           final dateStr = "${midnightNewDay.year}-${midnightNewDay.month.toString().padLeft(2, '0')}-${midnightNewDay.day.toString().padLeft(2, '0')}";

           final newEvent = SimulationEvent(
             id: midnightNewDay.millisecondsSinceEpoch.toString(),
             cameraId: activeEvent.cameraId,
             type: activeEvent.type,
             timestamp: timestamp,
             date: dateStr,
             isCritical: activeEvent.isCritical,
             snapshotUrl: activeEvent.snapshotUrl,
             startTimeMs: midnightNewDay.millisecondsSinceEpoch,
             durationSeconds: newDurationSec,
             duration: _formatDurationLabel(newDurationSec),
             description: activeEvent.description,
             latitude: activeEvent.latitude,
             longitude: activeEvent.longitude,
           );
           
           updatedEvents.insert(0, newEvent);
           _eventRepository.syncEvent(newEvent);
        } else {
           // Normal tick processing
           final durationSec = (_currentTime.millisecondsSinceEpoch - activeEvent.startTimeMs!) ~/ 1000;
           updatedEvents[0] = activeEvent.copyWith(
             durationSeconds: durationSec,
             duration: _formatDurationLabel(durationSec),
           );
        }
      }
    }

    _updateStateScore(newScore, updatedEvents);
  }

  void _applyScoreChange(String type, int durationSec) {
    double change = 0;
    switch (type) {
      case 'sitting': change = 30.0 * durationSec; break;
      case 'slouching': change = -60.0 * durationSec; break;
      case 'laying': change = -10.0 * durationSec; break;
      case 'walking': change = 30.0 * durationSec; break;
      case 'standing': change = 30.0 * durationSec; break;
      case 'exercise': change = 60.0 * durationSec; break;
      case 'falling': change = -1000.0; break; // Drop to 0
      case 'near_fall': change = -200.0; break; 
      case 'occluded': change = -10.0 * durationSec; break;
    }
    final int newScore = (state.score + change).round().clamp(0, 1000);
    _updateStateScore(newScore, state.events);
  }

  void _updateStateScore(int newScore, List<SimulationEvent> updatedEvents) {
    final now = _currentTime;
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final updatedDailyScores = Map<String, double>.from(state.dailyScores);
    updatedDailyScores[dateStr] = newScore.toDouble();

    final bool hasEvents = updatedEvents.isNotEmpty && state.events.isNotEmpty;
    final bool durationChanged = hasEvents && updatedEvents.first.durationSeconds != state.events.first.durationSeconds;

    if (newScore != state.score || durationChanged) {
      final oldStatus = state.status;
      final newStatus = _getStatus(newScore, events: updatedEvents);

      state = state.copyWith(
        score: newScore,
        status: newStatus,
        dailyScores: updatedDailyScores,
        events: updatedEvents,
      );

      // Handle status transitions
      if (newStatus != oldStatus) {
        if (newStatus == HealthStatus.warning && oldStatus == HealthStatus.normal) {
          _triggerThresholdWarningNotification();
        } else if (newStatus == HealthStatus.emergency && oldStatus == HealthStatus.warning) {
          _triggerThresholdEmergencyNotification();
        }
      }

      // Periodically sync active event to Firestore (every 30 simulation seconds)
      if (durationChanged && updatedEvents.isNotEmpty && updatedEvents.first.durationSeconds != null) {
        final duration = updatedEvents.first.durationSeconds!;
        final previousDuration = state.events.isNotEmpty ? (state.events.first.durationSeconds ?? 0) : 0;
        
        final isEmergency = state.status == HealthStatus.emergency;
        
        if (!isEmergency && updatedEvents.first.type == 'sitting' && previousDuration < 60 && duration >= 60) {
           _triggerSittingNotification(updatedEvents.first);
        }
        if (!isEmergency && updatedEvents.first.type == 'slouching' && previousDuration < 60 && duration >= 60) {
           _triggerSlouchingNotification(updatedEvents.first);
        }
        if (!isEmergency && (updatedEvents.first.type == 'walking' || updatedEvents.first.type == 'walk') && previousDuration < 30 && duration >= 30) {
           _triggerWalkingNotification(updatedEvents.first);
        }
        if (!isEmergency && updatedEvents.first.type == 'laying' && previousDuration < 120 && duration >= 120) {
           _triggerLayingNotification(updatedEvents.first);
        }

        // Periodic Health Advice (every 10 minutes of simulation)
        if (duration % 600 == 0 && duration > 0 && previousDuration < duration) {
           _triggerHealthAdviceNotification(state.score, state.status);
        }

        if ((duration ~/ 30) > (previousDuration ~/ 30)) {
           _eventRepository.syncEvent(updatedEvents.first);
        }
      }

      if (newScore != state.score) {
         _saveState();
      }
    }
  }

  Future<void> _triggerCriticalNotification(String activity, SimulationEvent event, {Position? position}) async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final isFalling = activity == 'falling';
      
      // Use provided position or fetch if missing
      final pos = position ?? await _getCurrentLocation();

      final notification = NotificationModel(
        id: '', // Firestore will generate
        title: isFalling ? 'ตรวจพบการล้ม! ⚠️' : 'ตรวจพบอาการเสียหลัก (Near Fall) ⚠️',
        message: isFalling 
            ? 'พบเหตุการณ์ล้มในกล้อง ${event.cameraId ?? "หลัก"} โปรดตรวจสอบทันที'
            : 'พบแนวโน้มการล้มในกล้อง ${event.cameraId ?? "หลัก"} โปรดติดตามสถานะอย่างใกล้ชิด',
        type: isFalling ? NotificationType.danger : NotificationType.warning,
        date: _currentTime,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        imageUrl: event.remoteImageUrl ?? event.snapshotUrl, // Preference remote
        confidence: event.confidence,
        eventId: event.id,
        cameraId: event.cameraId, // ส่ง cameraId ให้ Cloud Function ใช้ใน LINE alert
      );

      // 1. Save to the person who fell (Private/Internal)
      final privateNotification = notification.copyWith(
        message: "${notification.message} (ที่มา: ตนเอง)",
      );
      await _notificationRepository.addNotification(privateNotification, targetUid: uid);
      
      // 2. Broadcast to group members if it's a fall
      if (isFalling && uid != 'demo_user') {
        try {
          final groupRepo = _ref.read(groupRepoProvider);
          final group = await groupRepo.getGroupByOwnerUid(uid);
          
          if (group != null) {
            final memberUids = await groupRepo.getMemberUids(group.id);
            final groupNotification = notification.copyWith(
              title: "ตรวจพบการล้ม! (${group.name}) ⚠️",
              message: "${notification.message} (จากกลุ่ม: ${group.name})",
            );

            for (final memberUid in memberUids) {
              if (memberUid != uid) {
                 await _notificationRepository.addNotification(groupNotification, targetUid: memberUid);
              }
            }
          }
        } catch (e) {
          debugPrint("Error broadcasting group notification: $e");
        }
      }
      
      // Locally show the banner so the user testing the Demo immediately sees it
      try {
        await _ref.read(notificationServiceProvider).showLocalAppNotification(
          title: notification.title,
          body: notification.message,
        );
      } catch (e) {
        debugPrint("Error showing local app notification: $e");
      }

      debugPrint("🔔 LOGGED Notification [$uid]: ${notification.title} - ${notification.message}");
      debugPrint("📍 LocationAttached: ${pos != null}, ImageAttached: ${notification.imageUrl != null}");
    } catch (e) {
      debugPrint("Error triggering notification: $e");
    }
  }

  Future<void> _triggerSittingNotification(SimulationEvent event) async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final notification = NotificationModel(
        id: '', // Firestore will generate
        title: 'ระวังออฟฟิศซินโดรมถามหานะครับ! ⚠️',
        message: 'ลุกขึ้นหมุนหัวไหล่และสะบัดข้อมือสัก 2-3 นาทีดีไหมครับ? 💪 (ที่มา: ตนเอง)',
        type: NotificationType.warning,
        date: _currentTime,
        cameraId: event.cameraId,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
      
      debugPrint("🔔 LOGGED Sitting Notification [$uid]: ${notification.title}");
    } catch (e) {
      debugPrint("Error triggering sitting notification: $e");
    }
  }

  Future<void> _triggerExerciseNotification(SimulationEvent event) async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final notification = NotificationModel(
        id: '', 
        title: 'เริ่มกิจกรรมกายบริหาร',
        message: 'เริ่มกิจกรรมกายบริหาร ขอให้มีสุขภาพแข็งแรง! (จากกล้อง ${event.cameraId ?? "หลัก"}) (ที่มา: ตนเอง)',
        type: NotificationType.success,
        date: _currentTime,
        imageUrl: event.remoteImageUrl,
        cameraId: event.cameraId,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
      debugPrint("🔔 LOGGED Exercise Notification [$uid]: ${notification.title}");
    } catch (e) {
      debugPrint("Error triggering exercise notification: $e");
    }
  }

  Future<void> _triggerWalkingNotification(SimulationEvent event) async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final notification = NotificationModel(
        id: '',
        title: 'เดินเพื่อสุขภาพ',
        message: 'คุณเดินต่อเนื่องมาได้ระยะหนึ่งแล้ว เยี่ยมมาก! (จากกล้อง ${event.cameraId ?? "หลัก"}) (ที่มา: ตนเอง)',
        type: NotificationType.success,
        date: _currentTime,
        cameraId: event.cameraId,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
      debugPrint("🔔 LOGGED Walking Notification [$uid]: ${notification.title}");
    } catch (e) {
      debugPrint("Error triggering walking notification: $e");
    }
  }

  Future<void> _triggerLayingNotification(SimulationEvent event) async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final notification = NotificationModel(
        id: '',
        title: 'นอนเยอะไปแล้วนะวันนี้',
        message: 'คุณนอนพักผ่อนมานานกว่า 30 นาทีแล้ว ลองลุกขึ้นขยับร่างกายบ้างจะดีต่อสุขภาพนะครับ (จากกล้อง ${event.cameraId ?? "หลัก"}) (ที่มา: ตนเอง)',
        type: NotificationType.warning,
        date: _currentTime,
        cameraId: event.cameraId,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
      debugPrint("🔔 LOGGED Laying Notification [$uid]: ${notification.title}");
    } catch (e) {
      debugPrint("Error triggering laying notification: $e");
    }
  }

  Future<void> _triggerHealthAdviceNotification(int score, HealthStatus status) async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      String title;
      String message;
      NotificationType type;

      if (score >= 900) {
        title = 'สุขภาพดีเยี่ยม! 🌟';
        message = 'สุขภาพของคุณอยู่ในเกณฑ์ดีเยี่ยม รักษาพฤติกรรมที่ดีแบบนี้ต่อไปนะครับ';
        type = NotificationType.success;
      } else if (score >= 800) {
        title = 'รักษาสุขภาพคนเก่ง 👍';
        message = 'วันนี้คุณทำได้ดีแล้ว ลองเดินเพิ่มอีกสักนิดเพื่อกระตุ้นการไหลเวียนโลหิตนะครับ';
        type = NotificationType.success;
      } else if (score >= 600) {
        title = 'คำแนะนำสุขภาพ 💡';
        message = 'ช่วงนี้คุณอาจจะนั่งนานไปหน่อย ลองยืดเส้นยืดสายทุกๆ 1 ชั่วโมงจะช่วยให้สดชื่นขึ้นครับ';
        type = NotificationType.warning;
      } else {
        title = 'เป็นห่วงสุขภาพนะครับ ❤️';
        message = 'วันนี้คะแนนสุขภาพค่อนข้างต่ำ ลองหาเวลาพักผ่อนและทำกิจกรรมที่เคลื่อนไหวบ้างนะครับ';
        type = NotificationType.warning;
      }

      final notification = NotificationModel(
        id: '',
        title: title,
        message: '$message (ที่มา: ตนเอง)',
        type: type,
        date: _currentTime,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
      debugPrint("🔔 LOGGED Health Advice Notification [$uid]: ${notification.title}");
    } catch (e) {
      debugPrint("Error triggering health advice notification: $e");
    }
  }

  Future<void> _triggerSlouchingNotification(SimulationEvent event) async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final notification = NotificationModel(
        id: '',
        title: 'แจ้งเตือนท่านั่ง',
        message: 'ตรวจพบการนั่งหลังค่อมเป็นเวลานาน โปรดปรับท่านั่งเพื่อสุขภาพหลังครับ (จากกล้อง ${event.cameraId ?? "หลัก"}) (ที่มา: ตนเอง)',
        type: NotificationType.warning,
        date: _currentTime,
        cameraId: event.cameraId,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
      debugPrint("🔔 LOGGED Slouching Notification [$uid]: ${notification.title}");
    } catch (e) {
      debugPrint("Error triggering slouching notification: $e");
    }
  }

  void _showLocal(NotificationModel notification) {
    try {
      _ref.read(notificationServiceProvider).showLocalAppNotification(
        title: notification.title,
        body: notification.message,
      );
    } catch (e) {
      debugPrint("Error showing local app notification: $e");
    }
  }

  Future<void> _triggerThresholdWarningNotification() async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final notification = NotificationModel(
        id: '',
        title: 'เริ่มตรวจพบความผิดปกติ 🟡',
        message: 'คะแนนสุขภาพลดลงถึงเกณฑ์เฝ้าระวัง โปรดตรวจสอบผู้ถูกดูแลเบื้องต้น (ที่มา: ตนเอง)',
        type: NotificationType.warning,
        date: _currentTime,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
    } catch (e) {
      debugPrint("Error triggering threshold warning: $e");
    }
  }

  Future<void> _triggerThresholdEmergencyNotification() async {
    try {
      final targetUid = _ref.read(resolvedTargetUidProvider);
      final uid = targetUid.isEmpty ? 'demo_user' : targetUid;

      final notification = NotificationModel(
        id: '',
        title: 'เข้าสู่สถานะอันตราย! 🔴',
        message: 'คะแนนสุขภาพวิกฤต โปรดตรวจสอบสถานที่จริงทันที! (ที่มา: ตนเอง)',
        type: NotificationType.danger,
        date: _currentTime,
      );

      await _notificationRepository.addNotification(notification, targetUid: uid);
      _showLocal(notification);
    } catch (e) {
      debugPrint("Error triggering threshold emergency: $e");
    }
  }

  HealthStatus _getStatus(int score, {List<SimulationEvent>? events}) {
    // Priority 1: Check for active emergency activities in the provided/current event list
    final listToCheck = events ?? state.events;
    if (listToCheck.isNotEmpty) {
      final topEvent = listToCheck.first;
      if (topEvent.type == 'falling' || topEvent.type == 'near_fall') {
        return HealthStatus.emergency;
      }
    }
    
    // Priority 2: Numerical thresholds
    if (score < 500) return HealthStatus.emergency;
    if (score < 800) return HealthStatus.warning;
    return HealthStatus.normal;
  }

  String _formatDurationLabel(int seconds) {
    if (seconds < 0) return "0s";
    if (seconds < 60) return "${seconds}s"; 
    
    if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s == 0 ? "${m}m" : "${m}m ${s}s";
    }
    
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return m == 0 ? "${h}h" : "${h}h ${m}m";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eventsSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}

final healthStatusFamily = StateNotifierProvider.family<HealthStatusNotifier, HealthState, String?>((ref, cameraId) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final notifier = HealthStatusNotifier(eventRepo, notificationRepo, ref, cameraId: cameraId);

  // Watch selected targetUid and trigger loadState when it changes
  ref.listen(resolvedTargetUidProvider, (previous, next) {
    notifier.loadState(next);
  }, fireImmediately: true);

  return notifier;
});
