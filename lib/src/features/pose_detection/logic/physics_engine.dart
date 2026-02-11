import 'dart:math';
import '../data/pose_models.dart';

/// A buffer that stores pose data over time to calculate physics properties.
class PhysicsEngine {
  final int bufferSize;
  final List<Map<PoseLandmarkType, _LandmarkState>> _history = [];

  PhysicsEngine({this.bufferSize = 5}); // Keep last 5 frames (~150ms at 30fps)

  /// Updates the engine with a new pose and returns the analysis.
  Map<PoseLandmarkType, PhysicsData> update(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return {};

    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final Map<PoseLandmarkType, _LandmarkState> currentState = {};
    final Map<PoseLandmarkType, PhysicsData> results = {};

    for (var entry in landmarks.entries) {
      final type = entry.key;
      final landmark = entry.value;
      
      currentState[type] = _LandmarkState(
        x: landmark.x,
        y: landmark.y,
        timestamp: currentTimestamp,
      );
    }

    // Calculate physics for each landmark
    for (var type in currentState.keys) {
      final current = currentState[type]!;
      _LandmarkState? previous;

      // Find the most recent previous state for this landmark
      if (_history.isNotEmpty) {
        // We look at the immediate previous frame for instantaneous velocity
        final lastFrame = _history.last;
        if (lastFrame.containsKey(type)) {
          previous = lastFrame[type];
        }
      }

      if (previous != null) {
        final dt = (current.timestamp - previous.timestamp) / 1000.0; // Seconds
        if (dt > 0) {
          final dx = current.x - previous.x;
          final dy = current.y - previous.y;
          
          final vx = dx / dt;
          final vy = dy / dt;
          final velocity = sqrt(vx * vx + vy * vy);

          // Calculate acceleration if we have 2 frames of history
          double ax = 0;
          double ay = 0;
          double acceleration = 0;

          if (_history.length >= 2) {
             final prevFrame = _history[_history.length - 1];
             final prevPrevFrame = _history[_history.length - 2];
             
             if (prevFrame.containsKey(type) && prevPrevFrame.containsKey(type)) {
               final p1 = prevFrame[type]!;
               final p0 = prevPrevFrame[type]!;
               
               final dt1 = (current.timestamp - p1.timestamp) / 1000.0;
               final dt0 = (p1.timestamp - p0.timestamp) / 1000.0;
               
               if (dt1 > 0 && dt0 > 0) {
                 final vx1 = (current.x - p1.x) / dt1;
                 final vy1 = (current.y - p1.y) / dt1;
                 final vx0 = (p1.x - p0.x) / dt0;
                 final vy0 = (p1.y - p0.y) / dt0;
                 
                 ax = (vx1 - vx0) / dt1;
                 ay = (vy1 - vy0) / dt1;
                 acceleration = sqrt(ax * ax + ay * ay);
               }
             }
          }

          results[type] = PhysicsData(
            velocity: velocity,
            vx: vx,
            vy: vy,
            acceleration: acceleration,
            ax: ax,
            ay: ay,
          );
        }
      }
    }

    _history.add(currentState);
    if (_history.length > bufferSize) {
      _history.removeAt(0);
    }

    return results;
  }
  
  void reset() {
    _history.clear();
  }
}

class _LandmarkState {
  final double x;
  final double y;
  final int timestamp;

  _LandmarkState({required this.x, required this.y, required this.timestamp});
}

class PhysicsData {
  final double velocity; // Pixels per second
  final double vx;
  final double vy;
  final double acceleration; // Pixels per second squared
  final double ax;
  final double ay;

  PhysicsData({
    this.velocity = 0,
    this.vx = 0,
    this.vy = 0,
    this.acceleration = 0,
    this.ax = 0,
    this.ay = 0,
  });
  
  @override
  String toString() {
    return 'Vel: ${velocity.toStringAsFixed(1)}, Acc: ${acceleration.toStringAsFixed(1)}';
  }
}
