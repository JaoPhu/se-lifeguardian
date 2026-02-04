import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class TrackedPose {
  Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};
  math.Point<double> centroid = const math.Point(0, 0);
  int framesSinceUpdate = 0;

  TrackedPose(Map<PoseLandmarkType, PoseLandmark> initialLandmarks) {
    smoothedLandmarks = Map.from(initialLandmarks);
    _updateCentroid();
  }

  void update(Map<PoseLandmarkType, PoseLandmark> rawLandmarks, double factor) {
    rawLandmarks.forEach((type, landmark) {
      final prev = smoothedLandmarks[type];
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
    framesSinceUpdate = 0;
  }

  void _updateCentroid() {
    final leftHip = smoothedLandmarks[PoseLandmarkType.leftHip];
    final rightHip = smoothedLandmarks[PoseLandmarkType.rightHip];
    final leftShoulder = smoothedLandmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = smoothedLandmarks[PoseLandmarkType.rightShoulder];
    
    // Use average of hips and shoulders for more stable centroid
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
  // Use High-Accuracy model for diagnostic-grade results
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(model: PoseDetectionModel.accurate),
  );
  
  // Smoothing is now handled by 1 Euro Filter in the Presentation layer
  // to minimize latency and ensure anatomical consistency.
  
  final List<TrackedPose> _trackedPoses = [];
  final int _maxForgottenFrames = 10;

  Future<void> close() async {
    await _poseDetector.close();
  }

  Future<List<Map<PoseLandmarkType, PoseLandmark>>> detect(InputImage inputImage) async {
    final List<Pose> detectedPoses = await _poseDetector.processImage(inputImage);
    
    // 1. Increment frame counters
    for (var tp in _trackedPoses) {
      tp.framesSinceUpdate++;
    }

    // 2. Match and Update
    for (var pose in detectedPoses) {
      final rawLandmarks = pose.landmarks;
      final rawCentroid = _calculateRawCentroid(rawLandmarks);
      
      TrackedPose? bestMatch;
      double minDistance = 150.0; // Distance threshold for matching (adjust as needed)

      for (var tp in _trackedPoses) {
        final dist = tp.distanceTo(rawCentroid);
        if (dist < minDistance) {
          minDistance = dist;
          bestMatch = tp;
        }
      }

      if (bestMatch != null) {
        // Direct update: Smoothing is offloaded to 1 Euro Filter in UI
        bestMatch.update(rawLandmarks, 1.0); 
      } else {
        _trackedPoses.add(TrackedPose(rawLandmarks));
      }
    }

    // 3. Remove old tracks
    _trackedPoses.removeWhere((tp) => tp.framesSinceUpdate > _maxForgottenFrames);

    // 4. Return smoothed landmarks
    return _trackedPoses.map((tp) => tp.smoothedLandmarks).toList();
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
    
    final double result = math.toDegrees(
      math.atan2(last.y - mid.y, last.x - mid.x) -
      math.atan2(first.y - mid.y, first.x - mid.x)
    ).abs();
    
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
    
    final xValues = landmarks.values.map((l) => l.x).toList();
    final yValues = landmarks.values.map((l) => l.y).toList();
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
