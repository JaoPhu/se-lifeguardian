import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  
  Future<void> close() async {
    await _poseDetector.close();
  }

  Map<PoseLandmarkType, PoseLandmark> _previousLandmarks = {};
  final double _smoothingFactor = 0.5; // EMA factor (0 to 1)

  Future<Map<PoseLandmarkType, PoseLandmark>?> detect(InputImage inputImage) async {
    final List<Pose> poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) return null;

    final currentLandmarks = poses.first.landmarks;
    
    // Apply EMA Smoothing
    if (_previousLandmarks.isEmpty) {
      _previousLandmarks = currentLandmarks;
      return currentLandmarks;
    }

    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};
    currentLandmarks.forEach((type, landmark) {
      final prev = _previousLandmarks[type];
      if (prev != null) {
        final smoothedX = prev.x + (landmark.x - prev.x) * _smoothingFactor;
        final smoothedY = prev.y + (landmark.y - prev.y) * _smoothingFactor;
        final smoothedZ = prev.z + (landmark.z - prev.z) * _smoothingFactor;
        
        smoothedLandmarks[type] = PoseLandmark(
          type: type,
          x: smoothedX,
          y: smoothedY,
          z: smoothedZ,
          likelihood: landmark.likelihood,
        );
      } else {
        smoothedLandmarks[type] = landmark;
      }
    });

    _previousLandmarks = smoothedLandmarks;
    return smoothedLandmarks;
  }

  /// Calculates the angle of the torso relative to the vertical axis.
  /// Returns angle in degrees (0 = Horizontal, 90 = Upright).
  /// Note: Prototype logic: 0 = Flat, 90 = Upright.
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

    // dx, dy from Hip to Shoulder (Upward vector)
    final dx = midShoulderX - midHipX;
    final dy = midShoulderY - midHipY; 

    // Angle relative to vertical (0, -1)
    // atan2(dy, dx) gives angle from +X.
    // simple heuristic from prototype: abs(atan(dx/dy)) -> deviation from vertical?
    // Prototype: Math.atan2(Math.abs(dy), Math.abs(dx)) * 180 / PI
    // where dx is horizontal diff, dy is vertical diff.
    // If upright, dy is large, dx is small. atomic(dy/dx) -> close to 90.
    
    final angleRad = math.atan2(dy.abs(), dx.abs());
    return angleRad * (180 / math.pi);
  }

  /// Returns the straightness of the straightest leg (0 = straight, 180 = full bend)
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
    
    // Aspect ratio check from prototype
    final xValues = landmarks.values.map((l) => l.x).toList();
    final yValues = landmarks.values.map((l) => l.y).toList();
    if (xValues.isEmpty || yValues.isEmpty) return false;
    
    final width = xValues.reduce(math.max) - xValues.reduce(math.min);
    final height = yValues.reduce(math.max) - yValues.reduce(math.min);
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
