import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' hide PoseLandmark, PoseLandmarkType;
import 'multi_person_pose_service.dart';
import 'pose_models.dart';

class TrackedPerson {
  Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};
  math.Point<double> centroid = const math.Point(0, 0);
  math.Point<double> velocity = const math.Point(0, 0);
  int missedCount = 0;
  int seenCount = 0;
  final int id;

  TrackedPerson(this.id, Map<PoseLandmarkType, PoseLandmark> initialLandmarks) {
    smoothedLandmarks = Map<PoseLandmarkType, PoseLandmark>.from(initialLandmarks);
    _updateCentroid();
  }

  void update(Map<PoseLandmarkType, PoseLandmark> rawLandmarks, double factor) {
    final oldCentroid = centroid;
    
    rawLandmarks.forEach((PoseLandmarkType type, PoseLandmark landmark) {
      final PoseLandmark? prev = smoothedLandmarks[type];
      if (prev != null) {
        smoothedLandmarks[type] = PoseLandmark(
          type: type,
          x: landmark.x * factor + prev.x * (1 - factor),
          y: landmark.y * factor + prev.y * (1 - factor),
          z: landmark.z * factor + prev.z * (1 - factor),
          likelihood: landmark.likelihood * factor + prev.likelihood * (1 - factor),
        );
      } else {
        smoothedLandmarks[type] = landmark;
      }
    });

    _updateCentroid();
    
    // Update velocity based on centroid movement
    velocity = math.Point(centroid.x - oldCentroid.x, centroid.y - oldCentroid.y);
    missedCount = 0;
    seenCount++;
  }

  /// Predict next position based on velocity (Dead Reckoning)
  void predict() {
    centroid = math.Point(centroid.x + velocity.x, centroid.y + velocity.y);
    
    // Shift all landmarks by velocity to keep skeleton consistent during occlusion
    smoothedLandmarks = smoothedLandmarks.map((PoseLandmarkType type, PoseLandmark landmark) {
      return MapEntry(type, PoseLandmark(
        type: type,
        x: landmark.x + velocity.x,
        y: landmark.y + velocity.y,
        z: landmark.z,
        likelihood: landmark.likelihood * 0.9, // Diminish likelihood while occluded
      ));
    });
    
    missedCount++;
  }

  void _updateCentroid() {
    final leftHip = smoothedLandmarks[PoseLandmarkType.leftHip];
    final rightHip = smoothedLandmarks[PoseLandmarkType.rightHip];
    final leftShoulder = smoothedLandmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = smoothedLandmarks[PoseLandmarkType.rightShoulder];
    
    double sumX = 0;
    double sumY = 0;
    int count = 0;

    for (var l in [leftHip, rightHip, leftShoulder, rightShoulder]) {
      if (l != null) {
        sumX += l.x;
        sumY += l.y;
        count++;
      }
    }

    if (count > 0) {
      centroid = math.Point(sumX / count, sumY / count);
    }
  }

  double distanceTo(math.Point<double> other) {
    return math.sqrt(math.pow(centroid.x - other.x, 2) + math.pow(centroid.y - other.y, 2));
  }
}

class PoseDetectionService {
  final MultiPersonPoseService _multiPersonPoseService = MultiPersonPoseService();
  
  final List<TrackedPerson> _activeTracks = [];
  int _nextPersonId = 0;
  
  // Scene Analysis State
  bool _isCameraMoving = false;
  math.Point<double> _globalMotion = const math.Point(0, 0);
  
  // Stability thresholds (Standard for Occlusion Handling)
  static const double _matchThreshold = 350.0; 
  static const int _maxMissedFrames = 60; 
  // REMOVED: _velocityNoiseThreshold - allowing fast movements as requested

  Future<void> close() async {
    await _multiPersonPoseService.close();
  }

  /// Detects if the scene is moving by comparing movement of all tracked objects
  void _analyzeSceneMotion() {
    if (_activeTracks.isEmpty) return;
    
    double dx = 0;
    double dy = 0;
    int count = 0;

    for (var track in _activeTracks) {
      if (track.missedCount == 0) {
        dx += track.velocity.x;
        dy += track.velocity.y;
        count++;
      }
    }

    if (count > 0) {
      _globalMotion = math.Point(dx / count, dy / count);
      // Increased threshold to 15.0: Ignore minor hand-shake, only trigger focus if camera truly pans
      _isCameraMoving = math.sqrt(_globalMotion.x * _globalMotion.x + _globalMotion.y * _globalMotion.y) > 15.0; 
    }
  }

  Future<List<TrackedPerson>> detect(InputImage inputImage, Uint8List originalBytes) async {
    final List<Map<PoseLandmarkType, PoseLandmark>> detectedLandmarksList = 
        await _multiPersonPoseService.detect(inputImage, originalBytes);
    
    final imageSize = inputImage.metadata?.size ?? const ui.Size(0, 0);
    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;
    final centerRadius = imageSize.shortestSide * 0.35; // Focused region for moving camera
    // 1. Prediction Step for all existing tracks
    for (var track in _activeTracks) {
      track.predict();
    }

    // 2. Matching Step (Greedy matching by distance)
    final List<Map<PoseLandmarkType, PoseLandmark>> unmatchedDetections = List.from(detectedLandmarksList);
    
    // Sort tracks by missedCount to prioritize matching active ones
    _activeTracks.sort((a, b) => a.missedCount.compareTo(b.missedCount));

    for (var track in _activeTracks) {
      if (unmatchedDetections.isEmpty) break;

      Map<PoseLandmarkType, PoseLandmark>? bestMatch;
      double minDistance = _matchThreshold;

      for (var det in unmatchedDetections) {
        final detCentroid = _calculateRawCentroid(det);
        final dist = track.distanceTo(detCentroid);
        if (dist < minDistance) {
          minDistance = dist;
          bestMatch = det;
        }
      }

      if (bestMatch != null) {
        // Increased smoothing influence (0.6 instead of 0.7) for more stable tracks
        track.update(bestMatch, 0.6);
        unmatchedDetections.remove(bestMatch);
      }
    }

    // 3. Create new tracks for unmatched detections
    for (var det in unmatchedDetections) {
      final detCentroid = _calculateRawCentroid(det);
      
      // Intelligent Filtering Logic
      if (_isCameraMoving) {
        // If camera is moving, only keep detections near center
        final distToCenter = math.sqrt(math.pow(detCentroid.x - centerX, 2) + math.pow(detCentroid.y - centerY, 2));
        if (distToCenter > centerRadius) continue;
      }

      _activeTracks.add(TrackedPerson(_nextPersonId++, det));
    }

    // 4. Post-Process Analysis (Scene State)
    _analyzeSceneMotion();

    // 5. Cleanup Tracks
    _activeTracks.removeWhere((t) {
      // Check if centroid is wildly out of frame (Auto-remove if left scene)
      if (imageSize.width > 0 && imageSize.height > 0) {
        final padding = imageSize.shortestSide * 0.3;
        final isWayOutOfFrame = t.centroid.x < -padding || 
                                 t.centroid.x > imageSize.width + padding || 
                                 t.centroid.y < -padding || 
                                 t.centroid.y > imageSize.height + padding;
        if (isWayOutOfFrame) return true;
      }
      
      // Lost track (Time-based cleanup)
      return t.missedCount > _maxMissedFrames;
    });

    // Sort by ID to ensure consistent UI layering
    _activeTracks.sort((a, b) => a.id.compareTo(b.id));

    return List.from(_activeTracks);
  }

  math.Point<double> _calculateRawCentroid(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    
    double sumX = 0;
    double sumY = 0;
    int count = 0;

    for (var l in [leftHip, rightHip, leftShoulder, rightShoulder]) {
      if (l != null) {
        sumX += l.x;
        sumY += l.y;
        count++;
      }
    }

    return count > 0 ? math.Point(sumX / count, sumY / count) : const math.Point(0, 0);
  }

  /// Calculates the angle of the torso relative to the vertical axis.
  /// Ported from Prototype: 90 = Upright, 0 = Flat.
  double getTorsoAngle(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return 0;
    }

    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final midHipX = (leftHip.x + rightHip.x) / 2;
    final midHipY = (leftHip.y + rightHip.y) / 2;

    final dx = midShoulderX - midHipX;
    final dy = midShoulderY - midHipY; 

    // atan2(abs(dy), abs(dx)) gives angle with horizontal
    // verticality where 90 is Upright, 0 is Flat.
    final angleRad = math.atan2(dy.abs(), dx.abs());
    return angleRad * (180 / math.pi);
  }

  double getLegStraightness(Map<PoseLandmarkType, PoseLandmark> landmarks) {
  /// Calculates the angle between three landmarks using atan2 (Anatomical Standard).
  double getAngle(PoseLandmark? first, PoseLandmark? mid, PoseLandmark? last) {
    if (first == null || mid == null || last == null) return 0;
    
    final double result = (
      math.atan2(last.y - mid.y, last.x - mid.x) -
      math.atan2(first.y - mid.y, first.x - mid.x)
    ).abs() * (180 / math.pi);
    
    return result > 180 ? 360 - result : result;
  }

    final leftBend = getAngle(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
      landmarks[PoseLandmarkType.leftAnkle],
    );

    final rightBend = getAngle(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
      landmarks[PoseLandmarkType.rightAnkle],
    );

    return math.min(leftBend, rightBend);
  }

  bool isLaying(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return false;
    final torsoAngle = getTorsoAngle(landmarks);
    
    final xValues = landmarks.values.map((l) => (l as PoseLandmark).x).toList();
    final yValues = landmarks.values.map((l) => (l as PoseLandmark).y).toList();
    if (xValues.isEmpty || yValues.isEmpty) return false;
    
    final width = xValues.reduce(math.max) - xValues.reduce(math.min);
    final height = yValues.reduce(math.max) - yValues.reduce(math.min);
    
    // Prototype check: torso < 25 or isFlat
    final isFlat = width > height * 1.4;

    return torsoAngle < 25 || isFlat;
  }

  bool isStanding(Map<PoseLandmarkType, PoseLandmark> landmarks) {
     if (landmarks.isEmpty) return false;
     final torsoAngle = getTorsoAngle(landmarks);
     if (torsoAngle < 60) return false;
     
     final legBend = getLegStraightness(landmarks);
     return legBend < 25; // Very straight
  }

  bool isWalking(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    if (landmarks.isEmpty) return false;
    final torsoAngle = getTorsoAngle(landmarks);
    if (torsoAngle < 60) return false;
    
    final legBend = getLegStraightness(landmarks);
    return legBend >= 25 && legBend < 65;
  }
}
