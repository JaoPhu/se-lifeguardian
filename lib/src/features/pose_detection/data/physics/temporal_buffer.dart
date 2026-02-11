import 'dart:math';
import '../pose_models.dart';

/// Stores a history of pose frames to allow for temporal analysis 
/// (velocity, acceleration, and trend detection).
class TemporalBuffer {
  final int bufferSize;
  final List<Map<PoseLandmarkType, PoseLandmark>> _history = [];
  final List<int> _timestamps = [];
  
  TemporalBuffer({this.bufferSize = 30}); // Default 30 frames (~1 second)

  /// Adds a new frame to the buffer
  void add(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (_history.length >= bufferSize) {
      _history.removeAt(0);
      _timestamps.removeAt(0);
    }
    _history.add(landmarks);
    _timestamps.add(DateTime.now().millisecondsSinceEpoch);
  }

  /// Calculates the average velocity of a specific landmark over the last [windowMs] milliseconds.
  /// Returns velocity in "normalized units per second" (if using normalized coords) 
  /// or "pixels per second" (if using absolute).
  double getVelocity(PoseLandmarkType type, {int windowMs = 500}) {
    if (_history.length < 2) return 0.0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - windowMs;

    // Find index of the oldest frame within the window
    int startIndex = -1;
    for (int i = 0; i < _timestamps.length; i++) {
      if (_timestamps[i] >= cutoff) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1 || startIndex == _history.length - 1) return 0.0;

    final startFrame = _history[startIndex];
    final endFrame = _history.last;

    final startPoint = startFrame[type];
    final endPoint = endFrame[type];

    if (startPoint == null || endPoint == null) return 0.0;

    final distance = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2));
    final timeDeltaSeconds = (_timestamps.last - _timestamps[startIndex]) / 1000.0;

    if (timeDeltaSeconds <= 0) return 0.0;

    return distance / timeDeltaSeconds;
  }

  /// Checks if a landmark has dropped vertically significantly in the last [windowMs].
  /// Returns the vertical displacement (positive = went down).
  double getVerticalDrop(PoseLandmarkType type, {int windowMs = 1000}) {
    if (_history.length < 2) return 0.0;
    
    final startPoint = _history.first[type];
    final endPoint = _history.last[type];

    if (startPoint == null || endPoint == null) return 0.0;

    // Assuming coordinate system where Y increases downwards (standard screen coords)
    return endPoint.y - startPoint.y;
  }
}
