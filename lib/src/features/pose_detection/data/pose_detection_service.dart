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
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  
  // Ported from Prototype: Balance between lag and stability
  // 0.1 = very stable but laggy, 0.9 = jittery but fast
  final double _smoothingFactor = 0.35; 
  
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
        bestMatch.update(rawLandmarks, _smoothingFactor);
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
    double getAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
      if (a == null || b == null || c == null) return 180;
      
      final abX = b.x - a.x;
      final abY = b.y - a.y;
      final bcX = c.x - b.x;
      final bcY = c.y - b.y;
      
      final dot = abX * bcX + abY * bcY;
      final magAB = math.sqrt(abX * abX + abY * abY);
      final magBC = math.sqrt(bcX * bcX + bcY * bcY);
      
      if (magAB * magBC == 0) return 0;
      
      double cosine = dot / (magAB * magBC);
      cosine = cosine.clamp(-1.0, 1.0);
      return math.acos(cosine) * (180 / math.pi);
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
